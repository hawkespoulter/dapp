# A bug noted from the navbar's bug button, with the page it was noted on.
class BugReport < ApplicationRecord
  validates :note, presence: true

  # Open bugs first (newest at the top), then fixed ones, most recently fixed first.
  scope :listed, -> { order(Arel.sql("fixed_at IS NOT NULL"), fixed_at: :desc, created_at: :desc) }

  def as_json(*)
    { id:, note:, page:, fixed: fixed_at.present?, created_at:, fixed_at: }
  end
end
