# Default villain behavior. Subclasses override the hooks to give each park's
# villain its own rules. Hooks run inside the game's lock, so they can change
# area states and log events freely.
module Villains
  class Base
    class_attribute :key, :display_name, :park, :lair, :tagline, :rules_text

    attr_reader :game

    def initialize(game)
      @game = game
    end

    # Called once when the game starts.
    def setup!(at)
      game.area(lair).update!(influence: 2)
      game.log!("villain", "#{display_name} awakens in #{lair}.", at:)
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
      { key:, name: display_name, park:, lair:, tagline:, rules: rules_text }
    end
  end
end
