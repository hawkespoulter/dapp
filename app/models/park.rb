# The parks as the park game sees them, and their areas. Area names match
# the tracker's data. A few game parks span two of the tracker's parks
# (TRACKER_PARKS). A park is only playable once it has a board
# (config/game/parks.yml) and a villain, but it can have challenges before
# that.
module Park
  AREAS = {
    "Animal Kingdom" => ["Discovery Island", "Pandora", "Africa", "Asia", "DinoLand U.S.A."],
    "Magic Kingdom" => ["Main Street, U.S.A.", "Adventureland", "Frontierland", "Liberty Square", "Fantasyland", "Tomorrowland"],
    "Epcot" => ["World Celebration", "World Discovery", "World Nature", "World Showcase"],
    "Hollywood Studios" => ["Hollywood Boulevard", "Muppet Courtyard", "Echo Lake", "Toy Story Land", "Galaxy's Edge", "Animation Courtyard", "Sunset Boulevard"],
    "Universal Orlando" => [
      # Universal Studios
      "Minion Land", "New York", "Production Central", "San Francisco", "Diagon Alley", "World Expo", "Woody Woodpecker's KidZone",
      # Islands of Adventure
      "Superhero Island", "Toon Lagoon", "Hogsmede", "Jurassic Park", "Seuss Landing", "Lost Continent",
    ],
    "Disneyland Resort" => [],
    "Sea World" => [],
  }.freeze

  # Game parks made of more than one tracker park.
  TRACKER_PARKS = {
    "Universal Orlando" => ["Universal Studios", "Islands Of Adventure"],
    "Disneyland Resort" => ["Disneyland", "California Adventure"],
  }.freeze

  def self.names
    AREAS.keys
  end

  def self.areas(park)
    AREAS.fetch(park)
  end

  def self.tracker_parks(park)
    TRACKER_PARKS.fetch(park, [park])
  end
end
