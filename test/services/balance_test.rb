require "test_helper"
require_relative "game_test_helper"

class BalanceTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game(preset: "full_day")
    @now = @game.started_at + 1.minute
  end

  def act = Games::Actions.new(@game, @host)

  test "a running game's balance can be changed, and it's logged" do
    old_tick = @game.settings["tick_minutes"]
    act.update_balance!({ "tick_minutes" => "99", "influence_price" => "2", "hard_mode" => "false" }, @now)
    @game.reload

    assert_equal 99, @game.settings["tick_minutes"]
    assert_equal 2, @game.influence_price
    refute @game.hard_mode?
    assert_match "Villain moves every (minutes) #{old_tick} → 99", @game.game_events.last.message
    assert_match "Hard mode: the villain also moves when you fail a challenge on → off", @game.game_events.last.message
  end

  test "only settings that still matter mid-game can change" do
    act.update_balance!({ "starting_strength" => "99", "risings" => "0", "tick_minutes" => "30" }, @now)
    @game.reload

    assert_equal 30, @game.settings["tick_minutes"]
    assert_equal GamePreset::DEFAULTS["full_day"]["starting_strength"], @game.settings["starting_strength"]
    refute_includes @game.state_for(@host)[:balance][:fields].pluck(:key), "risings"
  end

  test "bad values are refused and nothing changes" do
    old_tick = @game.settings["tick_minutes"]
    error = assert_raises(Games::Actions::Invalid) { act.update_balance!({ "tick_minutes" => "0" }, @now) }
    assert_match "Villain moves every", error.message
    assert_equal old_tick, @game.reload.settings["tick_minutes"]
  end

  test "a new game length moves the end of the game" do
    act.update_balance!({ "hours" => "4" }, @now)
    assert_equal @game.started_at + 4.hours, @game.reload.ends_at

    error = assert_raises(Games::Actions::Invalid) { act.update_balance!({ "hours" => "1" }, @game.started_at + 2.hours) }
    assert_match "before now", error.message
  end

  test "hands grow or shrink to a new hand size" do
    act.update_balance!({ "hand_size" => "4" }, @now)
    assert_equal 4, @host.reload.hand.size

    kept = @host.hand.first(2)
    act.update_balance!({ "hand_size" => "2" }, @now)
    assert_equal kept, @host.reload.hand
  end

  test "a finished game can't be changed" do
    @game.update!(status: "finished", result: "lost")
    assert_raises(Games::Actions::Invalid) { act.update_balance!({ "tick_minutes" => "50" }, @now) }
  end
end
