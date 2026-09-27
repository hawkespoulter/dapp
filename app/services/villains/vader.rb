module Villains
  class Vader < Base
    self.key = "vader"
    self.display_name = "Darth Vader"
    self.park = "Hollywood Studios"
    self.lair = "Galaxy's Edge"
    self.rules_text = [
      "Might of the Empire: when Darth Vader draws one of his own areas, he places 2 influence there instead of 1.",
      "Youngling: at the end of every turn, your weakest area with %{youngling} or less influence that borders his territory becomes his, keeping its influence.",
    ]

    def self.as_json(*)
      super.merge(rules: rules_text.map { format(_1, youngling: GamePreset::DEFAULTS.values.first["youngling_max"]) })
    end

    # Might of the Empire.
    def card_push(area_state)
      area_state.villain? ? 2 : 1
    end

    # Youngling: the threshold is a game setting. A shielded area is safe.
    def on_tick(at)
      target = game.area_states
                   .select { |s| s.players? && s.strength <= youngling_max && !game.shielded?(s.area) }
                   .select { |s| game.board.neighbors(s.area).any? { game.area(_1).villain? } }
                   .min_by { [_1.strength, game.rng.rand] }
      return unless target

      game.log!("villain", "Youngling: Darth Vader turns #{target.area} to the dark side!", at:, action: "Youngling")
      Games::VillainEngine.new(game).seize(target.area, at)
    end

    def rules
      rules_text.map { format(_1, youngling: youngling_max) }
    end

    private

    def youngling_max
      game.settings["youngling_max"]
    end
  end
end
