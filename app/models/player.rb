class Player < ApplicationRecord
  belongs_to :game
  has_many :game_events, dependent: :nullify

  validates :name, presence: true, length: { maximum: 30 }
  validates :auth_token, presence: true, uniqueness: true

  before_validation { self.auth_token ||= SecureRandom.urlsafe_base64(24) }

  # Sets the hand to these challenge ids. Cards already held keep the list
  # items they were dealt; new cards from list challenges get fresh ones.
  def deal(ids, rng)
    challenges = Challenge.where(id: ids).index_by(&:id)
    self.card_lists = ids.to_h { |id| [id.to_s, card_lists[id.to_s] || challenges[id]&.deal_list(rng, game.park)] }.compact
    self.hand = ids
  end

  # The hand as shown on the player's phone, with each card's list items.
  def hand_cards
    by_id = Challenge.where(id: hand).index_by(&:id)
    fill_missing_lists(by_id)
    hand.filter_map { |id| by_id[id]&.as_json&.merge(list: card_lists[id.to_s]) }
  end

  def as_json(*)
    { id:, name:, host:, coins: }
  end

  private

  # A card dealt before its challenge had a list (or before the list had
  # items for this park) gets its items now, and keeps them.
  def fill_missing_lists(challenges)
    missing = hand.select { |id| challenges[id]&.list_from.present? && card_lists[id.to_s].blank? }
    return if missing.empty?

    fresh = missing.to_h { |id| [id.to_s, challenges[id].deal_list(Random.new, game.park)] }.compact_blank
    update_columns(card_lists: card_lists.merge(fresh)) if fresh.any? && persisted?
  end
end
