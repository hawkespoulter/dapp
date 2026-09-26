class RemoveChallengeArea < ActiveRecord::Migration[7.1]
  def change
    remove_index :challenges, [:park, :area]
    remove_column :challenges, :area, :string
    add_index :challenges, :park
  end
end
