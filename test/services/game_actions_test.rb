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

  test "only parks with a villain can be created" do
    error = assert_raises(Games::Actions::Invalid) do
      Games::Actions.create!(park: "Epcot", preset: "sprint", host_name: "Hawkes")
    end
    assert_match "villain", error.message
  end

  test "completing a challenge in a neutral area claims it and pays coins" do
    give(@host, :anywhere_easy, area: "Adventureland")
    act.complete!(challenges(:anywhere_easy).id, @now)

    assert @game.area("Adventureland").reload.players?
    assert_equal 1, @host.reload.coins
    assert_equal 1, @host.hand.size
    refute_includes @host.hand, challenges(:anywhere_easy).id
  end

  test "influence must be worn down before an area is claimed" do
    set_area(@game, "Adventureland", influence: 2)
    give(@host, :anywhere_easy, area: "Adventureland")
    act.complete!(challenges(:anywhere_easy).id, @now)

    state = @game.area("Adventureland").reload
    assert state.neutral?
    assert_equal 1, state.influence
  end

  test "an owned area is locked with a difficulty 2+ challenge" do
    set_area(@game, "Adventureland", owner: "players")
    give(@host, :anywhere_easy, area: "Adventureland")
    error = assert_raises(Games::Actions::Invalid) { act.complete!(challenges(:anywhere_easy).id, @now) }
    assert_match "difficulty 2+", error.message

    give(@host, :anywhere_medium, area: "Adventureland")
    act.complete!(challenges(:anywhere_medium).id, @now)
    assert @game.area("Adventureland").reload.locked?
  end

  test "area challenges must be done in their area" do
    give(@host, :adventureland_easy, area: "Frontierland")
    error = assert_raises(Games::Actions::Invalid) { act.complete!(challenges(:adventureland_easy).id, @now) }
    assert_match "Adventureland", error.message
  end

  test "attacking a villain area needs an adjacent players area" do
    set_area(@game, "Frontierland", owner: "villain", influence: 3)
    give(@host, :anywhere_hard, area: "Frontierland")
    assert_raises(Games::Actions::Invalid) { act.complete!(challenges(:anywhere_hard).id, @now) }

    set_area(@game, "Adventureland", owner: "players")
    act.complete!(challenges(:anywhere_hard).id, @now)
    assert @game.area("Frontierland").reload.players?
  end

  test "Thorn Wall blocks easy challenges next to a villain-held Fantasyland" do
    give(@host, :anywhere_easy, area: "Tomorrowland")
    set_area(@game, "Fantasyland", owner: "villain", influence: 3)
    error = assert_raises(Games::Actions::Invalid) { act.complete!(challenges(:anywhere_easy).id, @now) }
    assert_match "difficulty 2+", error.message
  end

  test "locking every area wins the game" do
    @game.area_states.each { _1.update!(owner: "players", locked: true, influence: 0) }
    set_area(@game, "Adventureland", locked: false)
    give(@host, :anywhere_medium, area: "Adventureland")
    act.complete!(challenges(:anywhere_medium).id, @now)

    assert @game.reload.finished?
    assert_equal "gold", @game.result
  end

  test "villain turns that came due are played before a player's action" do
    @game.update!(villain_draw: Array.new(5) { "area:Adventureland" })
    give(@host, :anywhere_easy, area: "Tomorrowland")
    act.complete!(challenges(:anywhere_easy).id, @game.started_at + @game.tick_seconds + 60)

    assert_equal 1, @game.reload.tick_count
    assert_equal 1, @game.area("Adventureland").influence
  end

  test "failing a challenge swaps the card" do
    give(@host, :anywhere_easy, area: "Adventureland")
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

  test "undo reverses a claim, coins and the hand" do
    set_area(@game, "Adventureland", influence: 1)
    give(@host, :anywhere_medium, area: "Adventureland")
    act.complete!(challenges(:anywhere_medium).id, @now)
    act.undo!(@now + 1.minute)

    state = @game.area("Adventureland").reload
    assert state.neutral?
    assert_equal 1, state.influence
    assert_equal 0, @host.reload.coins
    assert_equal [challenges(:anywhere_medium).id], @host.hand
    assert_equal "undo", @game.game_events.last.kind
    assert_raises(Games::Actions::Invalid) { act.undo!(@now + 2.minutes) }
  end

  test "undo is refused once the villain has touched the area" do
    give(@host, :anywhere_easy, area: "Adventureland")
    act.complete!(challenges(:anywhere_easy).id, @now)
    Games::VillainEngine.new(@game).add_influence("Adventureland", 1, @now)

    error = assert_raises(Games::Actions::Invalid) { act.undo!(@now) }
    assert_match "changed", error.message
  end

  test "undo can take back a winning claim" do
    @game.area_states.each { _1.update!(owner: "players", locked: true, influence: 0) }
    set_area(@game, "Adventureland", locked: false)
    give(@host, :anywhere_medium, area: "Adventureland")
    act.complete!(challenges(:anywhere_medium).id, @now)
    assert @game.reload.finished?

    act.undo!(@now)
    @game.reload
    assert @game.active?
    assert_nil @game.result
    refute @game.area("Adventureland").locked?
    assert @game.next_tick_at.present?
  end

  test "undo restores a failed card" do
    give(@host, :anywhere_easy, area: "Adventureland")
    act.fail!(challenges(:anywhere_easy).id, @now)
    act.undo!(@now)

    assert_equal [challenges(:anywhere_easy).id], @host.reload.hand
  end
end
