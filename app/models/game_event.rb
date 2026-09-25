class GameEvent < ApplicationRecord
  belongs_to :game
  belongs_to :player, optional: true

  def as_json(*)
    { id:, kind:, message:, data:, player: player&.name, occurred_at: }
  end
end
