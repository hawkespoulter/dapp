module Villains
  class Scar < Base
    self.key = "scar"
    self.display_name = "Scar"
    self.park = "Animal Kingdom"
    self.lair = "Africa"
    self.tagline = "Long live the king"
    self.rules_text = [
      "Hyena Pack: at every Villain Rising, hyenas knock 1 strength off each of your areas that borders his territory.",
      "Usurper: when Scar knocks one of your areas to 0 he takes it on the spot, instead of leaving it unclaimed.",
    ]

    def usurps?
      true
    end

    def on_escalation(at)
      targets = game.area_states.select do |state|
        state.players? && game.board.neighbors(state.area).any? { game.area(_1).villain? }
      end
      return if targets.empty?

      game.log!("villain", "Scar's hyenas raid #{targets.map(&:area).to_sentence}!", at:)
      targets.each { engine.push(_1.area, 1, at, from_outbreak: true) }
    end

    private

    def engine
      Games::VillainEngine.new(game)
    end
  end
end
