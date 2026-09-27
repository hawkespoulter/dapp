require "test_helper"
require_relative "game_test_helper"

class VaderTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game(park: "Hollywood Studios")
    @engine = Games::VillainEngine.new(@game)
    @now = @game.started_at
  end

  test "Hollywood Studios is playable, with Vader rising from Galaxy's Edge" do
    assert_includes Game.playable_parks, "Hollywood Studios"
    assert_equal "vader", @game.villain_key
    assert @game.area("Galaxy's Edge").villain?
    assert_equal 7, @game.area_states.size
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

  test "Youngling: his turn takes your weakest area at 3 or less next to him" do
    neutral_board!(@game)
    set_area(@game, "Galaxy's Edge", owner: "villain", strength: 9)
    set_area(@game, "Toy Story Land", owner: "players", strength: 3)
    set_area(@game, "Muppet Courtyard", owner: "players", strength: 2)
    set_area(@game, "Echo Lake", owner: "players", strength: 1) # not next to him
    @game.villain_draw = ["area:Sunset Boulevard"]
    @engine.villain_turn(@now)

    assert @game.area("Muppet Courtyard").villain?
    assert_equal 2, @game.area("Muppet Courtyard").strength, "it keeps its influence"
    assert @game.area("Toy Story Land").players?, "only one area a turn"
    assert @game.area("Echo Lake").players?
    assert_equal "Youngling", @game.villain_turns.last[:events].find { _1[:action] }[:action]
  end

  test "Youngling leaves areas above 3 and shielded areas alone" do
    neutral_board!(@game)
    set_area(@game, "Galaxy's Edge", owner: "villain", strength: 9)
    set_area(@game, "Toy Story Land", owner: "players", strength: 4)
    set_area(@game, "Muppet Courtyard", owner: "players", strength: 1)
    @game.set_power("shields", ["Muppet Courtyard"])
    @game.villain_draw = ["area:Sunset Boulevard"]
    @engine.villain_turn(@now)

    assert @game.area("Toy Story Land").players?
    assert @game.area("Muppet Courtyard").players?
  end
end
