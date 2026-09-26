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
    list_times = File.directory?(lists) ? [File.mtime(lists), *Dir.glob(File.join(lists, "*.yml")).map { File.mtime(_1) }] : []
    newest = [File.mtime(dir), *files(dir).map { File.mtime(_1) }, *list_times].max
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
      list = YAML.safe_load(File.read(path)) || []
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

  def list_items
    path = lists_dir.join("#{list_from}.yml")
    File.exist?(path) ? Array(YAML.safe_load(File.read(path))).map(&:to_s) : []
  end

  # The random items a newly dealt card gets, or nil for a plain challenge.
  def deal_list(rng)
    list_items.sample(list_count, random: rng) if list_from
  end

  def as_json(*)
    { id:, title:, description:, reward:, park: }
  end

  private

  def list_exists
    return if list_from.blank? && list_count.nil?

    items = list_items
    if list_from.blank? || list_count.nil?
      errors.add(:list, "needs both from: (a file in lists/) and count:")
    elsif items.empty?
      errors.add(:list, "lists/#{list_from}.yml doesn't exist or is empty")
    elsif !list_count.is_a?(Integer) || !(1..items.size).cover?(list_count)
      errors.add(:list, "count must be from 1 to #{items.size} (the number of items in lists/#{list_from}.yml)")
    end
  end
end
