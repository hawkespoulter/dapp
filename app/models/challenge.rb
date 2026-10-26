# A real-life task players complete in the park to earn coins. Challenges are
# edited in the app; the files in config/game/challenges/ (anywhere.yml plus
# one per park) add new challenges to it (see GameContent). A nil park
# means it can be done in any park.
class Challenge < ApplicationRecord
  DIR = Rails.root.join("config/game/challenges")
  LISTS_DIR = DIR.join("lists")
  ANYWHERE = "anywhere".freeze
  FIELDS = %w[title description reward list].freeze

  class InvalidFile < StandardError; end

  validates :title, presence: true, uniqueness: true
  REWARDS = 1..10

  validates :reward, inclusion: { in: REWARDS, message: "must be a whole number from #{REWARDS.min} to #{REWARDS.max}" }
  validate :list_exists

  scope :for_park, ->(park) { where(park: nil).or(where(park:)) }

  def anywhere? = park.nil?

  def self.files(dir = DIR)
    Dir.glob(File.join(dir, "*.yml")).sort
  end

  # anywhere.yml, or a park's name in lowercase with underscores
  # (magic_kingdom.yml, sea_world.yml).
  def self.file_name_for(park)
    park.downcase.gsub(/[^a-z0-9]+/, "_").delete_suffix("_")
  end

  # A challenge from a file entry (see parse_file).
  def self.from_file_entry(attrs)
    list = attrs["list"].is_a?(Hash) ? attrs["list"] : {}
    new(**%w[title description reward park].to_h { [_1.to_sym, attrs[_1]] }, list_from: list["from"], list_count: list["count"])
  end

  def self.parse(dir)
    entries = files(dir).flat_map { parse_file(_1) }
    repeated = entries.map { _1["title"] }.tally.select { _2 > 1 }.keys
    raise InvalidFile, "Each title can only be used once: #{repeated.join(', ')}" if repeated.any?

    entries
  end

  def self.parse_file(path)
    parks = Park.names.index_by { file_name_for(_1) }
    file = File.basename(path)
    name = File.basename(path, ".yml")
    park = name == ANYWHERE ? nil : parks.fetch(name) do
      raise InvalidFile, "#{file}: there's no park called that. Use #{ANYWHERE}.yml or one of: #{parks.keys.map { "#{_1}.yml" }.join(', ')}"
    end

    # Read the file ourselves: YAML.load_file goes through Bootsnap's cache,
    # which can hand back the old contents after a quick re-save.
    list = begin
      YAML.safe_load(File.read(path)) || []
    rescue Psych::SyntaxError => e
      raise InvalidFile, "#{file}: line #{e.line} can't be read (#{e.problem}). "                               "If a description has a colon in it, put the description in quotes."
    end
    raise InvalidFile, "#{file}: should be a list of challenges (each starting with \"- title:\")" unless list.is_a?(Array)

    list.each_with_index.map do |entry, i|
      raise InvalidFile, "#{file}: challenge #{i + 1} is empty. Give it a title or delete the stray \"-\"." unless entry.is_a?(Hash)

      unknown = entry.keys - FIELDS
      raise InvalidFile, "#{file}: #{entry['title']}: unknown field #{unknown.join(', ')}" if unknown.any?
      if entry.key?("list") && !entry["list"].is_a?(Hash)
        raise InvalidFile, "#{file}: #{entry['title']}: list should look like {from: tree_of_life_animals, count: 10}"
      end

      entry.merge("park" => park, "file" => file, "title" => entry["title"].to_s.strip)
    end
  end

  attr_writer :lists_dir

  def lists_dir
    @lists_dir || LISTS_DIR
  end

  # A list is either lists/<from>.yml, used in every park, or a folder
  # lists/<from>/ with a file per park (lists/geoguessr/animal_kingdom.yml).
  def per_park_list?
    list_from.present? && File.directory?(lists_dir.join(list_from))
  end

  # The items this challenge deals from in a park: an edited list from the
  # database, or a file (photos: {image:, credit:, answer:}; text with a
  # hidden answer: {text:, answer:}).
  def list_items(in_park = park)
    stored = ChallengeList.find_by(name: list_from)&.items
    return stored if stored

    path =
      if per_park_list?
        return [] if in_park.nil?

        lists_dir.join(list_from, "#{self.class.file_name_for(in_park)}.yml")
      else
        lists_dir.join("#{list_from}.yml")
      end
    File.exist?(path) ? self.class.read_list(path) : []
  end

  def self.read_list(path)
    Array(YAML.safe_load(File.read(path))).map { _1.is_a?(Hash) ? _1.transform_keys(&:to_s) : _1.to_s }
  end

  # Whether a card can be dealt in this park: a list challenge needs enough
  # items for that park.
  def dealable_in?(in_park)
    list_from.blank? || list_items(in_park).size >= list_count.to_i
  end

  # The random items a newly dealt card gets, or nil for a plain challenge.
  def deal_list(rng, in_park = park)
    list_items(in_park).sample(list_count, random: rng) if list_from
  end

  def as_json(*)
    { id:, title:, description:, reward:, park: }
  end

  # What the challenge editor shows and saves.
  def as_editor_json
    as_json.merge(list_from:, list_count:)
  end

  private

  def list_exists
    return if list_from.blank? && list_count.nil?
    return errors.add(:list, "needs both from: (a file or folder in lists/) and count:") if list_from.blank? || list_count.nil?
    return errors.add(:list, "count must be a whole number") unless list_count.is_a?(Integer) && list_count.positive?

    if per_park_list?
      check_park_lists
    else
      check_list("list #{list_from}", list_items)
    end
  end

  # Every file in a per-park list folder must be named for a park and hold
  # enough good items. Parks without a file just don't get this challenge.
  def check_park_lists
    parks = Park.names.index_by { self.class.file_name_for(_1) }
    files = Dir.glob(lists_dir.join(list_from, "*.yml").to_s)
    errors.add(:list, "lists/#{list_from}/ has no park files yet") if files.empty?
    files.each do |path|
      name = File.basename(path, ".yml")
      label = "lists/#{list_from}/#{name}.yml"
      next errors.add(:list, "#{label} isn't named for a park (use one of: #{parks.keys.join(', ')})") unless parks.key?(name)

      check_list(label, self.class.read_list(path))
    end
  end

  def check_list(label, items)
    return errors.add(:list, "#{label} doesn't exist or is empty") if items.empty?

    if items.size < list_count
      errors.add(:list, "count is #{list_count} but #{label} only has #{items.size} item#{'s' unless items.size == 1}")
    end
    bad = items.index { _1.is_a?(Hash) && _1["image"].blank? && _1["text"].blank? }
    errors.add(:list, "#{label} item #{bad + 1} needs an image: link or text:") if bad
  end
end
