require "test_helper"
require_relative "game_test_helper"

class ScarTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, = start_game(park: "Animal Kingdom")
    @engine = Games::VillainEngine.new(@game)
    @now = @game.started_at
  end

  test "Animal Kingdom starts two areas each with one unclaimed, Scar in Africa" do
    owners = @game.area_states.map(&:owner).tally
    assert_equal({ "villain" => 2, "players" => 2, "neutral" => 1 }, owners)
    assert @game.area("Africa").villain?
  end

  test "Usurper: knocking an area to 0 hands it straight to Scar" do
    neutral_board!(@game)
    set_area(@game, "Pandora", owner: "players", strength: 1)
    @engine.push("Pandora", 1, @now)

    assert @game.area("Pandora").villain?
    assert_equal 1, @game.area("Pandora").strength
  end

  test "Be Prepared: every turn his hyenas hit each players area bordering his" do
    neutral_board!(@game)
    set_area(@game, "Africa", owner: "villain", strength: 1)
    set_area(@game, "Pandora", owner: "players", strength: 2)
    set_area(@game, "Asia", owner: "players", strength: 2)
    set_area(@game, "DinoLand U.S.A.", owner: "players", strength: 2)
    @game.villain_draw = ["area:Africa"]
    @engine.villain_turn(@now)

    assert_equal 1, @game.area("Pandora").strength
    assert_equal 1, @game.area("Asia").strength
    assert_equal 2, @game.area("DinoLand U.S.A.").strength # borders no Scar area
  end
end
