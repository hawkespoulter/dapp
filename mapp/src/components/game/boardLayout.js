// Where each park sits inside its 1080x1920 map overlays. `crop` is the part
// of the frame the board shows; `centers` are where each area's markers go,
// in image pixels.
import IMAGES from "~/images/Images";
import { toCamelCase } from "~/constants.js";

export const IMAGE_SIZE = { width: 1080, height: 1920 };

export const BOARD_LAYOUT = {
  "Animal Kingdom": {
    // The savanna at the top of Africa's overlay is cropped off; the board
    // runs from the villages down to the Oasis.
    crop: { x: 0, y: 960, width: 1080, height: 800 },
    centers: {
      "Africa": [340, 1110],
      "Asia": [770, 1110],
      "Discovery Island": [545, 1300],
      "DinoLand U.S.A.": [760, 1460],
      "Pandora": [380, 1535],
    },
  },
  "Hollywood Studios": {
    // The empty ground above Tower of Terror and below Galaxy's Edge is
    // cropped off.
    crop: { x: 0, y: 500, width: 1080, height: 1240 },
    centers: {
      "Sunset Boulevard": [300, 700],
      "Toy Story Land": [165, 1180],
      "Animation Courtyard": [455, 1010],
      "Hollywood Boulevard": [540, 1320],
      "Echo Lake": [860, 1260],
      "Muppet Courtyard": [820, 1560],
      "Galaxy's Edge": [380, 1640],
    },
  },
  // Diagon Alley (left) and Hogsmeade (right), cut from the Universal
  // Studios and Islands of Adventure maps and joined by the Hogwarts Express.
  // Its area names clash with the tracker's overlays, so it brings its own.
  "Wizarding World": {
    crop: { x: 0, y: 560, width: 1080, height: 640 },
    logoPark: "Universal Studios",
    centers: {
      "Carkitt Market": [101, 850],
      "Diagon Alley": [329, 791],
      "Knockturn Alley": [335, 1061],
      "King's Cross": [525, 866],
      "Hagrid's Hut": [765, 707],
      "Hogsmeade Station": [974, 704],
      "Hogwarts Castle": [770, 985],
      "Hogsmeade Village": [970, 937],
    },
    images: {
      "Carkitt Market": IMAGES.wwCarkittMarket,
      "Diagon Alley": IMAGES.wwDiagonAlley,
      "Knockturn Alley": IMAGES.wwKnockturnAlley,
      "King's Cross": IMAGES.wwKingsCross,
      "Hagrid's Hut": IMAGES.wwHagridsHut,
      "Hogsmeade Station": IMAGES.wwHogsmeadeStation,
      "Hogwarts Castle": IMAGES.wwHogwartsCastle,
      "Hogsmeade Village": IMAGES.wwHogsmeadeVillage,
    },
  },
  "Magic Kingdom": {
    crop: { x: 20, y: 470, width: 1040, height: 740 },
    centers: {
      "Main Street, U.S.A.": [540, 1070],
      "Adventureland": [300, 960],
      "Frontierland": [175, 745],
      "Liberty Square": [430, 805],
      "Fantasyland": [615, 660],
      "Tomorrowland": [800, 900],
    },
  },
};

export const VILLAIN_COLORS = {
  maleficent: "#9333ea",
  scar: "#c2410c",
  voldemort: "#15803d",
  vader: "#be123c",
};

export const villainColor = (key) => VILLAIN_COLORS[key] || "#9333ea";

// An area's map overlay: the board's own image if it has one, otherwise the
// tracker's overlay for that land.
export const areaImage = (park, area) => BOARD_LAYOUT[park]?.images?.[area] || IMAGES[toCamelCase(area)];

// The white borders drawn over a board.
export const linesImage = (park) => IMAGES[`${toCamelCase(park)}Lines`];

// The park whose logos stand in for this board (end-of-game medal).
export const logoPark = (park) => BOARD_LAYOUT[park]?.logoPark || park;
