require "test_helper"
require_relative "game_test_helper"

class PowerUpsTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game
    neutral_board!(@game)
    @game.update!(coins: 20)
    @now = @game.started_at + 1.minute
    @engine = Games::VillainEngine.new(@game)
  end

  def act = Games::Actions.new(@game, @host)
  def price(power) = @game.settings["price_#{power}"]

  test "power-ups cost team coins and refuse when the team can't pay" do
    act.use_power!("stall", now: @now)
    assert_equal 20 - price("stall"), @game.reload.coins

    @game.update!(coins: 0)
    error = assert_raises(Games::Actions::Invalid) { act.use_power!("stall", now: @now) }
    assert_match "costs", error.message
  end

  test "games from before power-ups use the default prices" do
    @game.update!(rules: @game.rules.merge("settings" => @game.settings.except("price_stall")))
    act.use_power!("stall", now: @now)

    assert_equal 20 - GamePreset::DEFAULTS["full_day"]["price_stall"], @game.reload.coins
  end

  test "Forecast shows the next three cards and throws away the one you pick" do
    @game.update!(villain_draw: %w[area:Adventureland rising area:Tomorrowland area:Frontierland], villain_discard: [])
    act.use_power!("forecast", now: @now)
    assert_equal %w[area:Adventureland rising area:Tomorrowland], @game.reload.state_for(@host)[:powers][:forecast]

    act.forecast_discard!(1, @now)
    @game.reload
    assert_equal %w[area:Adventureland area:Tomorrowland area:Frontierland], @game.villain_draw
    assert_equal %w[rising], @game.villain_discard
    assert_nil @game.state_for(@host)[:powers][:forecast]
  end

  test "a forecast runs out when the villain takes her turn" do
    @game.update!(villain_draw: %w[area:Adventureland area:Tomorrowland area:Frontierland area:Fantasyland])
    act.use_power!("forecast", now: @now)
    @game.reload
    @engine.villain_turn(@now)
    @game.save!

    assert_raises(Games::Actions::Invalid) { act.forecast_discard!(0, @now) }
  end

  test "Stall skips the villain's next turn" do
    @game.update!(villain_draw: %w[area:Adventureland area:Tomorrowland])
    act.use_power!("stall", now: @now)
    @game.reload
    @engine.villain_turn(@now)

    assert @game.area_states.all?(&:neutral?)
    assert_equal %w[area:Adventureland area:Tomorrowland], @game.villain_draw
    assert_equal({ action: "Stall", actor: "players" }, @game.villain_turns.last[:events].last.slice(:action, :actor))

    @engine.villain_turn(@now)
    assert @game.area("Adventureland").villain?, "only one turn is skipped"
  end

  test "Shield keeps one of your areas safe for the villain's next turn only" do
    set_area(@game, "Adventureland", owner: "players", strength: 1)
    assert_raises(Games::Actions::Invalid) { act.use_power!("shield", area: "Tomorrowland", now: @now) }

    act.use_power!("shield", area: "Adventureland", now: @now)
    @game.reload
    @game.villain_draw = %w[area:Adventureland area:Adventureland]
    @engine.villain_turn(@now)
    assert_equal ["players", 1], [@game.area("Adventureland").owner, @game.area("Adventureland").strength]

    @engine.villain_turn(@now)
    assert @game.area("Adventureland").neutral?, "the shield is gone after one turn"
  end

  test "Redraw swaps the whole hand" do
    old = @host.hand
    act.use_power!("redraw", now: @now)

    assert_equal old.size, @host.reload.hand.size
    assert_empty old & @host.hand
  end

  test "Double Down doubles the next completed challenge, and undo gives it back" do
    act.use_power!("double_down", now: @now)
    give(@host, :anywhere_hard)
    act.complete!(challenges(:anywhere_hard).id, @now)
    assert_equal 20 - price("double_down") + 6, @game.reload.coins
    assert_equal 0, @game.state_for(@host)[:powers][:double_down]

    act.undo!(@now)
    assert_equal 1, @game.reload.state_for(@host)[:powers][:double_down]
  end

  test "Safety Net lets a hard-mode fail leave the villain alone, and keeps it undoable" do
    act.use_power!("safety_net", now: @now)
    give(@host, :anywhere_easy)
    act.fail!(challenges(:anywhere_easy).id, @now)
    assert_equal 0, @game.reload.tick_count

    act.undo!(@now)
    assert_equal 1, @game.reload.state_for(@host)[:powers][:safety_net]
  end

  test "Safety Net isn't sold outside hard mode" do
    @game.update!(rules: @game.rules.merge("settings" => @game.settings.merge("hard_mode" => false)))
    assert_raises(Games::Actions::Invalid) { act.use_power!("safety_net", now: @now) }
  end

  test "power-ups can't be undone and lock in what came before" do
    give(@host, :anywhere_easy)
    act.complete!(challenges(:anywhere_easy).id, @now)
    act.use_power!("stall", now: @now)

    assert_nil @game.reload.state_for(@host)[:me][:undo]
    error = assert_raises(Games::Actions::Invalid) { act.undo!(@now) }
    assert_match "can't be undone", error.message
  end
end
