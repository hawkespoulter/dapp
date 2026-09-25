require "test_helper"
require_relative "game_test_helper"

class VillainEngineTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game
    @engine = Games::VillainEngine.new(@game)
    @now = @game.started_at
  end

  test "starting splits the park in half, with the villain spreading from her lair" do
    villain = @game.area_states.select(&:villain?)
    players = @game.area_states.select(&:players?)

    assert_equal 3, villain.size
    assert_equal 3, players.size
    assert_includes villain.map(&:area), "Fantasyland"
    assert villain.all? { _1.influence == 2 }
    assert players.all? { _1.influence.zero? }
    villain.each do |state|
      next if state.area == "Fantasyland"

      assert @game.board.neighbors(state.area).any? { @game.area(_1).villain? }, "#{state.area} should touch her other areas"
    end
  end

  test "the starting split changes from game to game" do
    splits = 8.times.map do |seed|
      game, = start_game(seed:)
      game.area_states.select(&:villain?).map(&:area).sort
    end
    assert splits.uniq.size > 1
  end

  test "drawing a villain area strengthens it, and only full strength outbreaks" do
    neutral_board!(@game)
    set_area(@game, "Tomorrowland", owner: "villain", influence: 2)
    set_area(@game, "Fantasyland", owner: "villain", influence: 2)
    @engine.add_influence("Tomorrowland", 1, @now)
    assert_equal 3, @game.area("Tomorrowland").influence
    assert_equal 0, @game.outbreaks

    @engine.add_influence("Tomorrowland", 1, @now)
    assert_equal 1, @game.outbreaks
    assert_equal 1, @game.area("Main Street, U.S.A.").influence
    assert_equal 3, @game.area("Fantasyland").influence
  end

  test "starting sets up the deck, clock and hands" do
    assert_equal 12 + 4, @game.villain_draw.size
    assert_equal 4, @game.villain_draw.count("rising")
    assert_equal @game.started_at + @game.tick_seconds, @game.next_tick_at
    assert_equal @game.started_at + 10.hours, @game.ends_at
    assert_equal 3, @host.hand.size
  end

  test "third influence lets the villain take an area" do
    neutral_board!(@game)
    @engine.add_influence("Adventureland", 2, @now)
    refute @game.area("Adventureland").villain?

    @engine.add_influence("Adventureland", 1, @now)
    assert @game.area("Adventureland").villain?
    assert_equal "takeover", @game.game_events.last.kind
  end

  test "influence on a full-strength villain area causes an outbreak into every neighbor" do
    neutral_board!(@game)
    set_area(@game, "Frontierland", owner: "villain", influence: 3)
    @engine.add_influence("Frontierland", 1, @now)

    assert_equal 1, @game.outbreaks
    assert_equal 1, @game.area("Adventureland").influence
    assert_equal 1, @game.area("Liberty Square").influence
  end

  test "locked areas ignore influence" do
    neutral_board!(@game)
    set_area(@game, "Tomorrowland", owner: "players", locked: true)
    @engine.add_influence("Tomorrowland", 3, @now)

    assert_equal 0, @game.area("Tomorrowland").influence
    assert @game.area("Tomorrowland").players?
  end

  test "Dragon Form doubles outbreak spread from the second rising" do
    neutral_board!(@game)
    @game.escalation = 2
    set_area(@game, "Frontierland", owner: "villain", influence: 3)
    @engine.add_influence("Frontierland", 1, @now)

    assert_equal 2, @game.area("Adventureland").influence
  end

  test "a villain rising escalates and floods the bottom area card" do
    neutral_board!(@game)
    @game.villain_draw = ["rising", "area:Adventureland", "area:Tomorrowland"]
    @game.villain_discard = ["area:Frontierland"]
    @engine.villain_turn(@now)

    assert_equal 1, @game.escalation
    assert @game.area("Tomorrowland").villain?
    assert_equal %w[area:Adventureland], @game.villain_draw.last(1)
    assert_equal [], @game.villain_discard
  end

  test "hitting the outbreak limit loses the game" do
    neutral_board!(@game)
    @game.outbreaks = @game.outbreak_limit - 1
    set_area(@game, "Frontierland", owner: "villain", influence: 3)
    @engine.add_influence("Frontierland", 1, @now)

    assert @game.finished?
    assert_equal "lost", @game.result
  end

  test "the villain taking the whole park loses the game" do
    @game.area_states.each { _1.update!(owner: "villain", influence: 2) }
    set_area(@game, "Frontierland", owner: "players", influence: 0)
    %w[Main\ Street,\ U.S.A. Adventureland].each { set_area(@game, _1, owner: "villain", influence: 3) }
    @engine.add_influence("Frontierland", 2, @now)
    assert @game.active?

    @engine.add_influence("Frontierland", 1, @now)
    assert_equal "lost", @game.result
  end

  test "advance plays every villain turn that came due" do
    neutral_board!(@game)
    @game.villain_draw = Array.new(10) { "area:Adventureland" }
    tick = @game.tick_seconds
    @game.advance!(@now + (2 * tick) + 1)

    assert_equal 2, @game.tick_count
    assert_equal @now + (3 * tick), @game.next_tick_at
    assert_equal 2, @game.area("Adventureland").influence
  end

  test "time running out awards a medal by share of areas held" do
    neutral_board!(@game)
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
