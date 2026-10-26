require "test_helper"

class GameContentControllerTest < ActionDispatch::IntegrationTest
  test "lists a park's challenges, claim cards and areas" do
    get "/api/v1/game_content", params: { park: "Magic Kingdom" }
    body = response.parsed_body

    assert_response :success
    assert_includes body["challenges"].map { _1["title"] }, "Dole Whip"
    assert_includes body["areas"], "Adventureland"
  end

  test "adds, edits and deletes a challenge" do
    post "/api/v1/challenges", params: { challenge: { title: "Wave", reward: 2, park: "anywhere" } }, as: :json
    id = response.parsed_body["id"]
    assert_nil Challenge.find(id).park

    patch "/api/v1/challenges/#{id}", params: { challenge: { reward: 5 } }, as: :json
    assert_equal 5, Challenge.find(id).reward

    delete "/api/v1/challenges/#{id}"
    refute Challenge.exists?(id)
  end

  test "editing just the text keeps the list and park" do
    ChallengeList.create!(name: "smells", items: %w[Pie Smoke])
    challenge = Challenge.create!(title: "Sniff", reward: 1, park: "Epcot", list_from: "smells", list_count: 1)

    patch "/api/v1/challenges/#{challenge.id}", params: { challenge: { title: "Sniff it", reward: 2 } }, as: :json
    assert_response :success
    assert_equal ["Sniff it", 2, "Epcot", "smells", 1],
                 challenge.reload.slice(:title, :reward, :park, :list_from, :list_count).values
  end

  test "a bad challenge comes back with the problem" do
    post "/api/v1/challenges", params: { challenge: { title: "Greedy", reward: 50 } }, as: :json
    assert_response 422
    assert_match "Reward must be a whole number", response.parsed_body["error"]
  end

  test "claim cards must be for an area of the park" do
    post "/api/v1/claim_challenges", params: { claim: { park: "Magic Kingdom", area: "Narnia", title: "X" } }, as: :json
    assert_response 422

    post "/api/v1/claim_challenges", params: { claim: { park: "Magic Kingdom", area: "Adventureland", title: "Tiki" } }, as: :json
    assert_response :success
    assert_equal "Tiki", ClaimChallenge.cards("Magic Kingdom", "Adventureland").first.title
  end

  test "a list in use can't be deleted" do
    list = ChallengeList.create!(name: "smells", items: %w[Pie Smoke])
    Challenge.create!(title: "Sniff", reward: 1, list_from: "smells", list_count: 1)

    delete "/api/v1/challenge_lists/#{list.id}"
    assert_response 422
    assert_match "Sniff", response.parsed_body["error"]
  end

  test "exports everything as YAML" do
    get "/api/v1/game_content/export"
    assert_response :success
    assert_includes YAML.safe_load(response.body)["challenges"]["anywhere"].map { _1["title"] }, "Hidden Mickey"
  end
end
