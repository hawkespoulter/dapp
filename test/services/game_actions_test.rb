require "test_helper"
require_relative "game_test_helper"

class GameActionsTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game
    @game.update!(villain_draw: []) # keep the villain quiet unless a test wants it
    neutral_board!(@game)
    @now = @game.started_at + 1.minute
  end

  def act(player = @host) = Games::Actions.new(@game, player)

  def stash!(count)
    @game.update!(influence_stash: count)
  end

  test "only parks with a villain can be created" do
    error = assert_raises(Games::Actions::Invalid) do
      Games::Actions.create!(park: "Epcot", preset: "sprint", host_name: "Hawkes")
    end
    assert_match "villain", error.message
  end

  test "completing a challenge pays coins into the team pool and draws a new card" do
    give(@host, :anywhere_hard)
    act.complete!(challenges(:anywhere_hard).id, @now)

    assert_equal 3, @game.reload.coins
    assert_equal 3, @host.reload.coins
    assert_equal 1, @host.hand.size
    refute_includes @host.hand, challenges(:anywhere_hard).id
  end

  test "area challenges can be completed from anywhere" do
    give(@host, :adventureland_easy)
    act.complete!(challenges(:adventureland_easy).id, @now)

    assert_equal 1, @game.reload.coins
  end

  test "coins buy influence at the preset price" do
    price = @game.influence_price
    @game.update!(coins: (2 * price) + price - 1)
    act.buy_influence!(2, @now)

    assert_equal price - 1, @game.reload.coins
    assert_equal 2, @game.influence_stash
    assert_raises(Games::Actions::Invalid) { act.buy_influence!(1, @now) }
  end

  test "three influence claims an unclaimed area" do
    stash!(3)
    act.place_influence!("Adventureland", 2, @now)
    assert_equal 2, @game.area("Adventureland").reload.claim
    assert @game.area("Adventureland").neutral?

    act.place_influence!("Adventureland", 1, @now)
    state = @game.area("Adventureland").reload
    assert state.players?
    assert_equal 0, state.claim
    assert_equal 0, @game.reload.influence_stash
  end

  test "influence clears the villain's influence before building a claim" do
    set_area(@game, "Adventureland", influence: 2)
    stash!(3)
    act.place_influence!("Adventureland", 3, @now)

    state = @game.area("Adventureland").reload
    assert_equal 0, state.influence
    assert_equal 1, state.claim
  end

  test "two influence locks one of our areas and the rest stays in the stash" do
    set_area(@game, "Adventureland", owner: "players")
    stash!(5)
    act.place_influence!("Adventureland", 5, @now)

    assert @game.area("Adventureland").reload.locked?
    assert_equal 3, @game.reload.influence_stash
  end

  test "attacking a villain area needs an adjacent players area" do
    set_area(@game, "Frontierland", owner: "villain", influence: 2)
    stash!(5)
    assert_raises(Games::Actions::Invalid) { act.place_influence!("Frontierland", 5, @now) }

    set_area(@game, "Adventureland", owner: "players")
    act.place_influence!("Frontierland", 5, @now)
    assert @game.area("Frontierland").reload.players?
  end

  test "Thorn Wall doubles the cost next to a villain-held Fantasyland" do
    set_area(@game, "Fantasyland", owner: "villain", influence: 3)
    stash!(4)
    error = assert_raises(Games::Actions::Invalid) { act.place_influence!("Tomorrowland", 1, @now) }
    assert_match "Thorn Wall", error.message

    act.place_influence!("Tomorrowland", 3, @now)
    assert_equal 1, @game.area("Tomorrowland").reload.claim
    assert_equal 2, @game.reload.influence_stash
  end

  test "the villain eats a claim in progress before adding influence" do
    set_area(@game, "Adventureland", claim: 2)
    Games::VillainEngine.new(@game).add_influence("Adventureland", 3, @now)

    state = @game.area("Adventureland")
    assert_equal 0, state.claim
    assert_equal 1, state.influence
  end

  test "locking every area wins the game" do
    @game.area_states.each { _1.update!(owner: "players", locked: true, influence: 0) }
    set_area(@game, "Adventureland", locked: false)
    stash!(2)
    act.place_influence!("Adventureland", 2, @now)

    assert @game.reload.finished?
    assert_equal "gold", @game.result
  end

  test "villain turns that came due are played before a player's action" do
    @game.update!(villain_draw: Array.new(5) { "area:Adventureland" })
    give(@host, :anywhere_easy)
    act.complete!(challenges(:anywhere_easy).id, @game.started_at + @game.tick_seconds + 60)

    assert_equal 1, @game.reload.tick_count
    assert_equal 1, @game.area("Adventureland").influence
  end

  test "failing a challenge swaps the card" do
    give(@host, :anywhere_easy)
    act.fail!(challenges(:anywhere_easy).id, @now)

    assert_equal 1, @host.reload.hand.size
    assert_equal "failed", @game.game_events.last.kind
  end

  test "hands only draw challenges for this park" do
    other = challenges(:other_park).id
    20.times { refute_includes @game.draw_challenges(3), other }
  end

  test "late joiners get a hand" do
    player = act(nil).join!("Wife")
    assert_equal 3, player.reload.hand.size
  end

  test "multi-day games only run the clock during park hours" do
    game, = start_game(preset: "multi_day", at: Time.zone.parse("2026-10-01 20:30"))
    windows = game.clock.windows

    assert_equal 3, windows.size
    assert_equal [Time.zone.parse("2026-10-01 20:30"), Time.zone.parse("2026-10-01 21:00")], windows.first
    assert_equal Time.zone.parse("2026-10-02 09:10"), game.next_tick_at
  end
