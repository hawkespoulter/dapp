require "test_helper"
require_relative "game_test_helper"

class VoldemortTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game(park: "Wizarding World")
    @engine = Games::VillainEngine.new(@game)
    @now = @game.started_at
  end

  test "the Wizarding World board is playable, with Voldemort" do
    assert_includes Game.playable_parks, "Wizarding World"
    assert_equal "voldemort", @game.villain_key
    assert_equal 8, @game.area_states.size
    assert_includes @game.board.neighbors("King's Cross"), "Hogsmeade Station", "the Hogwarts Express links the halves"
  end

  test "Dark Mark: taking one of your areas costs the team a coin" do
    neutral_board!(@game)
    @game.coins = 3
    set_area(@game, "Diagon Alley", owner: "players", strength: 1)
    @engine.push("Diagon Alley", 2, @now)

    assert @game.area("Diagon Alley").villain?
    assert_equal 2, @game.coins
  end

  test "Nagini: a Villain Rising adds 2 to his strongest area" do
    neutral_board!(@game)
    set_area(@game, "Hogwarts Castle", owner: "villain", strength: 4)
    set_area(@game, "Hagrid's Hut", owner: "villain", strength: 1)
    @game.villain_draw = ["rising", "area:Carkitt Market"]
    @engine.villain_turn(@now)

    assert_equal 6, @game.area("Hogwarts Castle").strength
  end

  test "its challenges and claim cards load" do
    assert_operator Challenge.for_park("Wizarding World").count, :>=, 6
    assert_equal "Gringotts Doors", ClaimChallenge.cards("Wizarding World", "Diagon Alley").first.title
  end
end
