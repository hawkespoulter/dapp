require "test_helper"
require_relative "../services/game_test_helper"

class GamePresetTest < ActiveSupport::TestCase
  include GameTestHelper

  test "the settings are seeded from the defaults file" do
    assert_equal %w[standard], GamePreset.seeded.map(&:key)
    assert_equal GamePreset::DEFAULTS.dig("standard", "normal_minutes"), GamePreset.standard.settings["normal_minutes"]
  end

  test "old Sprint / Full Day / Multi-day presets are cleared out" do
    GamePreset.seeded
    GamePreset.create!(key: "sprint", position: 5, settings: GamePreset.standard.settings)
    assert_equal %w[standard], GamePreset.seeded.map(&:key)
  end

  test "the difficulty sets how often the villain moves" do
    paces = %w[easy normal hard].index_with { GamePreset.for_game(_1, hours: nil)["tick_minutes"] }
    assert_equal({ "easy" => 45, "normal" => 30, "hard" => 20 }, paces)
    settings = GamePreset.for_game("hard", hours: nil)
    assert_equal "Hard", settings["label"]
    refute settings.key?("easy_minutes"), "a game only keeps its own pace"
  end

  test "a game keeps the settings it was created with" do
    game, = start_game
    GamePreset.standard.update_settings!("normal_minutes" => "5")

    assert_equal 30, game.reload.settings["tick_minutes"]
    new_game, = start_game
    assert_equal 5, new_game.settings["tick_minutes"]
  end

  test "settings are checked against their allowed ranges" do
    preset = GamePreset.standard
    assert_raises(ActiveRecord::RecordInvalid) { preset.update_settings!("hard_minutes" => "0") }
  end

  test "reset brings back the defaults" do
    preset = GamePreset.standard
    preset.update_settings!("normal_minutes" => "7")
    preset.reset!

    assert_equal 30, preset.reload.settings["normal_minutes"]
  end

  test "old games keep their length's label" do
    assert_equal "Full Day", GamePreset.label_for("full_day")
    assert_equal "Hard", GamePreset.label_for("hard")
  end
end
