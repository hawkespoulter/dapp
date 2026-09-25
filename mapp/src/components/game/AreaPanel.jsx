import PropTypes from "prop-types";
import LockIcon from "@mui/icons-material/Lock";
import { OWNER_LABELS, meterText, placementPlan } from "./gameRules";

const OWNER_STYLES = {
  players: "bg-sky-600",
  neutral: "bg-slate-600",
  villain: "bg-purple-700",
};

function AreaPanel({ state, area, busy, onPlace }) {
  const { villain, game } = state;
  const plan = placementPlan(state, area.area);
  const stash = game.influence_stash;
  const affordable = Math.min(plan.cost, stash - (stash % plan.step));

  return (
    <div className="bg-slate-800 px-3 py-2 text-white">
      <div className="flex items-center gap-2">
        <h2 className="truncate font-bold">{area.area}</h2>
        <span className={`whitespace-nowrap rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${OWNER_STYLES[area.owner]}`}>
          {area.owner === "villain" ? villain.name : OWNER_LABELS[area.owner]}
        </span>
        {area.locked && <LockIcon sx={{ fontSize: 14 }} className="text-amber-300" />}
      </div>
      <p className="text-xs text-slate-400">
        {meterText(state, area)}
        {plan.step > 1 && ` · Thorn Wall: ${plan.step} influence per step`}
      </p>

      {plan.blocked ? (
        <p className="mt-2 text-sm text-amber-400">{plan.blocked}</p>
      ) : (
        <>
          <p className="mt-2 text-sm text-slate-300">
            {plan.cost} influence to {plan.goal}
          </p>
          <div className="mt-2 flex gap-2">
            <button
              className="rounded-lg bg-slate-700 px-4 py-2 text-sm font-bold disabled:opacity-40"
              disabled={busy || stash < plan.step}
              onClick={() => onPlace(plan.step)}
            >
              Place {plan.step}
            </button>
            <button
              className="flex-1 rounded-lg bg-sky-600 py-2 text-sm font-bold disabled:opacity-40"
              disabled={busy || affordable < plan.step}
              onClick={() => onPlace(affordable)}
            >
              {affordable >= plan.cost
                ? `Place ${plan.cost} · ${plan.goal}`
                : affordable >= plan.step
                  ? `Place ${affordable} of ${plan.cost}`
                  : `Need ${plan.cost} influence`}
            </button>
          </div>
        </>
      )}
    </div>
  );
}

export default AreaPanel;

AreaPanel.propTypes = {
  state: PropTypes.object.isRequired,
  area: PropTypes.object.isRequired,
  busy: PropTypes.bool,
  onPlace: PropTypes.func.isRequired,
};
