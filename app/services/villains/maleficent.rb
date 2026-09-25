module Villains
  class Maleficent < Base
    self.key = "maleficent"
    self.display_name = "Maleficent"
    self.park = "Magic Kingdom"
    self.lair = "Fantasyland"
    self.tagline = "Mistress of All Evil"
    self.rules_text = [
      "Thorn Wall: while she holds Fantasyland, challenges in the areas next to it must be difficulty 2 or higher.",
      "Dragon Form: from her second Villain Rising on, outbreaks spread 2 influence instead of 1.",
    ]

    def min_difficulty(area)
      thorn_wall?(area) ? 2 : 1
    end

    def outbreak_spread
      dragon_form? ? 2 : 1
    end

    def on_escalation(at)
      return unless game.escalation == 2

      game.log!("villain", "Maleficent takes her Dragon Form! Outbreaks now spread 2 influence.", at:)
    end

    private

    def thorn_wall?(area)
      game.area(lair).villain? && game.board.adjacent?(area, lair)
    end

    def dragon_form?
      game.escalation >= 2
    end
  end
end
