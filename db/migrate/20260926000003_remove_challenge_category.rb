class RemoveChallengeCategory < ActiveRecord::Migration[7.1]
  def change
    remove_column :challenges, :category, :string, null: false, default: "find"
  end
end
