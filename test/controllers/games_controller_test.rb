require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "create, join, start and play over the API" do
    get api_v1_game_parks_url
    assert_equal ["Magic Kingdom"], response.parsed_body["parks"].map { _1["park"] }

    post api_v1_games_url, params: { park: "Magic Kingdom", preset: "sprint", name: "Hawkes" }, as: :json
    assert_response :created
    host_token = response.parsed_body["token"]
    code = response.parsed_body.dig("state", "game", "code")

    post join_api_v1_game_url(code.downcase), params: { name: "Wife" }, as: :json
    assert_response :created
    wife_token = response.parsed_body["token"]

    post start_api_v1_game_url(code), headers: { "X-Player-Token" => wife_token }, as: :json
    assert_response :unprocessable_entity

    post start_api_v1_game_url(code), headers: { "X-Player-Token" => host_token }, as: :json
    assert_response :success
    state = response.parsed_body
    assert_equal "active", state.dig("game", "status")
    assert_equal 2, state.dig("me", "hand").size
    assert_equal 6, state["areas"].size

    patch move_api_v1_game_url(code), params: { area: "Adventureland" }, headers: { "X-Player-Token" => host_token }, as: :json
    assert_equal "Adventureland", response.parsed_body.dig("me", "current_area")

    card = response.parsed_body.dig("me", "hand").find { _1["area"].nil? || _1["area"] == "Adventureland" }
    if card
      post complete_api_v1_game_url(code), params: { challenge_id: card["id"] }, headers: { "X-Player-Token" => host_token }, as: :json
      assert_response :success
    end

    get api_v1_game_url(code)
    assert_response :success
    assert_nil response.parsed_body["me"]
  end

  test "unknown codes are a 404" do
    get api_v1_game_url("NOPE00")
    assert_response :not_found
  end
end
