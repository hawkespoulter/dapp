# A real-life task players complete in the park to earn coins. Every
# challenge comes from the files in config/game/challenges/ (anywhere.yml,
# plus one file per park); the table is a copy of them that hands can point
# at. park/area nil means it can be done anywhere.
class Challenge < ApplicationRecord
  DIR = Rails.root.join("config/game/challenges")
  ANYWHERE = "anywhere".freeze
  FIELDS = %w[title description difficulty area].freeze

  class InvalidFile < StandardError; end

  validates :title, presence: true, uniqueness: true
  validates :difficulty, inclusion: { in: 1..3, message: "must be 1, 2 or 3" }
  validate :area_is_on_the_board

  scope :for_park, ->(park) { where(park: nil).or(where(park:)) }

  def anywhere? = area.nil?

  # Reloads the files if any changed (or were added or deleted) since the
  # last load. If they have a mistake, the last good deck stays in play and
  # the problem is returned (and shown on the Game settings page); otherwise
  # returns nil.
  def self.refresh(dir = DIR)
    newest = [File.mtime(dir), *files(dir).map { File.mtime(_1) }].max
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
    transaction do
      where.not(title: entries.map { _1["title"] }).delete_all
      problems = entries.filter_map do |attrs|
        challenge = find_or_initialize_by(title: attrs["title"])
        # Fields left out of a file are cleared, not kept from before.
        challenge.assign_attributes(%w[description difficulty park area].index_with { attrs[_1] })
        "#{attrs['file']}: #{attrs['title']}: #{challenge.errors.full_messages.to_sentence}" unless challenge.save
      end
      raise InvalidFile, "Challenge files have problems:\n#{problems.join("\n")}" if problems.any?

      all.touch_all
    end
  end

  def self.files(dir = DIR)
    Dir.glob(File.join(dir, "*.yml")).sort
  end

  # anywhere.yml, or a park's name in lowercase with underscores.
  def self.file_name_for(park)
    park.downcase.gsub(/[^a-z0-9]+/, "_").delete_suffix("_")
  end

  def self.parse(dir)
    parks = ParkBoard.config.keys.index_by { file_name_for(_1) }
    entries = files(dir).flat_map do |path|
      file = File.basename(path)
      name = File.basename(path, ".yml")
      park = name == ANYWHERE ? nil : parks.fetch(name) do
        raise InvalidFile, "#{file}: there's no park board called that. Use #{ANYWHERE}.yml or one of: #{parks.keys.map { "#{_1}.yml" }.join(', ')}"
      end

      # Read the file ourselves: YAML.load_file goes through Bootsnap's cache,
      # which can hand back the old contents after a quick re-save.
      list = YAML.safe_load(File.read(path)) || []
      raise InvalidFile, "#{file}: should be a list of challenges (each starting with \"- title:\")" unless list.is_a?(Array)

      list.map do |entry|
        unknown = entry.keys - FIELDS
        raise InvalidFile, "#{file}: #{entry['title']}: unknown field #{unknown.join(', ')}" if unknown.any?

        entry.merge("park" => park, "file" => file, "title" => entry["title"].to_s.strip)
      end
    end
    repeated = entries.map { _1["title"] }.tally.select { _2 > 1 }.keys
    raise InvalidFile, "Each title can only be used once: #{repeated.join(', ')}" if repeated.any?

    entries
  end

  def as_json(*)
    { id:, title:, description:, difficulty:, park:, area: }
  end

  private

  def area_is_on_the_board
    return if area.blank?

    if park.blank?
      errors.add(:area, "only works in a park's file, not anywhere.yml")
    elsif !ParkBoard.for(park).areas.include?(area)
      errors.add(:area, "#{area} isn't an area in #{park} (#{ParkBoard.for(park).areas.join(', ')})")
    end
  end
end
