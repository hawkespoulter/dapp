# A co-op park game: players earn coins with real-life challenges and spend
# them on influence to claim areas, while the park's villain spreads on a
# real-time clock.
#
# There is no background worker. Villain turns that came due since the last
# request are played by `advance!`, which every request runs inside the game
# lock (see Games::Actions).
class Game < ApplicationRecord
  STATUSES = %w[lobby active finished].freeze
  RESULTS = %w[gold silver bronze lost].freeze
  CODE_CHARS = ("A".."Z").to_a - %w[I O]

  has_many :players, -> { order(:id) }, dependent: :destroy
  has_many :area_states, dependent: :destroy
  has_many :game_events, -> { order(:occurred_at, :id) }, dependent: :destroy

  validates :join_code, presence: true, uniqueness: true
  validates :preset, inclusion: { in: ->(_) { GamePreset.keys } }
  validates :status, inclusion: { in: STATUSES }
  validates :result, inclusion: { in: RESULTS }, allow_nil: true
  validate :park_is_playable, on: :create

  before_validation { self.join_code ||= self.class.unique_code }

  attr_writer :rng

  def self.unique_code
    loop do
      code = Array.new(6) { CODE_CHARS.sample }.join
      return code unless exists?(join_code: code)
    end
  end

  def self.playable_parks
    Villains.all.map(&:park) & ParkBoard.config.keys
  end

  def lobby? = status == "lobby"
  def active? = status == "active"
  def finished? = status == "finished"

  # The balance settings this game was created with (see GamePreset).
  def settings
    rules["settings"] || GamePreset.for(preset).settings
  end

  def board
    @board ||= ParkBoard.for(park)
  end

  def villain
    @villain ||= Villains.find(villain_key).new(self)
  end

  def clock
    GameClock.new(rules.fetch("windows", []))
  end

  def rng
    @rng ||= Random.new
  end

  def tick_seconds
    settings["tick_minutes"] * 60
  end

  def hand_size
    settings["hand_size"]
  end

  def outbreak_limit
    settings["outbreak_limit"]
  end

  def influence_price
    settings["influence_price"]
  end

  def outbreak_at
    settings["outbreak_at"]
  end

  # Hard mode: the villain also takes a turn when a challenge is failed.
  # Games from before it was a preset setting kept it in rules.
  def hard_mode?
    settings.fetch("hard_mode") { rules["villain_on_fail"] } == true
  end

  def area(name)
    areas_by_name.fetch(name) { raise ArgumentError, "#{name} is not in #{park}" }
  end

  def areas_by_name
    @areas_by_name ||= area_states.index_by(&:area)
  end

  def reload(*)
    @areas_by_name = @board = @villain = nil
    super
  end

  def log!(kind, message, at: Time.current, player: nil, **data)
    game_events.create!(kind:, message:, player:, data: data.deep_stringify_keys, occurred_at: at)
  end

  # Plays every villain turn that has come due, then ends the game if time is up.
  def advance!(now = Time.current)
    return unless active?

    engine = Games::VillainEngine.new(self)
    while active? && next_tick_at && next_tick_at < ends_at && next_tick_at <= now
      at = next_tick_at
      engine.handle(:timer, at:)
      self.next_tick_at = clock.advance(at, tick_seconds) if active?
    end
    engine.finish_on_time!(ends_at) if active? && now >= ends_at
    save!
  end

  # Draws challenge ids for a hand, avoiding cards already held or recently used.
  def draw_challenges(count)
    Challenge.refresh
    held = players.flat_map(&:hand)
    pool = Challenge.for_park(park).where.not(id: held).select { _1.dealable_in?(park) }.map(&:id)
    fresh = pool - challenge_discard
    if fresh.size < count
      self.challenge_discard = []
      fresh = pool
    end
    fresh.sample(count, random: rng)
  end

  def discard_challenge(id)
    self.challenge_discard = challenge_discard + [id]
  end

  def state_for(player)
    {
      game: {
        code: join_code, park:, preset:, preset_label: settings["label"], status:, result:,
        started_at:, ends_at:, next_tick_at:, server_time: Time.current,
        tick_minutes: settings["tick_minutes"], hand_size:,
        escalation:, outbreaks:, outbreak_limit:, villain_rate: Games::VillainEngine.rate_for(escalation),
        coins:, influence_stash:, influence_price:, outbreak_at:,
        villain_cards_left: villain_draw.size, windows: rules["windows"] || [],
      },
      villain: villain,
      areas: board.areas.map { |name| area(name).as_json.merge(neighbors: board.neighbors(name), placement_cost: villain.placement_cost(name)) },
      players:,
      me: player && player.as_json.merge(hand: player.hand_cards, undo: undoable_message(player)),
      events: game_events.last(40).reverse,
    }
  end

  private

  def undoable_message(player)
    event = game_events.where(player_id: player.id, kind: Games::Actions::UNDOABLE).last
    event.message if event&.data&.dig("undo") && !event.data["undone"]
  end

  def park_is_playable
    errors.add(:park, "doesn't have a villain yet") unless self.class.playable_parks.include?(park)
  end
end
