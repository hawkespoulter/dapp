require "test_helper"

class GameSettingsControllerTest < ActionDispatch::IntegrationTest
  test "lists presets with their fields and finished games" do
    game, = Games::Actions.create!(park: "Magic Kingdom", preset: "sprint", host_name: "Hawkes")
    game.update!(status: "finished", result: "bronze")

    get api_v1_game_settings_url
    assert_response :success
    body = response.parsed_body
    assert_equal %w[sprint full_day multi_day], body["presets"].map { _1["key"] }
    assert_includes body["presets"].first["fields"].map { _1["key"] }, "tick_minutes"
    assert_equal({ "bronze" => 1 }, body.dig("record", "sprint"))
    assert_equal game.join_code, body["finished_games"].first["code"]
  end

  test "updates and resets a preset" do
    patch api_v1_game_setting_url("full_day"), params: { settings: { tick_minutes: 30 } }, as: :json
    assert_response :success
    assert_equal 30, response.parsed_body.dig("settings", "tick_minutes")

    patch api_v1_game_setting_url("full_day"), params: { settings: { tick_minutes: 0 } }, as: :json
    assert_response :unprocessable_entity
    assert_match "Villain moves every", response.parsed_body["error"]

    post reset_api_v1_game_setting_url("full_day"), as: :json
    assert_equal GamePreset::DEFAULTS.dig("full_day", "tick_minutes"), response.parsed_body.dig("settings", "tick_minutes")
  end
end
