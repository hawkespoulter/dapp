require "test_helper"
require_relative "game_test_helper"

class GameLengthTest < ActiveSupport::TestCase
  include GameTestHelper

  test "the host picks the game's length, in half hours" do
    game, = start_game(difficulty: "normal", rules: { "hours" => "2.5" })
    assert_equal 2.5, game.settings["hours"]
    assert_equal game.started_at + 150.minutes, game.ends_at
  end

  test "whole hours stay whole numbers" do
    game, = start_game(difficulty: "normal", rules: { "hours" => "4" })
    assert_equal 4, game.settings["hours"]
  end

  test "a length that isn't a half hour step is refused" do
    error = assert_raises(Games::Actions::Invalid) { start_game(difficulty: "normal", rules: { "hours" => "2.25" }) }
    assert_match "steps of 0.5", error.message
  end

  test "the difficulty sets the villain's pace" do
    game, = start_game(difficulty: "hard")
    assert_equal ["hard", "Hard", 20], [game.preset, game.settings["label"], game.settings["tick_minutes"]]
    assert_raises(Games::Actions::Invalid, ArgumentError) { start_game(difficulty: "sprint") }
  end

  test "without a length it's 3 hours" do
    game, = start_game(difficulty: "normal")
    assert_equal 3, game.settings["hours"]
  end
end
