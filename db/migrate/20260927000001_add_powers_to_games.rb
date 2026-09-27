# Power-ups in play: stalls queued, shielded areas, a pending forecast, and
# each player's Double Down / Safety Net charges.
class AddPowersToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :powers, :json, default: {}, null: false
  end
end
