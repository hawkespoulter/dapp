# Default villain behavior. Subclasses override the hooks to give each park's
# villain its own rules. Hooks run inside the game's lock, so they can change
# area states and log events freely.
module Villains
  class Base
    class_attribute :key, :display_name, :park, :lair, :tagline, :rules_text

    def self.as_json(*)
      { key:, name: display_name, park:, lair:, tagline:, rules: rules_text }
    end

    attr_reader :game

    def initialize(game)
      @game = game
    end

    STARTING_STRENGTH = 2

    # Called once when the game starts: splits the park at random. The villain
    # spreads out from her lair to half the park, the players spread from the
    # far side over the other half, and any odd area left over starts
    # unclaimed.
    def setup!(at)
      split = random_split
      game.area_states.each do |state|
        owner = split.fetch(state.area, "neutral")
        state.update!(owner:, influence: owner == "villain" ? STARTING_STRENGTH : 0, claim: 0, locked: false)
      end
      held = game.area_states.select(&:villain?).map(&:area)
      game.log!("villain", "#{display_name} rises from #{lair} and holds #{held.to_sentence}.", at:)
    end

    # Influence it takes to move this area's meter one step.
    def placement_cost(_area)
      1
    end

    # Influence each neighbor receives when an outbreak spreads.
    def outbreak_spread
      1
    end

    def on_tick(_at); end
    def on_takeover(_area_state, _at); end
    def on_escalation(_at); end

    def as_json(*)
      self.class.as_json
    end

    private

    def random_split
      board = game.board
      half = board.areas.size / 2
      owners = {}
      grow = lambda do |owner, seed|
        owners[seed] = owner
        while owners.count { _2 == owner } < half
          mine = owners.select { _2 == owner }.keys
          frontier = mine.flat_map { board.neighbors(_1) }.uniq - owners.keys
          frontier = board.areas - owners.keys if frontier.empty?
          owners[frontier.sample(random: game.rng)] = owner
        end
      end
      grow.call("villain", lair)
      open = board.areas - owners.keys
      far = open.map { board.distance(lair, _1) }.max
      grow.call("players", open.select { board.distance(lair, _1) == far }.sample(random: game.rng))
      owners
    end
  end
end
