# The parks the tracker knows and their areas, named as in the tracker's
# data. A park is only playable in the park game once it has a board
# (config/game/parks.yml) and a villain, but it can have challenges before
# that.
module Park
  AREAS = {
    "Animal Kingdom" => ["Discovery Island", "Pandora", "Africa", "Asia", "DinoLand U.S.A."],
    "Magic Kingdom" => ["Main Street, U.S.A.", "Adventureland", "Frontierland", "Liberty Square", "Fantasyland", "Tomorrowland"],
    "Epcot" => ["World Celebration", "World Discovery", "World Nature", "World Showcase"],
    "Hollywood Studios" => ["Hollywood Boulevard", "Muppet Courtyard", "Echo Lake", "Toy Story Land", "Galaxy's Edge", "Animation Courtyard", "Sunset Boulevard"],
    "Universal Studios" => ["Minion Land", "New York", "Production Central", "San Francisco", "Diagon Alley", "World Expo", "Woody Woodpecker's KidZone"],
    "Islands Of Adventure" => ["Superhero Island", "Toon Lagoon", "Hogsmede", "Jurassic Park", "Seuss Landing", "Lost Continent"],
    "Disneyland" => [],
    "California Adventure" => [],
    "Sea World" => [],
  }.freeze

  def self.names
    AREAS.keys
  end

  def self.areas(park)
    AREAS.fetch(park)
  end
end
