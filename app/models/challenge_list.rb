# Items a challenge card deals from (Star Tours characters, Tree of Life
# animals...): one text item each. Photo lists like GeoGuessr stay as files
# in config/game/challenges/lists/<name>/.
class ChallengeList < ApplicationRecord
  validates :name, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9_]+\z/, message: "can only use lowercase letters, numbers and _" }
  validate :items_are_text

  before_validation { self.items = Array(items).map { _1.to_s.strip }.reject(&:blank?) }

  def used_by
    Challenge.where(list_from: name).pluck(:title)
  end

  def as_json(*)
    { id:, name:, items:, used_by: }
  end

  private

  def items_are_text
    errors.add(:items, "need at least one item") if items.empty?
  end
end
