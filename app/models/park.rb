# The parks as the park game sees them. A few game parks span two of the
# tracker's parks (TRACKER_PARKS). A park is only playable once it has a
# board (config/game/parks.yml) and a villain, but it can have challenges
# before that.
module Park
  NAMES = [
    "Animal Kingdom",
    "Magic Kingdom",
    "Epcot",
    "Hollywood Studios",
    "Universal Orlando",
    "Disneyland Resort",
    "Sea World",
  ].freeze

  # Game parks made of more than one tracker park.
  TRACKER_PARKS = {
    "Universal Orlando" => ["Universal Studios", "Islands Of Adventure"],
    "Disneyland Resort" => ["Disneyland", "California Adventure"],
  }.freeze

  def self.names
    NAMES
  end

  def self.tracker_parks(park)
    TRACKER_PARKS.fetch(park, [park])
  end
end
