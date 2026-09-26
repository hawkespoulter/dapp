class AddChallengeLists < ActiveRecord::Migration[7.1]
  def change
    # A challenge can deal some random items from a list file with each card.
    add_column :challenges, :list_from, :string
    add_column :challenges, :list_count, :integer
    # The items each card in a player's hand was dealt, keyed by challenge id.
    add_column :players, :card_lists, :json, null: false, default: {}
  end
end
