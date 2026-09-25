# One villain per park. Add a class under app/services/villains/ and list it here.
module Villains
  def self.all
    [Villains::Maleficent]
  end

  def self.for_park(park)
    all.find { _1.park == park }
  end

  def self.find(key)
    all.find { _1.key == key } || raise(ArgumentError, "Unknown villain #{key}")
  end
end
