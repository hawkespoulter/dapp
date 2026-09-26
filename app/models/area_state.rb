# Who holds an area and how strongly. Strength has no cap on either side.
class AreaState < ApplicationRecord
  OWNERS = %w[neutral players villain].freeze
  OUTBREAK_AT = 3 # drawing a villain area this strong is an outbreak

  belongs_to :game

  validates :owner, inclusion: { in: OWNERS }
  validates :strength, numericality: { greater_than_or_equal_to: 0 }

  def players? = owner == "players"
  def villain? = owner == "villain"
  def neutral? = owner == "neutral"

  def as_json(*)
    { area:, owner:, strength: }
  end
end
