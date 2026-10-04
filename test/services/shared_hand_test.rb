require "test_helper"
require_relative "game_test_helper"

class SharedHandTest < ActiveSupport::TestCase
  include GameTestHelper

  def two_player_game(shared:)
    game, host = Games::Actions.create!(park: "Magic Kingdom", preset: "full_day", host_name: "Hawkes")
    game.update!(rules: game.rules.merge("settings" => game.settings.merge("shared_hand" => shared)))
    guest = Games::Actions.new(game).join!("Sam")
    Games::Actions.new(game, host).start!(START)
    game.update!(villain_draw: [])
    [game.reload, host.reload, guest.reload]
  end

  def hand(game, player) = game.reload.state_for(player)[:me][:hand].pluck(:id)

  test "by default everyone sees the same challenges" do
    game, host, guest = two_player_game(shared: true)
    assert game.shared_hand?
    assert_equal 3, hand(game, host).size
    assert_equal hand(game, host), hand(game, guest)
    assert game.state_for(host)[:game][:shared_hand]
  end

  test "either player can play the shared hand, and both see the new card" do
    game, host, guest = two_player_game(shared: true)
    card = hand(game, guest).first
    Games::Actions.new(game, guest).complete!(card, START + 1.minute)

    refute_includes hand(game, host), card
    assert_equal hand(game, host), hand(game, guest)
  end

  test "late joiners play from the shared hand too" do
    game, host, = two_player_game(shared: true)
    late = Games::Actions.new(game).join!("Alex")
    assert_equal hand(game, host), hand(game, late)
  end

  test "undo is refused once a teammate has changed the hand" do
    game, host, guest = two_player_game(shared: true)
    first, second = hand(game, host)
    Games::Actions.new(game, host).complete!(first, START + 1.minute)
    Games::Actions.new(game, guest).complete!(second, START + 2.minutes)

    error = assert_raises(Games::Actions::Invalid) { Games::Actions.new(game, host).undo!(START + 3.minutes) }
    assert_match "challenges have changed", error.message
  end

  test "turned off, each player (or group) has their own hand" do
    game, host, guest = two_player_game(shared: false)
    refute game.shared_hand?
    assert_equal 3, hand(game, guest).size
    assert_empty hand(game, host) & hand(game, guest)
  end

  test "games from before the setting keep separate hands" do
    game, = two_player_game(shared: true)
    game.rules = { "settings" => game.settings.except("shared_hand") }
    refute game.shared_hand?
  end
end
