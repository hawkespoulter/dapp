import PropTypes from "prop-types";
import LockIcon from "@mui/icons-material/Lock";
import PlaceIcon from "@mui/icons-material/Place";
import { OWNER_LABELS } from "./gameRules";

const OWNER_STYLES = {
  players: "bg-sky-600",
  neutral: "bg-slate-600",
  villain: "bg-purple-700",
};

function AreaPanel({ area, here, busy, onMoveHere, villainName }) {
  return (
    <div className="flex items-center justify-between gap-2 bg-slate-800 px-3 py-2 text-white">
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
      {here ? (
        <span className="flex items-center gap-1 whitespace-nowrap text-xs font-bold text-emerald-400">
          <PlaceIcon sx={{ fontSize: 16 }} /> You&apos;re here
        </span>
      ) : (
        <button className="whitespace-nowrap rounded-lg bg-sky-600 px-3 py-2 text-sm font-bold disabled:opacity-40" disabled={busy} onClick={onMoveHere}>
          I&apos;m here
        </button>
      )}
    </div>
  );
}

export default AreaPanel;

AreaPanel.propTypes = {
  area: PropTypes.object.isRequired,
  here: PropTypes.bool,
  busy: PropTypes.bool,
  onMoveHere: PropTypes.func.isRequired,
  villainName: PropTypes.string.isRequired,
};