end

class GameUndoTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game
    @game.update!(villain_draw: [])
    neutral_board!(@game)
    @now = @game.started_at + 1.minute
  end

  def act = Games::Actions.new(@game, @host)

  test "undo takes back a challenge's coins and restores the hand" do
    give(@host, :anywhere_medium)
    act.complete!(challenges(:anywhere_medium).id, @now)
    act.undo!(@now)

    assert_equal 0, @game.reload.coins
    assert_equal 0, @host.reload.coins
    assert_equal [challenges(:anywhere_medium).id], @host.hand
    assert_equal "undo", @game.game_events.last.kind
    assert_raises(Games::Actions::Invalid) { act.undo!(@now) }
  end

  test "undo is refused once the team has spent the coins" do
    give(@host, :anywhere_hard)
    act.complete!(challenges(:anywhere_hard).id, @now)
    @game.reload.update!(coins: 0)

    error = assert_raises(Games::Actions::Invalid) { act.undo!(@now) }
    assert_match "spent", error.message
  end

  test "undo returns placed influence to the stash" do
    @game.update!(influence_stash: 2)
    act.place_influence!("Adventureland", 2, @now)
    act.undo!(@now)

    assert_equal 2, @game.reload.influence_stash
    assert_equal 0, @game.area("Adventureland").claim
  end

  test "undo is refused once the villain has touched the area" do
    @game.update!(influence_stash: 3)
    act.place_influence!("Adventureland", 3, @now)
    Games::VillainEngine.new(@game).add_influence("Adventureland", 1, @now)

    error = assert_raises(Games::Actions::Invalid) { act.undo!(@now) }
    assert_match "changed", error.message
  end

  test "undo can take back a winning placement" do
    @game.area_states.each { _1.update!(owner: "players", locked: true, influence: 0) }
    set_area(@game, "Adventureland", locked: false)
    @game.update!(influence_stash: 2)
    act.place_influence!("Adventureland", 2, @now)
    assert @game.reload.finished?

    act.undo!(@now)
    @game.reload
    assert @game.active?
    assert_nil @game.result
    refute @game.area("Adventureland").locked?
    assert @game.next_tick_at.present?
  end

  test "undo restores a failed card" do
    give(@host, :anywhere_easy)
    act.fail!(challenges(:anywhere_easy).id, @now)
    act.undo!(@now)

    assert_equal [challenges(:anywhere_easy).id], @host.reload.hand
  end
end
