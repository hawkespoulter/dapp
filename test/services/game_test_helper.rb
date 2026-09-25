module GameTestHelper
  def start_game(preset: "full_day", rules: {}, at: Time.zone.parse("2026-10-01 09:00"))
    game, host = Games::Actions.create!(park: "Magic Kingdom", preset:, host_name: "Hawkes", rules:)
    game.rng = Random.new(1)
    Games::Actions.new(game, host).start!(at)
    [game, host.reload]
  end

  def set_area(game, name, **attrs)
    game.area(name).update!(**attrs)
  end

  def give(player, challenge, area:)
    player.update!(hand: [challenges(challenge).id], current_area: area)
  end
end
