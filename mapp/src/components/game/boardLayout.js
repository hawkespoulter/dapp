// Where each park sits inside its 1080x1920 map overlays. `crop` is the part
// of the frame the board shows; `centers` are where each area's markers go,
// in image pixels.
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
  vader: "#be123c",
};

export const villainColor = (key) => VILLAIN_COLORS[key] || "#9333ea";
