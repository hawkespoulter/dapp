module Villains
  class Scar < Base
    self.key = "scar"
    self.display_name = "Scar"
    self.park = "Animal Kingdom"
    self.lair = "Africa"
    self.tagline = "Long live the king"
    self.rules_text = [
      "Be Prepared: On every turn, hyenas decrease strength of neighboring areas by one.",
      "Long Live the King: when Scar decreases your influence to 0 in one of your areas to 0 he claims the area instantly.",
    ]

    def usurps?
      true
    end

    # Be Prepared: at the end of every turn.
    def on_tick(at)
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
