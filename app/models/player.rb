class Player < ApplicationRecord
  belongs_to :game
  has_many :game_events, dependent: :nullify

  validates :name, presence: true, length: { maximum: 30 }
  validates :auth_token, presence: true, uniqueness: true

  before_validation { self.auth_token ||= SecureRandom.urlsafe_base64(24) }

  def hand_challenges
    by_id = Challenge.where(id: hand).index_by(&:id)
    hand.filter_map { |id| by_id[id] }
  end

  def as_json(*)
    { id:, name:, host:, current_area:, coins: }
  end
end
