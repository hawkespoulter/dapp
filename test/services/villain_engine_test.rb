require "test_helper"
require_relative "game_test_helper"

class VillainEngineTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game
    @engine = Games::VillainEngine.new(@game)
    @now = @game.started_at
  end

  test "starting sets up lair, deck, clock and hands" do
    assert_equal 2, @game.area("Fantasyland").influence
    assert_equal 12 + 4, @game.villain_draw.size
    assert_equal 4, @game.villain_draw.count("rising")
    assert_equal @game.started_at + 30.minutes, @game.next_tick_at
    assert_equal @game.started_at + 10.hours, @game.ends_at
    assert_equal 3, @host.hand.size
  end

  test "third influence lets the villain take an area" do
    @engine.add_influence("Adventureland", 2, @now)
    refute @game.area("Adventureland").villain?

    @engine.add_influence("Adventureland", 1, @now)
    assert @game.area("Adventureland").villain?
    assert_equal "takeover", @game.game_events.last.kind
  end

  test "influence on a villain area causes an outbreak into every neighbor" do
    set_area(@game, "Frontierland", owner: "villain", influence: 3)
    @engine.add_influence("Frontierland", 1, @now)

    assert_equal 1, @game.outbreaks
    assert_equal 1, @game.area("Adventureland").influence
    assert_equal 1, @game.area("Liberty Square").influence
  end

  test "locked areas ignore influence" do
    set_area(@game, "Tomorrowland", owner: "players", locked: true)
    @engine.add_influence("Tomorrowland", 3, @now)

    assert_equal 0, @game.area("Tomorrowland").influence
    assert @game.area("Tomorrowland").players?
  end

  test "Dragon Form doubles outbreak spread from the second rising" do
    @game.escalation = 2
    set_area(@game, "Frontierland", owner: "villain", influence: 3)
    @engine.add_influence("Frontierland", 1, @now)

    assert_equal 2, @game.area("Adventureland").influence
  end

  test "a villain rising escalates and floods the bottom area card" do
    @game.villain_draw = ["rising", "area:Adventureland", "area:Tomorrowland"]
    @game.villain_discard = ["area:Frontierland"]
    @engine.villain_turn(@now)

    assert_equal 1, @game.escalation
    assert @game.area("Tomorrowland").villain?
    assert_equal %w[area:Adventureland], @game.villain_draw.last(1)
    assert_equal [], @game.villain_discard
  end

  test "hitting the outbreak limit loses the game" do
    @game.outbreaks = @game.outbreak_limit - 1
    set_area(@game, "Frontierland", owner: "villain", influence: 3)
    @engine.add_influence("Frontierland", 1, @now)

    assert @game.finished?
    assert_equal "lost", @game.result
  end

  test "holding the lair and two neighbors loses the game" do
    set_area(@game, "Fantasyland", owner: "villain", influence: 3)
    set_area(@game, "Tomorrowland", owner: "villain", influence: 3)
    @engine.add_influence("Main Street, U.S.A.", 3, @now)

    assert_equal "lost", @game.result
  end

  test "advance plays every villain turn that came due" do
    @game.villain_draw = Array.new(10) { "area:Adventureland" }
    @game.advance!(@now + 61.minutes)

    assert_equal 2, @game.tick_count
    assert_equal @now + 90.minutes, @game.next_tick_at
    assert_equal 2, @game.area("Adventureland").influence
  end

  test "time running out awards a medal by share of areas held" do
    %w[Adventureland Frontierland Liberty\ Square Tomorrowland].each { set_area(@game, _1, owner: "players") }
    @game.villain_draw = []
    @game.villain_discard = []
    @game.advance!(@game.ends_at)

    assert @game.finished?
    assert_equal "silver", @game.result
  end

  test "failed challenges only wake the villain when the rule is on" do
    @engine.handle(:challenge_failed, at: @now)
    assert_equal 0, @game.tick_count

    @game.rules = @game.rules.merge("villain_on_fail" => true)
    @engine.handle(:challenge_failed, at: @now)
    assert_equal 1, @game.tick_count
  end
end
