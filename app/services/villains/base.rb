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

    # Called once when the game starts: splits the park between the players
    # and the villain as set in config/game/parks.yml.
    def setup!(at)
      game.area_states.each do |state|
        owner = game.board.starting_owner(state.area)
        state.update!(owner:, influence: owner == "villain" ? STARTING_STRENGTH : 0, locked: false)
      end
      held = game.area_states.select(&:villain?).map(&:area)
      game.log!("villain", "#{display_name} rises from #{lair} and holds #{held.to_sentence}.", at:)
    end

    # Lowest challenge difficulty that counts in this area.
    def min_difficulty(_area)
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
  end
end
