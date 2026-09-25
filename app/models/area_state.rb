class AreaState < ApplicationRecord
  OWNERS = %w[neutral players villain].freeze
  MAX_INFLUENCE = 3 # villain influence that takes an area; also max villain strength
  CLAIM_COST = 3    # player influence that claims an unclaimed area
  LOCK_COST = 2     # player influence that locks one of their areas

  belongs_to :game

  validates :owner, inclusion: { in: OWNERS }

  def players? = owner == "players"
  def villain? = owner == "villain"
  def neutral? = owner == "neutral"

  def as_json(*)
    { area:, owner:, influence:, claim:, locked: }
  end
end
