class CreateGamePresets < ActiveRecord::Migration[7.1]
  def change
    create_table :game_presets do |t|
      t.string :key, null: false
      t.integer :position, null: false, default: 0
      t.json :settings, null: false, default: {}
      t.timestamps
    end
    add_index :game_presets, :key, unique: true
  end
end
