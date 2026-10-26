require "test_helper"
require_relative "game_test_helper"

class GameLengthTest < ActiveSupport::TestCase
  include GameTestHelper

  test "the host picks a sprint's length, in half hours" do
    game, = start_game(preset: "sprint", rules: { "hours" => "2.5" })
    assert_equal 2.5, game.settings["hours"]
    assert_equal game.started_at + 150.minutes, game.ends_at
  end

  test "whole hours stay whole numbers" do
    game, = start_game(preset: "sprint", rules: { "hours" => "4" })
    assert_equal 4, game.settings["hours"]
  end

  test "a length that isn't a half hour step is refused" do
    error = assert_raises(Games::Actions::Invalid) { start_game(preset: "sprint", rules: { "hours" => "2.25" }) }
    assert_match "steps of 0.5", error.message
  end

  test "without a length the preset's is used" do
    game, = start_game(preset: "sprint")
    assert_equal GamePreset.for("sprint").settings["hours"], game.settings["hours"]
  end
end
