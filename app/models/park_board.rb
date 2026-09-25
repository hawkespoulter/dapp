# Area adjacency graph and starting split for one park, loaded from
# config/game/parks.yml.
class ParkBoard
  def self.config
    @config ||= YAML.load_file(Rails.root.join("config/game/parks.yml"))
  end

  def self.for(park)
    raise ArgumentError, "No board for #{park}" unless config.key?(park)

    new(park, config[park]["adjacency"], config[park].fetch("start", {}))
  end

  attr_reader :park

  def initialize(park, adjacency, start = {})
    @park = park
    @start = start
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

  # "players", "villain" or "neutral" for an area at the start of a game.
  def starting_owner(area)
    %w[players villain].find { @start.fetch(_1, []).include?(area) } || "neutral"
  end
end
