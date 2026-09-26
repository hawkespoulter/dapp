# A real-life task players complete in the park to earn coins. Every
# challenge comes from the files in config/game/challenges/ (anywhere.yml,
# plus one file per park); the table is a copy of them that hands can point
# at. A nil park means it can be done in any park.
class Challenge < ApplicationRecord
  DIR = Rails.root.join("config/game/challenges")
  LISTS_DIR = DIR.join("lists")
  ANYWHERE = "anywhere".freeze
  FIELDS = %w[title description reward list].freeze

  class InvalidFile < StandardError; end

  validates :title, presence: true, uniqueness: true
  validates :reward, inclusion: { in: 1..3, message: "must be 1, 2 or 3" }
  validate :list_exists

  scope :for_park, ->(park) { where(park: nil).or(where(park:)) }

  def anywhere? = park.nil?

  # Reloads the files if any changed (or were added or deleted) since the
  # last load. If they have a mistake, the last good deck stays in play and
  # the problem is returned (and shown on the Game settings page); otherwise
  # returns nil.
  def self.refresh(dir = DIR)
    lists = File.join(dir, "lists")
    list_paths = File.directory?(lists) ? [lists, *Dir.glob(File.join(lists, "**", "*"))] : []
    newest = [File.mtime(dir), *files(dir).map { File.mtime(_1) }, *list_paths.map { File.mtime(_1) }].max
    return if exists? && maximum(:updated_at) >= newest

    sync!(dir)
    nil
  rescue InvalidFile, Psych::SyntaxError => e
    Rails.logger.error(e.message)
    e.message
  end

  # Makes the table match the files exactly: adds and updates challenges by
  # title and removes any the files no longer have. Raises InvalidFile naming
  # every bad entry, and changes nothing if there are any.
  def self.sync!(dir = DIR)
    entries = parse(dir)
    lists_dir = Pathname(dir).join("lists")
    transaction do
      where.not(title: entries.map { _1["title"] }).delete_all
      problems = entries.filter_map do |attrs|
        challenge = find_or_initialize_by(title: attrs["title"])
        # Fields left out of a file are cleared, not kept from before.
        challenge.assign_attributes(%w[description reward park].index_with { attrs[_1] })
        list = attrs["list"].is_a?(Hash) ? attrs["list"] : {}
        challenge.assign_attributes(list_from: list["from"], list_count: list["count"])
        challenge.lists_dir = lists_dir
        "#{attrs['file']}: #{attrs['title']}: #{challenge.errors.full_messages.to_sentence}" unless challenge.save
      end
      raise InvalidFile, "Challenge files have problems:\n#{problems.join("\n")}" if problems.any?

      all.touch_all
    end
  end

  def self.files(dir = DIR)
    Dir.glob(File.join(dir, "*.yml")).sort
  end

  # anywhere.yml, or a park's name in lowercase with underscores
  # (magic_kingdom.yml, sea_world.yml).
  def self.file_name_for(park)
    park.downcase.gsub(/[^a-z0-9]+/, "_").delete_suffix("_")
  end

  def self.parse(dir)
    parks = Park.names.index_by { file_name_for(_1) }
    entries = files(dir).flat_map do |path|
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
        raise InvalidFile, "#{file}: line #{e.line} can't be read (#{e.problem}). "                            "If a description has a colon in it, put the description in quotes."
      end
      raise InvalidFile, "#{file}: should be a list of challenges (each starting with \"- title:\")" unless list.is_a?(Array)

      list.map do |entry|
        unknown = entry.keys - FIELDS
        raise InvalidFile, "#{file}: #{entry['title']}: unknown field #{unknown.join(', ')}" if unknown.any?
        if entry.key?("list") && !entry["list"].is_a?(Hash)
          raise InvalidFile, "#{file}: #{entry['title']}: list should look like {from: tree_of_life_animals, count: 10}"
        end

        entry.merge("park" => park, "file" => file, "title" => entry["title"].to_s.strip)
      end
    end
    repeated = entries.map { _1["title"] }.tally.select { _2 > 1 }.keys
    raise InvalidFile, "Each title can only be used once: #{repeated.join(', ')}" if repeated.any?

    entries
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

  # The items this challenge deals from in a park. An item is text, or a
  # photo: {image:, credit:, answer:}.
  def list_items(in_park = park)
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

  private

  def list_exists
    return if list_from.blank? && list_count.nil?
    return errors.add(:list, "needs both from: (a file or folder in lists/) and count:") if list_from.blank? || list_count.nil?
    return errors.add(:list, "count must be a whole number") unless list_count.is_a?(Integer) && list_count.positive?

    if per_park_list?
      check_park_lists
    else
      check_list("lists/#{list_from}.yml", list_items)
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
    bad = items.index { _1.is_a?(Hash) && _1["image"].blank? }
    errors.add(:list, "#{label} item #{bad + 1} is a photo without an image: link") if bad
  end
end
