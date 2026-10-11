# Coins are the only currency now: influence the team had bought but not yet
# placed goes back into the coin pool (1 coin each) before the stash goes.
class MergeInfluenceIntoCoins < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE games SET coins = coins + influence_stash"
    remove_column :games, :influence_stash
  end

  def down
    add_column :games, :influence_stash, :integer, default: 0, null: false
  end
end
