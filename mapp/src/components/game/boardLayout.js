// Where each park sits inside its 1080x1920 map overlays. `crop` is the part
// of the frame the board shows; `centers` are where each area's markers go,
// in image pixels.
export const IMAGE_SIZE = { width: 1080, height: 1920 };

export const BOARD_LAYOUT = {
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
};

export const villainColor = (key) => VILLAIN_COLORS[key] || "#9333ea";
