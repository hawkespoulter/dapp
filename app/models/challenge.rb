# A real-life task players complete in the park to earn coins. Every
# challenge comes from config/game/challenges.yml; the table is a copy of
# that file that hands can point at. park/area nil means it can be done
# anywhere.
class Challenge < ApplicationRecord
  FILE = Rails.root.join("config/game/challenges.yml")
  CATEGORIES = %w[ride show food photo find social trivia].freeze
  FIELDS = %w[title description category difficulty area].freeze

  class InvalidFile < StandardError; end

  validates :title, presence: true, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES, message: "must be one of #{CATEGORIES.join(', ')}" }
  validates :difficulty, inclusion: { in: 1..3, message: "must be 1, 2 or 3" }
  validate :area_is_on_the_board

  scope :for_park, ->(park) { where(park: nil).or(where(park:)) }

  def anywhere? = area.nil?

  # Reloads the file if it has changed since the last load. If the file has
  # a mistake, the last good deck stays in play and the problem is returned
  # (and shown on the Game settings page); otherwise returns nil.
  def self.refresh(file = FILE)
    return if exists? && maximum(:updated_at) >= File.mtime(file)

    sync!(file)
    nil
  rescue InvalidFile, Psych::SyntaxError => e
    Rails.logger.error(e.message)
    e.message
  end

  # Makes the table match the file exactly: adds and updates challenges by
  # title and removes any the file no longer has. Raises InvalidFile naming
  # every bad entry, and changes nothing if there are any.
  def self.sync!(file = FILE)
    entries = parse(file)
    transaction do
      where.not(title: entries.map { _1["title"] }).delete_all
      problems = entries.filter_map do |attrs|
        challenge = find_or_initialize_by(title: attrs["title"])
        # Fields left out of the file are cleared, not kept from before.
        challenge.assign_attributes(%w[description category difficulty park area].index_with { attrs[_1] })
        "#{attrs['title']}: #{challenge.errors.full_messages.to_sentence}" unless challenge.save
      end
      raise InvalidFile, "challenges.yml has problems:\n#{problems.join("\n")}" if problems.any?

      all.touch_all
    end
  end

  # The file groups challenges under "anywhere" or a park's name.
  def self.parse(file)
    entries = YAML.load_file(file).flat_map do |group, list|
      park = group == "anywhere" ? nil : group
      Array(list).map do |entry|
        unknown = entry.keys - FIELDS
        raise InvalidFile, "#{entry['title'] || group}: unknown field #{unknown.join(', ')}" if unknown.any?

        entry.merge("park" => park, "title" => entry["title"].to_s.strip)
      end
    end
    repeated = entries.map { _1["title"] }.tally.select { _2 > 1 }.keys
    raise InvalidFile, "Each title can only be used once: #{repeated.join(', ')}" if repeated.any?

    entries
  end

  def as_json(*)
    { id:, title:, description:, category:, difficulty:, park:, area: }
  end

  private

  def area_is_on_the_board
    return if area.blank?

    if park.blank?
      errors.add(:area, "needs a park (put it under that park's name)")
    elsif ParkBoard.config.key?(park) && !ParkBoard.for(park).areas.include?(area)
      errors.add(:area, "#{area} isn't an area in #{park} (#{ParkBoard.for(park).areas.join(', ')})")
    end
  end
end
