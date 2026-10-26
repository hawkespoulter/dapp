# A file (or part of one) under config/game that has already been loaded into
# the database, so it isn't loaded again over edits made in the app.
class ContentSeed < ApplicationRecord
  validates :key, presence: true, uniqueness: true
end
