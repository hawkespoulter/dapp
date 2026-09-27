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

    # Called once when the game starts: splits the park at random. The villain
    # spreads out from her lair to half the park, the players spread from the
    # far side over the other half, and any odd area left over starts
    # unclaimed. Each side then scatters its starting strength over its areas
    # (at least 1 each).
    def setup!(at)
      split = random_split
      strengths = %w[players villain].to_h do |side|
        [side, scatter(split.select { _2 == side }.keys, game.settings["starting_strength"])]
      end
      game.area_states.each do |state|
        owner = split.fetch(state.area, "neutral")
        state.update!(owner:, strength: strengths.dig(owner, state.area) || 0)
      end
      held = game.area_states.select(&:villain?).map(&:area)
      game.log!("villain", "#{display_name} rises from #{lair} and holds #{held.to_sentence}.", at:)
    end

    # Whether knocking a players area to 0 hands it straight to the villain
    # instead of leaving it unclaimed.
    def usurps?
      false
    end

    # Influence it takes to move this area's meter one step.
    def placement_cost(_area)
      1
    end

    # Influence each neighbor receives when one of her areas spills over.
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

    def scatter(areas, total)
      strengths = areas.to_h { [_1, 1] }
      (total - areas.size).times { strengths[areas.sample(random: game.rng)] += 1 }
      strengths
    end

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
