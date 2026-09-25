class CreateParkGame < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.string :join_code, null: false
      t.string :park, null: false
      t.string :villain_key, null: false
      t.string :preset, null: false
      t.string :status, null: false, default: "lobby"
      t.string :result
      t.datetime :started_at
      t.datetime :ends_at
      t.datetime :next_tick_at
      t.integer :tick_count, null: false, default: 0
      t.integer :escalation, null: false, default: 0
      t.integer :outbreaks, null: false, default: 0
      t.json :villain_draw, null: false, default: []
      t.json :villain_discard, null: false, default: []
      t.json :challenge_discard, null: false, default: []
      t.json :rules, null: false, default: {}
      t.timestamps
    end
    add_index :games, :join_code, unique: true

    create_table :players do |t|
      t.references :game, null: false, foreign_key: true
      t.string :name, null: false
      t.string :auth_token, null: false
      t.boolean :host, null: false, default: false
      t.integer :coins, null: false, default: 0
      t.json :hand, null: false, default: []
      t.timestamps
    end
    add_index :players, :auth_token, unique: true

    create_table :area_states do |t|
      t.references :game, null: false, foreign_key: true
      t.string :area, null: false
      t.string :owner, null: false, default: "neutral"
      t.integer :influence, null: false, default: 0
      t.boolean :locked, null: false, default: false
      t.timestamps
    end
    add_index :area_states, [:game_id, :area], unique: true

    create_table :challenges do |t|
      t.string :title, null: false
      t.text :description
      t.string :category, null: false
      t.integer :difficulty, null: false, default: 1
      t.string :park
      t.string :area
      t.string :source_type
      t.integer :source_id
      t.timestamps
    end
    add_index :challenges, [:park, :area]
    add_index :challenges, [:source_type, :source_id], unique: true

    create_table :game_events do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, foreign_key: true
      t.string :kind, null: false
      t.string :message, null: false
      t.json :data, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end
  end
end
