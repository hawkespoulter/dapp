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
    villain.each do |state|
      next if state.area == "Fantasyland"

      assert @game.board.neighbors(state.area).any? { @game.area(_1).villain? }, "#{state.area} should touch her other areas"
    end
  end

  test "each side scatters its starting strength over its areas" do
    %w[villain players].each do |side|
      strengths = @game.area_states.select { _1.owner == side }.map(&:strength)
      assert_equal 10, strengths.sum
      assert strengths.all?(&:positive?)
    end
  end

  test "the starting split and strengths change from game to game" do
    starts = 8.times.map do |seed|
      game, = start_game(seed:)
      game.area_states.sort_by(&:area).map { [_1.owner, _1.strength] }
    end
    assert starts.uniq.size > 1
  end

  test "starting sets up the deck, clock and hands" do
    assert_equal 12 + 4, @game.villain_draw.size
    assert_equal 4, @game.villain_draw.count("rising")
    assert_equal @game.started_at + @game.tick_seconds, @game.next_tick_at
    assert_equal @game.started_at + 10.hours, @game.ends_at
    assert_equal 3, @host.hand.size
  end

  test "the villain weakens a players area and knocks it to unclaimed at 0" do
    neutral_board!(@game)
    set_area(@game, "Adventureland", owner: "players", strength: 2)
    @engine.push("Adventureland", 1, @now)
    assert_equal ["players", 1], [@game.area("Adventureland").owner, @game.area("Adventureland").strength]

    @engine.push("Adventureland", 1, @now)
    assert @game.area("Adventureland").neutral?
    assert_equal 0, @game.area("Adventureland").strength
  end

  test "the villain claims an unclaimed area at the strength she pushes in" do
    neutral_board!(@game)
    @engine.push("Adventureland", 1, @now)

    assert @game.area("Adventureland").villain?
    assert_equal 1, @game.area("Adventureland").strength
    assert_equal "takeover", @game.game_events.last.kind
  end

  test "a push bigger than a players area's strength knocks it out and claims it" do
    neutral_board!(@game)
    set_area(@game, "Adventureland", owner: "players", strength: 1)
    @engine.push("Adventureland", 3, @now)

    assert @game.area("Adventureland").villain?
    assert_equal 2, @game.area("Adventureland").strength
  end

  test "drawing a villain area strengthens it until it is strong enough to break out" do
    neutral_board!(@game)
    set_area(@game, "Tomorrowland", owner: "villain", strength: 2)
    @engine.push("Tomorrowland", 1, @now)
    assert_equal 3, @game.area("Tomorrowland").strength
    assert_equal 0, @game.outbreaks

    @engine.push("Tomorrowland", 1, @now)
    assert_equal 1, @game.outbreaks
    assert_equal 4, @game.area("Tomorrowland").strength, "a spilling area grows too"
    assert @game.area("Main Street, U.S.A.").villain?
    assert @game.area("Fantasyland").villain?
  end

  test "outbreaks weaken players areas next door" do
    neutral_board!(@game)
    set_area(@game, "Frontierland", owner: "villain", strength: 5)
    set_area(@game, "Adventureland", owner: "players", strength: 4)
    @engine.push("Frontierland", 1, @now)

    assert_equal 3, @game.area("Adventureland").strength
    assert @game.area("Liberty Square").villain?
  end

  test "Dragon Form doubles what outbreaks push from the second rising" do
    neutral_board!(@game)
    @game.escalation = 2
    set_area(@game, "Frontierland", owner: "villain", strength: 3)
    set_area(@game, "Adventureland", owner: "players", strength: 4)
    @engine.push("Frontierland", 1, @now)

    assert_equal 2, @game.area("Adventureland").strength
  end

  test "a villain rising adds a card to every turn, starting with the one it's drawn on" do
    neutral_board!(@game)
    @game.villain_draw = ["rising", "area:Adventureland", "area:Tomorrowland", "area:Frontierland", "area:Fantasyland",
                          "area:Liberty Square"]
    @engine.villain_turn(@now)

    assert_equal 1, @game.escalation
    assert %w[Adventureland Tomorrowland].all? { @game.area(_1).villain? }, "the rising isn't one of the cards, and adds one now"
    assert @game.area("Frontierland").neutral?

    @engine.villain_turn(@now)
    assert %w[Frontierland Fantasyland].all? { @game.area(_1).villain? }, "later turns play two cards too"
    assert @game.area("Liberty Square").neutral?
  end

  test "spilling over never loses the game by itself" do
    neutral_board!(@game)
    @game.outbreaks = 50
    set_area(@game, "Frontierland", owner: "villain", strength: 3)
    @engine.push("Frontierland", 1, @now)

    assert @game.active?
    refute_includes @game.state_for(@host)[:game].keys, :outbreaks
  end

  test "what she does on a turn is grouped under that turn for the pop-up" do
    neutral_board!(@game)
    set_area(@game, "Adventureland", owner: "players", strength: 2)
    @game.villain_draw = ["area:Adventureland", "area:Adventureland"]
    @game.log!("bought", "Someone bought influence.")
    @engine.villain_turn(@now)
    @engine.villain_turn(@now)

    turns = @game.state_for(@host)[:villain_turns]
    assert_equal [1, 2], turns.pluck(:turn)
    assert_equal ["Maleficent plays 1 card.", "Maleficent plays Adventureland.",
                  "Maleficent weakens your hold on Adventureland (strength 1)."],
                 turns.first[:events].pluck(:message)
    assert_equal "Adventureland", turns.first[:events][1][:card]
    assert_equal ["players", 2], turns.first[:events][0][:board]["Adventureland"]
    assert_equal({ area: "Adventureland", owner: "players", strength: 1 },
                 turns.first[:events][2].slice(:area, :owner, :strength))
    assert_equal "lost_area", turns.last[:events].last[:kind]
  end

  test "the testing button makes her move now without moving her timer" do
    next_tick = @game.next_tick_at
    Games::Actions.new(@game, @host).force_villain_turn!(@now)

    assert_equal 1, @game.reload.tick_count
    assert_equal next_tick, @game.next_tick_at
    assert_equal 1, @game.villain_turns.last[:turn]
  end

  test "the villain taking the whole park loses the game" do
    @game.area_states.each { _1.update!(owner: "villain", strength: 1) }
    set_area(@game, "Frontierland", owner: "players", strength: 1)
    @engine.push("Frontierland", 1, @now)
    assert @game.active?

    @engine.push("Frontierland", 1, @now)
    assert_equal "lost", @game.result
  end

  test "advance plays every villain turn that came due" do
    neutral_board!(@game)
    set_area(@game, "Adventureland", owner: "players", strength: 5)
    @game.villain_draw = Array.new(10) { "area:Adventureland" }
    tick = @game.tick_seconds
    @game.advance!(@now + (2 * tick) + 1)

    assert_equal 2, @game.tick_count
    assert_equal @now + (3 * tick), @game.next_tick_at
    assert_equal 3, @game.area("Adventureland").strength
  end

  test "time running out awards a medal by areas held" do
    neutral_board!(@game)
    %w[Adventureland Frontierland Liberty\ Square Tomorrowland].each { set_area(@game, _1, owner: "players", strength: 1) }
    set_area(@game, "Fantasyland", owner: "villain", strength: 1)
    @game.villain_draw = []
    @game.villain_discard = []
    @game.advance!(@game.ends_at)

    assert @game.finished?
    assert_equal "silver", @game.result
  end

  test "a tie at the end is a bronze" do
    @game.update!(villain_draw: [], villain_discard: [])
    @game.advance!(@game.ends_at)

    assert_equal "bronze", @game.result
  end

  test "failed challenges only wake the villain in hard mode" do
    assert @game.hard_mode?, "hard mode is on by default"
    @engine.handle(:challenge_failed, at: @now)
    assert_equal 1, @game.tick_count

    @game.rules = @game.rules.merge("settings" => @game.settings.merge("hard_mode" => false))
    @engine.handle(:challenge_failed, at: @now)
    assert_equal 1, @game.tick_count
  end

  test "the general villain rules use this game's numbers" do
    rules = @game.state_for(@host)[:villain_rules]

    assert_includes rules.first, "every #{@game.settings['tick_minutes']} minutes, and if you fail a challenge"
    assert_includes rules.fourth, "at #{@game.outbreak_at} or more"
    assert_includes rules.fifth, "hides 4 Villain Rising cards. Each one makes the villain play one more card per turn."

    @game.rules = @game.rules.merge("settings" => @game.settings.merge("risings" => 0))
    refute(Games::VillainEngine.general_rules(@game).any? { _1.include?("Rising") })

    @game.rules = @game.rules.merge("settings" => @game.settings.merge("hard_mode" => false))
    refute_includes Games::VillainEngine.general_rules(@game).first, "fail"
  end

  test "games from before hard mode was a setting keep their old rule" do
    @game.rules = { "settings" => @game.settings.except("hard_mode"), "villain_on_fail" => true }
    assert @game.hard_mode?
    @game.rules = { "settings" => @game.settings.except("hard_mode") }
    refute @game.hard_mode?
  end
end
