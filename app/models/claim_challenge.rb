# A claim challenge: what the team does in an unclaimed area (go there and
# touch something) to claim it. Loaded once from config/game/claims/<park>.yml
# and edited in the app after that.
class ClaimChallenge < ApplicationRecord
  validates :park, :area, :title, presence: true
  validate :area_on_board

  scope :ordered, -> { order(:position, :id) }

  # The area's claim cards, or a stand-in when it has none.
  def self.cards(park, area)
    where(park:, area:).ordered.to_a.presence ||
      [new(park:, area:, title: "Stake your claim", description: "Go to #{area} together and take a group photo there.")]
  end

  def as_json(*)
    { id:, park:, area:, title:, description: }
  end

  private

  def area_on_board
    return if park.blank? || area.blank?
    return errors.add(:park, "doesn't have a board yet") unless ParkBoard.config.key?(park)

    errors.add(:area, "isn't an area of #{park}") unless ParkBoard.for(park).areas.include?(area)
  end
end
