require "test_helper"
require_relative "../services/game_test_helper"

class GamePresetTest < ActiveSupport::TestCase
  include GameTestHelper

  test "presets are seeded from the defaults file" do
    assert_equal %w[sprint full_day multi_day], GamePreset.keys
    assert_equal GamePreset::DEFAULTS.dig("full_day", "tick_minutes"), GamePreset.for("full_day").settings["tick_minutes"]
  end

  test "a game keeps the settings it was created with" do
    game, = start_game
    GamePreset.for("full_day").update_settings!("tick_minutes" => "5", "starting_strength" => "30")

    assert_equal GamePreset::DEFAULTS.dig("full_day", "tick_minutes"), game.reload.settings["tick_minutes"]
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

  test "hard mode is on by default and can be switched off" do
    preset = GamePreset.for("sprint")
    assert_equal true, preset.settings["hard_mode"]

    preset.update_settings!("hard_mode" => "false")
    assert_equal false, preset.reload.settings["hard_mode"]
    game, = start_game(preset: "sprint")
    refute game.hard_mode?
  end

  test "settings added to the defaults file are filled in without losing tuned values" do
    preset = GamePreset.for("full_day")
    preset.update_columns(settings: preset.settings.except("hard_mode").merge("tick_minutes" => 7))

    reloaded = GamePreset.for("full_day")
    assert_equal true, reloaded.settings["hard_mode"]
    assert_equal 7, reloaded.settings["tick_minutes"]
  end

  test "settings dropped from the defaults file are removed" do
    preset = GamePreset.for("sprint")
    preset.update_columns(settings: preset.settings.merge("outbreak_limit" => 4))

    refute GamePreset.for("sprint").settings.key?("outbreak_limit")
  end

  test "reset brings back the defaults" do
    preset = GamePreset.for("sprint")
    preset.update_settings!("tick_minutes" => "7")
    preset.reset!

    assert_equal GamePreset::DEFAULTS.dig("sprint", "tick_minutes"), preset.reload.settings["tick_minutes"]
  end
end
