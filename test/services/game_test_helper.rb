module GameTestHelper
  def start_game(preset: "full_day", rules: {}, at: Time.zone.parse("2026-10-01 09:00"), seed: 1)
    game, host = Games::Actions.create!(park: "Magic Kingdom", preset:, host_name: "Hawkes", rules:)
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
