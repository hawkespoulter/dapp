require "test_helper"
require_relative "game_test_helper"

class ClaimTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game(park: "Magic Kingdom")
    @game.update!(villain_draw: [])
    neutral_board!(@game)
    GameContent.seed_claims(GameContent::CLAIMS_DIR, Set.new)
    @now = @game.started_at + 1.minute
  end

  def act = Games::Actions.new(@game, @host)

  test "each area's claim challenge comes from the claim cards" do
    card = @game.claim_card("Liberty Square")
    assert_equal "Let Freedom Ring", card.title

    claim = @game.state_for(@host)[:areas].find { _1[:area] == "Liberty Square" }[:claim]
    assert_equal "Let Freedom Ring", claim.title
  end

  test "completing a claim challenge claims an unclaimed area at strength 1" do
    act.complete_claim!("Liberty Square", @now)

    state = @game.area("Liberty Square").reload
    assert_equal ["players", 1], [state.owner, state.strength]
    assert_match "claimed Liberty Square", @game.game_events.last.message
  end

  test "a villain area can't be claimed until it's worn down to unclaimed" do
    set_area(@game, "Adventureland", owner: "villain", strength: 6)
    error = assert_raises(Games::Actions::Invalid) { act.complete_claim!("Adventureland", @now) }
    assert_match "unclaimed", error.message
    assert_nil @game.state_for(@host)[:areas].find { _1[:area] == "Adventureland" }[:claim]
  end

  test "your own areas have nothing to claim" do
    set_area(@game, "Tomorrowland", owner: "players", strength: 1)
    assert_raises(Games::Actions::Invalid) { act.complete_claim!("Tomorrowland", @now) }
    assert_nil @game.state_for(@host)[:areas].find { _1[:area] == "Tomorrowland" }[:claim]
  end

  test "an area with no claim challenge gets a stand-in" do
    card = ClaimChallenge.cards("Epcot", "World Showcase").first
    assert_equal "Stake your claim", card.title
  end

  test "claim cards are edited in the app" do
    ClaimChallenge.where(park: "Magic Kingdom", area: "Liberty Square").delete_all
    ClaimChallenge.create!(park: "Magic Kingdom", area: "Liberty Square", title: "Ring the bell")
    assert_equal "Ring the bell", @game.claim_card("Liberty Square").title
  end
end
