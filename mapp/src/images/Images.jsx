const IMAGES = {

  // Logos

  seaWorldColor: new URL("./logos/sea-world-color.png", import.meta.url).href,
  seaWorldGrayscale: new URL("./logos/sea-world-grayscale.png", import.meta.url).href,

  disneylandColor: new URL("./logos/disneyland-color.png", import.meta.url).href,
  disneylandGrayscale: new URL("./logos/disneyland-grayscale.png", import.meta.url).href,

  californiaAdventureColor: new URL("./logos/california-adventure-color.png", import.meta.url).href,
  californiaAdventureGrayscale: new URL("./logos/california-adventure-grayscale.png", import.meta.url).href,

  animalKingdomColor: new URL("./logos/animal-kingdom-color.png", import.meta.url).href,
  animalKingdomGrayscale: new URL("./logos/animal-kingdom-grayscale.png", import.meta.url).href,
  animalKingdomBronze: new URL("./logos/animal-kingdom-bronze.png", import.meta.url).href,
  animalKingdomGold: new URL("./logos/animal-kingdom-gold.png", import.meta.url).href,

  epcotColor: new URL("./logos/epcot-color.png", import.meta.url).href,
  epcotGrayscale: new URL("./logos/epcot-grayscale.png", import.meta.url).href,
  epcotBronze: new URL("./logos/epcot-bronze.png", import.meta.url).href,
  epcotGold: new URL("./logos/epcot-gold.png", import.meta.url).href,

  hollywoodStudiosColor: new URL("./logos/hollywood-studios-color.png", import.meta.url).href,
  hollywoodStudiosGrayscale: new URL("./logos/hollywood-studios-grayscale.png", import.meta.url).href,
  hollywoodStudiosBronze: new URL("./logos/hollywood-studios-bronze.png", import.meta.url).href,
  hollywoodStudiosGold: new URL("./logos/hollywood-studios-gold.png", import.meta.url).href,

  magicKingdomColor: new URL("./logos/magic-kingdom-color.png", import.meta.url).href,
  magicKingdomGrayscale: new URL("./logos/magic-kingdom-grayscale.png", import.meta.url).href,
  magicKingdomBronze: new URL("./logos/magic-kingdom-bronze.png", import.meta.url).href,
  magicKingdomGold: new URL("./logos/magic-kingdom-gold.png", import.meta.url).href,

  islandsOfAdventureColor: new URL("./logos/islands-of-adventure-color.png", import.meta.url).href,
  islandsOfAdventureGrayscale: new URL("./logos/islands-of-adventure-grayscale.png", import.meta.url).href,
  islandsOfAdventureBronze: new URL("./logos/islands-of-adventure-bronze.png", import.meta.url).href,
  islandsOfAdventureGold: new URL("./logos/islands-of-adventure-gold.png", import.meta.url).href,

  universalStudiosColor: new URL("./logos/universal-studios-color.png", import.meta.url).href,
  universalStudiosGrayscale: new URL("./logos/universal-studios-grayscale.png", import.meta.url).href,
  universalStudiosBronze: new URL("./logos/universal-studios-bronze.png", import.meta.url).href,
  universalStudiosGold: new URL("./logos/universal-studios-gold.png", import.meta.url).href,
  
  // Maps

  mapBackground: new URL("./maps/map-background.png", import.meta.url).href,

  // Animal Kingdom

  animalKingdomMap: new URL("./maps/animalKingdom/ak-map.png", import.meta.url).href,
  animalKingdomLines: new URL("./maps/animalKingdom/ak-lines.png", import.meta.url).href,
  africa: new URL("./maps/animalKingdom/africa.png", import.meta.url).href,
  asia: new URL("./maps/animalKingdom/asia.png", import.meta.url).href,
  dinoLandUSA: new URL("./maps/animalKingdom/dinoland.png", import.meta.url).href,
  pandora: new URL("./maps/animalKingdom/pandora.png", import.meta.url).href,
  discoveryIsland: new URL("./maps/animalKingdom/dsc-island.png", import.meta.url).href,

  epcotMap: new URL("./maps/epcot/epcot-map.png", import.meta.url).href,
  epcotLines: new URL("./maps/epcot/epcot-lines.png", import.meta.url).href,
  worldShowcase: new URL("./maps/epcot/world-showcase.png", import.meta.url).href,
  worldCelebration: new URL("./maps/epcot/world-celebration.png", import.meta.url).href,
  worldDiscovery: new URL("./maps/epcot/world-discovery.png", import.meta.url).href,
  worldNature: new URL("./maps/epcot/world-nature.png", import.meta.url).href,

  hollywoodStudiosMap: new URL("./maps/hollywoodStudios/hs-map.png", import.meta.url).href,
  hollywoodStudiosLines: new URL("./maps/hollywoodStudios/hs-lines.png", import.meta.url).href,
  animationCourtyard: new URL("./maps/hollywoodStudios/animation-courtyard.png", import.meta.url).href,
  echoLake: new URL("./maps/hollywoodStudios/echo-lake.png", import.meta.url).href,
  galaxysEdge: new URL("./maps/hollywoodStudios/galaxys-edge.png", import.meta.url).href,
  hollywoodBoulevard: new URL("./maps/hollywoodStudios/hollywood-boulevard.png", import.meta.url).href,
  muppetCourtyard: new URL("./maps/hollywoodStudios/muppets.png", import.meta.url).href,
  sunsetBoulevard: new URL("./maps/hollywoodStudios/sunset-blvd.png", import.meta.url).href,
  toyStoryLand: new URL("./maps/hollywoodStudios/toystory-land.png", import.meta.url).href,

  magicKingdomMap: new URL("./maps/magicKingdom/magic-kingdom-map.png", import.meta.url).href,
  magicKingdomLines: new URL("./maps/magicKingdom/magic-kingdom-lines.png", import.meta.url).href,
  adventureland: new URL("./maps/magicKingdom/adventureland.png", import.meta.url).href,
  fantasyland: new URL("./maps/magicKingdom/fantasyland.png", import.meta.url).href,
  frontierland: new URL("./maps/magicKingdom/frontierland.png", import.meta.url).href,
  libertySquare: new URL("./maps/magicKingdom/libertySqare.png", import.meta.url).href,
  mainStreetUSA: new URL("./maps/magicKingdom/mainstreet.png", import.meta.url).href,
  tomorrowland: new URL("./maps/magicKingdom/tomorrowland.png", import.meta.url).href,

  islandsOfAdventureMap: new URL("./maps/islandsOfAdventure/islands-of-adventure-map.png", import.meta.url).href,
  islandsOfAdventureLines: new URL("./maps/islandsOfAdventure/islands-of-adventure-line.png", import.meta.url).href,
  hogsmede: new URL("./maps/islandsOfAdventure/hogsmede.png", import.meta.url).href,
  jurassicPark: new URL("./maps/islandsOfAdventure/jurassic-park.png", import.meta.url).href,
  lostContinent: new URL("./maps/islandsOfAdventure/lost-continent.png", import.meta.url).href,
  seussLanding: new URL("./maps/islandsOfAdventure/seuss-landing.png", import.meta.url).href,
  superheroIsland: new URL("./maps/islandsOfAdventure/superhero-island.png", import.meta.url).href,
  toonLagoon: new URL("./maps/islandsOfAdventure/toon-lagoon.png", import.meta.url).href,

  wizardingWorldLines: new URL("./maps/wizardingWorld/wizarding-world-lines.png", import.meta.url).href,
  wwCarkittMarket: new URL("./maps/wizardingWorld/carkitt-market.png", import.meta.url).href,
  wwDiagonAlley: new URL("./maps/wizardingWorld/diagon-alley.png", import.meta.url).href,
  wwKnockturnAlley: new URL("./maps/wizardingWorld/knockturn-alley.png", import.meta.url).href,
  wwKingsCross: new URL("./maps/wizardingWorld/kings-cross.png", import.meta.url).href,
  wwHagridsHut: new URL("./maps/wizardingWorld/hagrids-hut.png", import.meta.url).href,
  wwHogsmeadeStation: new URL("./maps/wizardingWorld/hogsmeade-station.png", import.meta.url).href,
  wwHogwartsCastle: new URL("./maps/wizardingWorld/hogwarts-castle.png", import.meta.url).href,
  wwHogsmeadeVillage: new URL("./maps/wizardingWorld/hogsmeade-village.png", import.meta.url).href,
  universalStudiosMap: new URL("./maps/universalStudios/universal-studios-map.png", import.meta.url).href,
  universalStudiosLines: new URL("./maps/universalStudios/universal-studios-lines.png", import.meta.url).href,
  diagonAlley: new URL("./maps/universalStudios/diagon-alley.png", import.meta.url).href,
  minionLand: new URL("./maps/universalStudios/minion.png", import.meta.url).href,
  newYork: new URL("./maps/universalStudios/new-york.png", import.meta.url).href,
  productionCentral: new URL("./maps/universalStudios/production-central.png", import.meta.url).href,
  sanFrancisco: new URL("./maps/universalStudios/san-francisco.png", import.meta.url).href,
  worldExpo: new URL("./maps/universalStudios/world-expo.png", import.meta.url).href,
  woodyWoodpeckersKidZone: new URL("./maps/universalStudios/woody-woodpecker.png", import.meta.url).href,
};

export default IMAGES;
