class RemoveChallengeSources < ActiveRecord::Migration[7.1]
  def change
    # Challenges generated from the tracker go; only challenges.yml remains.
    reversible { |dir| dir.up { execute "DELETE FROM challenges WHERE source_type IS NOT NULL" } }
    remove_index :challenges, [:source_type, :source_id], unique: true
    remove_column :challenges, :source_type, :string
    remove_column :challenges, :source_id, :integer
    add_index :challenges, :title, unique: true
  end
end
