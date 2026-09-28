# A game length preset (Sprint, Full Day, Multi-day) and its balance
# settings, tuned from the Game settings page. Defaults come from
# config/game/presets.yml. Each game copies its preset's settings when it's
# created, so changing a preset never affects a game already being played.
class GamePreset < ApplicationRecord
  DEFAULTS = YAML.load_file(Rails.root.join("config/game/presets.yml")).freeze

  # Every tunable setting: what it means and the values it may take.
  FIELDS = {
    "hours" => { label: "Game length (hours)", range: 1..72 },
    "days" => { label: "Days", range: 1..14 },
    "day_start" => { label: "Each day starts", time: true },
    "day_end" => { label: "Each day ends", time: true },
    "tick_minutes" => { label: "Villain moves every (minutes)", range: 1..240 },
    "starting_strength" => { label: "Starting strength per side", range: 1..100 },
    "influence_price" => { label: "Coins per influence", range: 1..20 },
    "hand_size" => { label: "Challenge cards in hand", range: 1..8 },
    "risings" => { label: "Villain Rising cards in the deck (each adds a card per turn)", range: 0..12 },
    "outbreak_at" => { label: "Area spills over at", range: 1..50 },
    "youngling_max" => { label: "Youngling (Darth Vader) takes areas with influence at or below", range: 0..20 },
    "hard_mode" => { label: "Hard mode: the villain also moves when you fail a challenge", boolean: true },
    "price_forecast" => { label: "Forecast price (coins)", range: 0..50 },
    "price_stall" => { label: "Stall price (coins)", range: 0..50 },
    "price_shield" => { label: "Shield price (coins)", range: 0..50 },
    "price_redraw" => { label: "Redraw price (coins)", range: 0..50 },
    "price_double_down" => { label: "Double Down price (coins)", range: 0..50 },
    "price_safety_net" => { label: "Safety Net price (coins)", range: 0..50 },
  }.freeze
  # Settings that can still change once a game is under way. The others set
  # the game up (the split, the villain deck, multi-day windows).
  LIVE_FIELDS = (FIELDS.keys - %w[days day_start day_end starting_strength risings]).freeze

  validates :key, presence: true, uniqueness: true
  validate :settings_in_range

  default_scope { order(:position) }

  def self.seed_defaults!
    DEFAULTS.each_with_index do |(key, settings), position|
      find_or_create_by!(key:) { _1.assign_attributes(position:, settings:) }
    end
  end

  # All presets, creating them from the defaults file the first time and
  # keeping them in step with it: settings the file has gained are added and
  # ones it dropped are removed, without touching values that were tuned.
  def self.seeded
    seed_defaults! unless exists?
    all.each do |preset|
      defaults = DEFAULTS.fetch(preset.key, {})
      synced = defaults.merge(preset.settings.slice(*defaults.keys))
      preset.update_columns(settings: synced) if synced != preset.settings
    end
    all
  end

  def self.for(key)
    seeded.find_by(key:) or raise ArgumentError, "Unknown game length #{key}"
  end

  def self.keys
    seeded.pluck(:key)
  end

  def reset!
    update!(settings: DEFAULTS.fetch(key))
  end

  # Edited values from a form, limited to `allowed` fields and turned into
  # integers / booleans where the field calls for it.
  def self.coerce(changes, allowed)
    changes.to_h.slice(*allowed).to_h do |field, value|
      spec = FIELDS[field] || {}
      value =
        if spec[:range] then value.to_s.strip.then { Integer(_1, exception: false) || _1 }
        elsif spec[:boolean] then ActiveModel::Type::Boolean.new.cast(value)
        else value.to_s.strip
        end
      [field, value]
    end
  end

  # What's wrong with a set of settings, as sentences.
  def self.problems(settings)
    problems = []
    problems << "Settings need a label" if settings["label"].blank?
    settings.each do |field, value|
      spec = FIELDS[field] or next
      if spec[:range] && !(value.is_a?(Integer) && spec[:range].cover?(value))
        problems << "#{spec[:label]} must be a whole number from #{spec[:range].min} to #{spec[:range].max}"
      elsif spec[:boolean] && ![true, false].include?(value)
        problems << "#{spec[:label]} must be on or off"
      elsif spec[:time] && !value.to_s.match?(/\A([01]\d|2[0-3]):[0-5]\d\z/)
        problems << "#{spec[:label]} must be a time like 09:00"
      end
    end
    if settings["day_start"] && settings["day_end"] && settings["day_start"] >= settings["day_end"]
      problems << "Each day has to end after it starts"
    end
    problems
  end

  # The form fields for these settings, in FIELDS order.
  def self.fields_for(keys)
    FIELDS.filter_map do |field, spec|
      next unless keys.include?(field)

      spec.except(:range).merge(key: field, min: spec[:range]&.min, max: spec[:range]&.max)
    end
  end

  # Takes edited values from the settings page, keeping only known fields
  # this preset already has.
  def update_settings!(changes)
    update!(settings: settings.merge(self.class.coerce(changes, settings.keys + ["label"])))
  end

  def as_json(*)
    { key:, label: settings["label"], settings:, defaults: DEFAULTS[key], fields: self.class.fields_for(settings.keys) }
  end

  private

  def settings_in_range
    self.class.problems(settings).each { errors.add(:base, _1) }
  end
end
