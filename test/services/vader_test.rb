require "test_helper"
require_relative "game_test_helper"

class VaderTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game(park: "Hollywood Studios")
    @engine = Games::VillainEngine.new(@game)
    @now = @game.started_at
  end

  test "Hollywood Studios is playable, with Vader holding three of its seven areas" do
    assert_includes Game.playable_parks, "Hollywood Studios"
    assert_equal "vader", @game.villain_key
    assert_equal 7, @game.area_states.size
    assert_equal({ "villain" => 3, "players" => 3, "neutral" => 1 }, @game.area_states.map(&:owner).tally)
  end

  test "the Youngling threshold is a setting, and his rules show it" do
    assert_equal 2, @game.settings["youngling_max"]
    assert_match "2 or less influence", @game.state_for(@host)[:villain].rules.second

    @game.rules = @game.rules.merge("settings" => @game.settings.merge("youngling_max" => 4))
    assert_match "4 or less influence", @game.villain.rules.second
  end

  test "Might of the Empire: his own area cards place 2" do
    neutral_board!(@game)
    set_area(@game, "Galaxy's Edge", owner: "villain", strength: 1)
    @game.villain_draw = ["area:Galaxy's Edge"]
    @engine.villain_turn(@now)

    assert_equal 3, @game.area("Galaxy's Edge").strength
  end

  test "Might of the Empire doesn't change cards for areas that aren't his" do
    neutral_board!(@game)
    set_area(@game, "Echo Lake", owner: "players", strength: 5)
    @game.villain_draw = ["area:Echo Lake"]
    @engine.villain_turn(@now)

    assert_equal 4, @game.area("Echo Lake").strength
  end

  test "a spilling area of his grows by 2 and its neighbors by 1" do
    neutral_board!(@game)
    set_area(@game, "Echo Lake", owner: "villain", strength: 3)
    set_area(@game, "Muppet Courtyard", owner: "players", strength: 5)
    @game.villain_draw = ["area:Echo Lake"]
    @engine.villain_turn(@now)

    assert_equal 5, @game.area("Echo Lake").strength
    assert_equal 4, @game.area("Muppet Courtyard").strength
  end

  test "Youngling: his turn takes your weakest area at or below the threshold (2) next to him" do
    neutral_board!(@game)
    set_area(@game, "Galaxy's Edge", owner: "villain", strength: 9)
    set_area(@game, "Toy Story Land", owner: "players", strength: 2)
    set_area(@game, "Muppet Courtyard", owner: "players", strength: 1)
    set_area(@game, "Echo Lake", owner: "players", strength: 1) # not next to him
    @game.villain_draw = ["area:Sunset Boulevard"]
    @engine.villain_turn(@now)

    assert @game.area("Muppet Courtyard").villain?
    assert_equal 1, @game.area("Muppet Courtyard").strength, "it keeps its influence"
    assert @game.area("Toy Story Land").players?, "only one area a turn"
    assert @game.area("Echo Lake").players?
    assert_equal "Youngling", @game.villain_turns.last[:events].find { _1[:action] }[:action]
  end

  test "Youngling leaves areas above the threshold and shielded areas alone" do
    neutral_board!(@game)
    set_area(@game, "Galaxy's Edge", owner: "villain", strength: 9)
    set_area(@game, "Toy Story Land", owner: "players", strength: 3)
    set_area(@game, "Muppet Courtyard", owner: "players", strength: 1)
    @game.set_power("shields", ["Muppet Courtyard"])
    @game.villain_draw = ["area:Sunset Boulevard"]
    @engine.villain_turn(@now)

    assert @game.area("Toy Story Land").players?
    assert @game.area("Muppet Courtyard").players?
  end
end
