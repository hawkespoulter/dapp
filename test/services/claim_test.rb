require "test_helper"
require_relative "game_test_helper"

class ClaimTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game(park: "Magic Kingdom")
    @game.update!(villain_draw: [])
    neutral_board!(@game)
    @now = @game.started_at + 1.minute
  end

  def act = Games::Actions.new(@game, @host)

  test "each area's claim challenge comes from the park's claims file" do
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

  test "it takes a villain area outright, at strength 1 (Scar has no Thorn Wall)" do
    game, host = start_game(park: "Animal Kingdom")
    set_area(game, "Africa", owner: "villain", strength: 6)
    Games::Actions.new(game, host).complete_claim!("Africa", @now)

    assert_equal ["players", 1], game.area("Africa").reload.then { [_1.owner, _1.strength] }
  end

  test "Thorn Wall: you can't claim an area while Maleficent holds it" do
    set_area(@game, "Fantasyland", owner: "villain", strength: 2)
    error = assert_raises(Games::Actions::Invalid) { act.complete_claim!("Fantasyland", @now) }
    assert_match "can't enter Fantasyland", error.message
    refute @game.state_for(@host)[:areas].find { _1[:area] == "Fantasyland" }[:enterable]
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

  test "claims file mistakes are reported, not raised" do
    summary = ClaimChallenge.summary
    assert_nil summary[:problem]
    assert_equal 6, summary[:counts]["Magic Kingdom"]
  end
end
