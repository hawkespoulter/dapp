class RenameChallengeDifficultyToReward < ActiveRecord::Migration[7.1]
  def change
    rename_column :challenges, :difficulty, :reward
  end
end
