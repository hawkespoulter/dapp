# Default villain behavior. Subclasses override the hooks to give each park's
# villain its own rules. Hooks run inside the game's lock, so they can change
# area states and log events freely.
module Villains
  class Base
    class_attribute :key, :display_name, :park, :lair, :rules_text

    def self.as_json(*)
      { key:, name: display_name, park:, lair:, rules: rules_text }
    end

    attr_reader :game

    def initialize(game)
      @game = game
    end

    # Called once when the game starts: deals half the park to each side at
    # random (the lair plays no part), then each side scatters its starting
    # strength over its areas (at least 1 each).
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
      game.log!("villain", "#{display_name} holds #{held.to_sentence}.", at:)
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

    # Whether the team can go into an area in the park (to do its claim
    # challenge, say).
    def enterable?(_area_state)
      true
    end

    # Influence an area card puts into its area.
    def card_push(_area_state)
      1
    end

    # Influence each neighbor receives when one of her areas spills over.
    def outbreak_spread
      1
    end

    def on_tick(_at); end
    def on_takeover(_area_state, _at); end
    def on_escalation(_at); end

    # The rules as shown in this game (some mention its settings).
    def rules
      rules_text
    end

    def as_json(*)
      self.class.as_json.merge(rules:)
    end

    private

    def scatter(areas, total)
      strengths = areas.to_h { [_1, 1] }
      (total - areas.size).times { strengths[areas.sample(random: game.rng)] += 1 }
      strengths
    end

    # Half the areas to each side, picked at random; with an odd number of
    # areas the one left over starts unclaimed.
    def random_split
      areas = game.board.areas.shuffle(random: game.rng)
      half = areas.size / 2
      areas.first(half).to_h { [_1, "villain"] }.merge(areas.drop(half).first(half).to_h { [_1, "players"] })
    end
  end
end
