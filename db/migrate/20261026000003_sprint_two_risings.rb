# Sprint's default went from 1 Villain Rising to 2. Presets keep tuned
# values in the database, so move a Sprint still on the old default.
class SprintTwoRisings < ActiveRecord::Migration[7.1]
  class Preset < ActiveRecord::Base
    self.table_name = "game_presets"
  end

  def up
    Preset.where(key: "sprint").find_each do |preset|
      next unless preset.settings["risings"] == 1

      preset.update_columns(settings: preset.settings.merge("risings" => 2))
    end
  end

  def down; end
end
