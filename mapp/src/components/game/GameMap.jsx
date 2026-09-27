import { useEffect, useRef } from "react";
import PropTypes from "prop-types";
import ShieldIcon from "@mui/icons-material/Shield";
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

// A label that pops up over an area and drifts upward (villain turn replay).
const POP_KEYFRAMES = `@keyframes area-pop {
  0% { transform: translate(-50%, -50%) scale(0.3); opacity: 0; }
  25% { transform: translate(-50%, -130%) scale(1.35); opacity: 1; }
  45% { transform: translate(-50%, -125%) scale(1); }
  100% { transform: translate(-50%, -150%) scale(1); opacity: 1; }
}`;

function GameMap({ park, areas, villainKey, onSelect, highlights = [], markers = [] }) {
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
              {highlights.includes(area.area) && (
                <div style={{ ...fill, opacity: 0.6 }}>
                  <div className="animate-pulse" style={{ ...mask(src), backgroundColor: "white" }} />
                </div>
              )}
            </div>
          );
        })}
        <img src={IMAGES[`${toCamelCase(park)}Lines`]} style={fill} alt="" draggable={false} />

        {areas
          .filter((area) => area.owner !== "neutral")
          .map((area) => {
            const [x, y] = layout.centers[area.area];
            const hers = area.owner === "villain";
            return (
              <div
                key={area.area}
                className="pointer-events-none absolute"
                style={{ left: pct(x, IMAGE_SIZE.width), top: pct(y, IMAGE_SIZE.height), transform: "translate(-50%, -50%)" }}
              >
                <div
                  className={`flex h-6 min-w-6 items-center justify-center rounded-full border-2 border-white/80 px-1 text-xs font-black text-white shadow transition-transform duration-300 ${
                    highlights.includes(area.area) ? "scale-150" : ""
                  }`}
                  style={{ backgroundColor: hers ? color : "#0284c7" }}
                  title={`Strength ${area.strength}`}
                >
                  {area.strength}
                </div>
                {area.shielded && (
                  <ShieldIcon
                    className="absolute -right-4 -top-4 text-sky-300"
                    sx={{ fontSize: 22, filter: "drop-shadow(0 0 1px #0f172a) drop-shadow(0 0 1px #0f172a)" }}
                    titleAccess="Shielded"
                  />
                )}
              </div>
            );
          })}

        {markers.length > 0 && <style>{POP_KEYFRAMES}</style>}
        {markers
          .filter((marker) => layout.centers[marker.area])
          .map((marker) => (
            <div
              key={marker.id}
              className="pointer-events-none absolute whitespace-nowrap rounded-full px-3 py-1 text-lg font-black text-white shadow-lg ring-2 ring-white"
              style={{
                left: pct(layout.centers[marker.area][0], IMAGE_SIZE.width),
                top: pct(layout.centers[marker.area][1], IMAGE_SIZE.height),
                backgroundColor: marker.color,
                animation: "area-pop 0.9s ease-out forwards",
              }}
            >
              {marker.text}
            </div>
          ))}
      </div>
    </div>
  );
}

export default GameMap;

GameMap.propTypes = {
  park: PropTypes.string.isRequired,
  areas: PropTypes.array.isRequired,
  villainKey: PropTypes.string.isRequired,
  onSelect: PropTypes.func,
  highlights: PropTypes.arrayOf(PropTypes.string),
  markers: PropTypes.arrayOf(
    PropTypes.shape({ id: PropTypes.any, area: PropTypes.string, text: PropTypes.string, color: PropTypes.string }),
  ),
};
