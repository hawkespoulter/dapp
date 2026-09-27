module Villains
  class Maleficent < Base
    self.key = "maleficent"
    self.display_name = "Maleficent"
    self.park = "Magic Kingdom"
    self.lair = "Fantasyland"
    self.rules_text = [
      "Thorn Wall: you can't set foot in any area Maleficent controls. Stay in the rest of the park until you win it back (you can still place influence there).",
      "Dragon Form: from her second Villain Rising on, when her strong areas spill over they push 2 into each neighbor instead of 1.",
    ]

    def outbreak_spread
      dragon_form? ? 2 : 1
    end

    def on_escalation(at)
      return unless game.escalation == 2

      game.log!("villain", "Maleficent takes her Dragon Form! Her strong areas now spill 2 into each neighbor.", at:)
    end

    private

    def dragon_form?
      game.escalation >= 2
    end
  end
end
