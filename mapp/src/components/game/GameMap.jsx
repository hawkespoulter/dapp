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

function GameMap({ park, areas, players, villainKey, selected, onSelect }) {
  const layout = BOARD_LAYOUT[park];
  const color = villainColor(villainKey);
  const areaNames = areas.map((a) => a.area);
  const hitTest = useAreaHitTest(areaNames);
  const { crop } = layout;

  const handleTap = (event) => {
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
        className="absolute cursor-pointer"
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
              {area.area === selected && <div className="animate-pulse" style={{ ...mask(src), backgroundColor: "white", opacity: 0.35 }} />}
            </div>
          );
        })}
        <img src={IMAGES[`${toCamelCase(park)}Lines`]} style={fill} alt="" draggable={false} />

        {areas.map((area) => {
          const [x, y] = layout.labels[area.area];
          const here = players.filter((p) => p.current_area === area.area);
          return (
            <div
              key={area.area}
              className="absolute flex flex-col items-center gap-0.5 pointer-events-none"
              style={{ left: pct(x, IMAGE_SIZE.width), top: pct(y, IMAGE_SIZE.height), transform: "translate(-50%, -50%)" }}
            >
              <div className="flex items-center gap-0.5 rounded-full bg-slate-900/80 px-1.5 py-0.5 text-[10px] font-bold leading-none text-white whitespace-nowrap">
                {area.locked && <LockIcon sx={{ fontSize: 10 }} className="text-amber-300" />}
                {area.area.replace(", U.S.A.", "")}
              </div>
              {area.influence > 0 && (
                <div className="flex gap-0.5">
                  {[0, 1, 2].map((i) => (
                    <span
                      key={i}
                      className="h-2 w-2 rounded-full border border-white/80"
                      style={{ backgroundColor: i < area.influence ? (area.owner === "villain" ? "white" : color) : "transparent" }}
                    />
                  ))}
                </div>
              )}
              {here.length > 0 && (
                <div className="flex -space-x-1">
                  {here.map((p) => (
                    <span key={p.id} className="flex h-4 w-4 items-center justify-center rounded-full border border-white bg-sky-500 text-[8px] font-bold text-white">
                      {p.name[0].toUpperCase()}
                    </span>
                  ))}
                </div>
              )}
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
  players: PropTypes.array.isRequired,
  villainKey: PropTypes.string.isRequired,
  selected: PropTypes.string,
  onSelect: PropTypes.func.isRequired,
};
