class AreaState < ApplicationRecord
  OWNERS = %w[neutral players villain].freeze
  MAX_INFLUENCE = 3

  belongs_to :game

  validates :owner, inclusion: { in: OWNERS }

  def players? = owner == "players"
  def villain? = owner == "villain"
  def neutral? = owner == "neutral"

  def as_json(*)
    { area:, owner:, influence:, locked: }
  end
end
