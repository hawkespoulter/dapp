# Area adjacency graph for one park, loaded from config/game/parks.yml.
class ParkBoard
  def self.config
    @config ||= YAML.load_file(Rails.root.join("config/game/parks.yml"))
  end

  def self.for(park)
    raise ArgumentError, "No board for #{park}" unless config.key?(park)

    new(park, config[park])
  end

  attr_reader :park

  def initialize(park, adjacency)
    @park = park
    @neighbors = Hash.new { |h, k| h[k] = [] }
    adjacency.each do |area, list|
      list.each do |other|
        @neighbors[area] |= [other]
        @neighbors[other] |= [area]
      end
    end
  end

  def areas
    @neighbors.keys
  end

  def neighbors(area)
    @neighbors.fetch(area, [])
  end

  def adjacent?(a, b)
    neighbors(a).include?(b)
  end
end
