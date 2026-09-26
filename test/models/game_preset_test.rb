require "test_helper"
require_relative "../services/game_test_helper"

class GamePresetTest < ActiveSupport::TestCase
  include GameTestHelper

  test "presets are seeded from the defaults file" do
    assert_equal %w[sprint full_day multi_day], GamePreset.keys
    assert_equal 40, GamePreset.for("full_day").settings["tick_minutes"]
  end

  test "a game keeps the settings it was created with" do
    game, = start_game
    GamePreset.for("full_day").update_settings!("tick_minutes" => "5", "starting_strength" => "30")

    assert_equal 40, game.reload.settings["tick_minutes"]
    new_game, = start_game
    assert_equal 5, new_game.settings["tick_minutes"]
    assert_equal 30, new_game.area_states.select(&:players?).sum(&:strength)
  end

  test "settings are checked against their allowed ranges" do
    preset = GamePreset.for("sprint")
    assert_raises(ActiveRecord::RecordInvalid) { preset.update_settings!("tick_minutes" => "0") }
    assert_raises(ActiveRecord::RecordInvalid) { preset.update_settings!("hand_size" => "lots") }
    assert_match "whole number", preset.errors.full_messages.to_sentence

    multi = GamePreset.for("multi_day")
    assert_raises(ActiveRecord::RecordInvalid) { multi.update_settings!("day_start" => "22:00") }
  end

  test "fields a preset doesn't use are ignored" do
    preset = GamePreset.for("sprint")
    preset.update_settings!("days" => "4", "bogus" => "1")

    refute preset.reload.settings.key?("days")
    refute preset.settings.key?("bogus")
  end

  test "reset brings back the defaults" do
    preset = GamePreset.for("sprint")
    preset.update_settings!("tick_minutes" => "7")
    preset.reset!

    assert_equal 20, preset.reload.settings["tick_minutes"]
  end
end
