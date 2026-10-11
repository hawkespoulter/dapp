module Villains
  # Rough-draft rules: placeholders to rewrite.
  class Voldemort < Base
    NAGINI_BOOST = 2

    self.key = "voldemort"
    self.display_name = "Voldemort"
    self.park = "Wizarding World"
    self.lair = "Hogwarts Castle"
    self.rules_text = [
      "Dark Mark: whenever Voldemort takes one of your areas, the team loses 1 coin.",
      "Nagini: every Villain Rising adds #{NAGINI_BOOST} influence to his strongest area.",
    ]

    # Dark Mark.
    def on_takeover(_area_state, at)
      return unless game.coins.positive?

      game.coins -= 1
      game.log!("villain", "The Dark Mark costs the team a coin.", at:)
    end

    # Nagini.
    def on_escalation(at)
      strongest = game.area_states.select(&:villain?).max_by(&:strength)
      return unless strongest

      strongest.update!(strength: strongest.strength + NAGINI_BOOST)
      game.log!("strength", "Nagini coils around #{strongest.area} (strength #{strongest.strength}).", at:,
                                                                                                     area: strongest.area,
                                                                                                     owner: "villain",
                                                                                                     strength: strongest.strength)
    end
  end
end
