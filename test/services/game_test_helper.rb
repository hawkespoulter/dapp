module GameTestHelper
  # Games in these tests start on a fixed morning; the clock is held just
  # before it so they don't depend on the real date.
  START = Time.zone.parse("2026-10-01 09:00")

  def self.included(base)
    base.include ActiveSupport::Testing::TimeHelpers
    base.setup { travel_to START - 1.minute }
  end

  def start_game(preset: "full_day", rules: {}, at: START, seed: 1, park: "Magic Kingdom")
    game, host = Games::Actions.create!(park:, preset:, host_name: "Hawkes", rules:)
    game.rng = Random.new(seed)
    Games::Actions.new(game, host).start!(at)
    [game, host.reload]
  end

  # Most rule tests are easier to read from an all-neutral board.
  def neutral_board!(game)
    game.area_states.each { _1.update!(owner: "neutral", strength: 0) }
  end

  def set_area(game, name, **attrs)
    game.area(name).update!(**attrs)
  end

  def give(player, challenge)
    player.update!(hand: [challenges(challenge).id])
  end
end
