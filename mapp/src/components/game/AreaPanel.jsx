import PropTypes from "prop-types";
import LockIcon from "@mui/icons-material/Lock";
import { OWNER_LABELS } from "./gameRules";

const OWNER_STYLES = {
  players: "bg-sky-600",
  neutral: "bg-slate-600",
  villain: "bg-purple-700",
};

function AreaPanel({ area, villainName }) {
  return (
    <div className="bg-slate-800 px-3 py-2 text-white">
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <h2 className="truncate font-bold">{area.area}</h2>
          <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold uppercase whitespace-nowrap ${OWNER_STYLES[area.owner]}`}>
            {area.owner === "villain" ? villainName : OWNER_LABELS[area.owner]}
          </span>
          {area.locked && <LockIcon sx={{ fontSize: 14 }} className="text-amber-300" />}
        </div>
        <p className="text-xs text-slate-400">
          {area.owner === "villain" ? "Strength" : "Influence"} {area.influence}/3
          {area.min_difficulty > 1 && ` · needs ${area.min_difficulty}★+`}
          {" · next to "}
          {area.neighbors.map((n) => n.replace(", U.S.A.", "")).join(", ")}
        </p>
      </div>
    </div>
  );
}

export default AreaPanel;

AreaPanel.propTypes = {
  area: PropTypes.object.isRequired,
  villainName: PropTypes.string.isRequired,
};
