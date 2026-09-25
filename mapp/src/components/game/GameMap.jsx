import { useEffect, useRef } from "react";
import PropTypes from "prop-types";
import LockIcon from "@mui/icons-material/Lock";
import IMAGES from "~/images/Images";
import { toCamelCase } from "~/constants.js";
import { BOARD_LAYOUT, IMAGE_SIZE, villainColor } from "./boardLayout";

const pct = (value, total) => `${(value / total) * 100}%`;

const OWNER_FILTERS = {
  players: "none",
  neutral: "grayscale(0.85) brightness(0.9)",
  villain: "grayscale(1) brightness(0.45)",
};

// Reads each area image's pixels once so a tap can be matched to the area
// whose overlay is opaque at that point.
function useAreaHitTest(areaNames) {
  const masks = useRef({});

  useEffect(() => {
    areaNames.forEach((name) => {
      if (masks.current[name]) return;
      const img = new Image();
      img.src = IMAGES[toCamelCase(name)];
      img.onload = () => {
        const canvas = document.createElement("canvas");
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext("2d", { willReadFrequently: true });
        ctx.drawImage(img, 0, 0);
        masks.current[name] = ctx.getImageData(0, 0, img.width, img.height);
      };
    });
  }, [areaNames]);

  return (x, y) =>
    areaNames.find((name) => {
      const mask = masks.current[name];
      if (!mask) return false;
      const px = Math.round(x);
      const py = Math.round(y);
      return mask.data[(py * mask.width + px) * 4 + 3] > 128;
    });
}

function GameMap({ park, areas, villainKey, claimCost, lockCost, onSelect }) {
  const layout = BOARD_LAYOUT[park];
  const color = villainColor(villainKey);
  const areaNames = areas.map((a) => a.area);
  const hitTest = useAreaHitTest(areaNames);
  const { crop } = layout;

  const handleTap = (event) => {
    if (!onSelect) return;
    const rect = event.currentTarget.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * IMAGE_SIZE.width;
    const y = ((event.clientY - rect.top) / rect.height) * IMAGE_SIZE.height;
    const hit = hitTest(x, y);
    if (hit) onSelect(hit);
  };

  const fill = { position: "absolute", inset: 0, width: "100%", height: "100%" };
  const mask = (src) => ({
    ...fill,
    WebkitMaskImage: `url(${src})`,
    maskImage: `url(${src})`,
    WebkitMaskSize: "100% 100%",
    maskSize: "100% 100%",
  });

  return (
    <div
      className="relative w-full overflow-hidden bg-green-900 select-none"
      style={{ aspectRatio: `${crop.width} / ${crop.height}` }}
    >
      <div
        className={`absolute ${onSelect ? "cursor-pointer" : ""}`}
        onClick={handleTap}
        style={{
          left: pct(-crop.x, crop.width),
          top: pct(-crop.y, crop.height),
          width: pct(IMAGE_SIZE.width, crop.width),
          height: pct(IMAGE_SIZE.height, crop.height),
        }}
      >
        <img src={IMAGES.mapBackground} style={fill} alt="" draggable={false} />
        {areas.map((area) => {
          const src = IMAGES[toCamelCase(area.area)];
          return (
            <div key={area.area}>
              <img src={src} style={{ ...fill, filter: OWNER_FILTERS[area.owner] }} alt="" draggable={false} />
              {area.owner === "villain" && <div style={{ ...mask(src), backgroundColor: color, opacity: 0.55 }} />}
            </div>
          );
        })}
        <img src={IMAGES[`${toCamelCase(park)}Lines`]} style={fill} alt="" draggable={false} />

        {areas
          .filter((area) => area.locked || area.influence > 0 || area.claim > 0)
          .map((area) => {
            const [x, y] = layout.centers[area.area];
            const claimTarget = area.owner === "players" ? lockCost : claimCost;
            return (
              <div
                key={area.area}
                className="pointer-events-none absolute flex items-center gap-1 rounded-full bg-slate-900/70 px-1.5 py-1"
                style={{ left: pct(x, IMAGE_SIZE.width), top: pct(y, IMAGE_SIZE.height), transform: "translate(-50%, -50%)" }}
              >
                {area.locked && <LockIcon sx={{ fontSize: 12 }} className="text-amber-300" />}
                {area.influence > 0 &&
                  [0, 1, 2].map((i) => (
                    <span
                      key={i}
                      className="h-2 w-2 rounded-full border border-white/80"
                      style={{ backgroundColor: i < area.influence ? (area.owner === "villain" ? "white" : color) : "transparent" }}
                    />
                  ))}
                {area.claim > 0 &&
                  Array.from({ length: claimTarget }, (_, i) => (
                    <span
                      key={`claim-${i}`}
                      className="h-2 w-2 rounded-full border border-sky-300"
                      style={{ backgroundColor: i < area.claim ? "#38bdf8" : "transparent" }}
                    />
                  ))}
              </div>
            );
          })}
      </div>
    </div>
  );
}

export default GameMap;

GameMap.propTypes = {
  park: PropTypes.string.isRequired,
  areas: PropTypes.array.isRequired,
  villainKey: PropTypes.string.isRequired,
  claimCost: PropTypes.number.isRequired,
  lockCost: PropTypes.number.isRequired,
  onSelect: PropTypes.func,
};
