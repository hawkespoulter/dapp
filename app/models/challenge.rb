# A real-life task players complete in the park to claim an area.
# park/area nil means it can be done anywhere.
class Challenge < ApplicationRecord
  CATEGORIES = %w[ride show food photo find social trivia].freeze
  SOURCES = {
    "Attraction" => { category: "ride", difficulty: 1, verb: "Ride" },
    "Show" => { category: "show", difficulty: 2, verb: "Watch" },
    "Restaurant" => { category: "food", difficulty: 1, verb: "Eat at" },
  }.freeze

  validates :title, :category, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :difficulty, inclusion: { in: 1..3 }

  scope :for_park, ->(park) { where(park: nil).or(where(park:)) }

  def anywhere? = area.nil?

  # Rebuilds the challenge deck from config/game/challenges.yml plus one
  # challenge per attraction, show and restaurant in the tracker. Idempotent.
  def self.sync!
    transaction do
      authored = YAML.load_file(Rails.root.join("config/game/challenges.yml"))
      where(source_type: nil).where.not(title: authored.map { _1["title"] }).delete_all
      authored.each do |attrs|
        find_or_initialize_by(title: attrs["title"], source_type: nil).update!(attrs.slice(*%w[description category difficulty park area]))
      end

      SOURCES.each do |klass, opts|
        records = klass.constantize.all
        where(source_type: klass).where.not(source_id: records.map(&:id)).delete_all
        records.each do |record|
          find_or_initialize_by(source_type: klass, source_id: record.id).update!(
            title: "#{opts[:verb]} #{record.name}",
            category: opts[:category],
            difficulty: opts[:difficulty],
            park: record.park,
            area: record.area,
          )
        end
      end
    end
  end

  def as_json(*)
    { id:, title:, description:, category:, difficulty:, park:, area: }
  end
end
