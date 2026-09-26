require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "create, join, start and play over the API" do
    get api_v1_game_parks_url
    assert_equal ["Animal Kingdom", "Magic Kingdom"], response.parsed_body["parks"].map { _1["park"] }

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

    host = { "X-Player-Token" => host_token }
    card = state.dig("me", "hand").max_by { _1["difficulty"] }
    post complete_api_v1_game_url(code), params: { challenge_id: card["id"] }, headers: host, as: :json
    assert_response :success
    assert_equal card["difficulty"], response.parsed_body.dig("game", "coins")

    post buy_api_v1_game_url(code), params: { count: 1 }, headers: host, as: :json
    assert_response :success
    assert_equal 1, response.parsed_body.dig("game", "influence_stash")

    ours = response.parsed_body["areas"].find { _1["owner"] == "players" && _1["placement_cost"] == 1 }
    if ours
      post place_api_v1_game_url(code), params: { area: ours["area"], count: 1 }, headers: host, as: :json
      assert_response :success
      assert_equal ours["strength"] + 1, response.parsed_body["areas"].find { _1["area"] == ours["area"] }["strength"]
    end

    post undo_api_v1_game_url(code), headers: host, as: :json
    assert_response :success

    get api_v1_game_url(code)
    assert_response :success
    assert_nil response.parsed_body["me"]
  end

  test "unknown codes are a 404" do
    get api_v1_game_url("NOPE00")
    assert_response :not_found
  end
end
