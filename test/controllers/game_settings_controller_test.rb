require "test_helper"

class GameSettingsControllerTest < ActionDispatch::IntegrationTest
  test "lists presets with their fields and the finished-game record" do
    game, = Games::Actions.create!(park: "Magic Kingdom", preset: "sprint", host_name: "Hawkes")
    game.update!(status: "finished", result: "bronze")

    get api_v1_game_settings_url
    assert_response :success
    body = response.parsed_body
    assert_equal %w[sprint full_day multi_day], body["presets"].map { _1["key"] }
    assert_includes body["presets"].first["fields"].map { _1["key"] }, "tick_minutes"
    assert_equal({ "bronze" => 1 }, body.dig("record", "sprint"))
    assert_equal 1, body["finished_count"]
  end

  test "finished games come newest first, ten to a page" do
    codes = 12.times.map do |i|
      game, = Games::Actions.create!(park: "Magic Kingdom", preset: "sprint", host_name: "Hawkes")
      game.update!(status: "finished", result: "lost", updated_at: i.hours.from_now)
      game.join_code
    end

    get api_v1_finished_games_url
    body = response.parsed_body
    assert_equal [1, 2, 12], body.values_at("page", "pages", "total")
    assert_equal codes.reverse.first(10), body["games"].pluck("code")

    get api_v1_finished_games_url(page: 2)
    assert_equal codes.first(2).reverse, response.parsed_body["games"].pluck("code")

    get api_v1_finished_games_url(page: 99)
    assert_equal 2, response.parsed_body["page"], "out-of-range pages land on the last one"
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
