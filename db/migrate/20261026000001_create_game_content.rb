# Challenges become editable in the app: claim cards and item lists move into
# the database too, and content_seeds remembers which files have been loaded
# so the files seed each park once and never overwrite edits.
class CreateGameContent < ActiveRecord::Migration[7.1]
  def change
    create_table :content_seeds do |t|
      t.string :key, null: false
      t.timestamps
    end
    add_index :content_seeds, :key, unique: true

    create_table :claim_challenges do |t|
      t.string :park, null: false
      t.string :area, null: false
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :claim_challenges, [:park, :area]

    create_table :challenge_lists do |t|
      t.string :name, null: false
      t.json :items, null: false, default: []
      t.timestamps
    end
    add_index :challenge_lists, :name, unique: true
  end
end
