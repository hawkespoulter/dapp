require "test_helper"
require_relative "game_test_helper"

# Challenges that deal random items from a list with each card, like the
# Tree of Life animals.
class ChallengeListTest < ActiveSupport::TestCase
  include GameTestHelper

  setup do
    @game, @host = start_game(park: "Animal Kingdom")
    @game.update!(villain_draw: [])
    @now = @game.started_at + 1.minute
    @tree = Challenge.create!(title: "Tree of Life", park: "Animal Kingdom",
                              reward: 3, list_from: "tree_of_life_animals", list_count: 10)
  end

  def act = Games::Actions.new(@game, @host)

  def deal_tree
    @host.deal([@tree.id], @game.rng)
    @host.save!
  end

  test "the real tree of life list deals 10 different animals" do
    animals = @tree.deal_list(Random.new(1))
    assert_equal 10, animals.size
    assert_equal 10, animals.uniq.size
    assert (animals - @tree.list_items).empty?
  end

  test "a dealt card shows its animals and keeps them while held" do
    deal_tree
    first = @host.hand_cards.first[:list]
    assert_equal 10, first.size

    @host.deal([@tree.id, challenges(:anywhere_easy).id], @game.rng)
    assert_equal first, @host.hand_cards.find { _1[:id] == @tree.id }[:list]
    assert_nil @host.hand_cards.find { _1[:id] == challenges(:anywhere_easy).id }[:list]
  end

  test "undo brings the card back with the same animals" do
    deal_tree
    animals = @host.reload.card_lists[@tree.id.to_s]
    act.complete!(@tree.id, @now)
    refute_includes @host.reload.hand, @tree.id

    act.undo!(@now)
    assert_equal animals, @host.reload.card_lists[@tree.id.to_s]
  end

  test "a list that doesn't exist or is too short is a mistake" do
    missing = Challenge.new(title: "X", reward: 1, list_from: "nope", list_count: 3)
    refute missing.valid?
    assert_match "lists/nope.yml doesn't exist", missing.errors.full_messages.to_sentence

    greedy = Challenge.new(title: "Y", reward: 1, list_from: "tree_of_life_animals", list_count: 500)
    refute greedy.valid?
    assert_match "count must be from 1 to", greedy.errors.full_messages.to_sentence
  end
end
