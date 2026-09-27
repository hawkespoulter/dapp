import PropTypes from "prop-types";
import { OWNER_LABELS, placementPlan } from "./gameRules";
import { villainColor } from "./boardLayout";

const OWNER_STYLES = {
  players: "bg-sky-600",
  neutral: "bg-slate-600",
};

const button = "rounded-lg py-2 text-sm font-bold disabled:opacity-40";

function AreaPanel({ state, area, busy, onPlace }) {
  const { villain, game } = state;
  const plan = placementPlan(state, area.area);
  const stash = game.influence_stash;
  const all = stash - (stash % plan.step);

  let main;
  if (plan.goal === "strengthen") {
    const short = stash > 0 ? `Need ${plan.step} per point here` : "No influence to place";
    main = { count: all, label: all >= plan.step ? `Place ${all}` : short };
  } else if (all >= plan.cost) {
    main = { count: plan.cost, label: `Place ${plan.cost}` };
  } else {
    main = { count: 0, label: `Need ${plan.cost} influence to ${plan.goal}` };
  }

  return (
    <div className="bg-slate-800 px-3 py-2 text-white">
      <div className="flex items-center gap-2">
        <h2 className="truncate font-bold">{area.area}</h2>
        <span
          className={`whitespace-nowrap rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${OWNER_STYLES[area.owner] || ""}`}
          style={area.owner === "villain" ? { backgroundColor: villainColor(villain.key) } : undefined}
        >
          {area.owner === "villain" ? villain.name : OWNER_LABELS[area.owner]}
        </span>
      </div>

      {plan.blocked ? (
        <p className="mt-2 text-sm text-amber-400">{plan.blocked}</p>
      ) : (
        <>
          <div className="mt-2 flex gap-2">
            {plan.goal !== "claim it" && (
              <button className={`${button} bg-slate-700 px-4`} disabled={busy || stash < plan.step} onClick={() => onPlace(plan.step)}>
                Place {plan.step}
              </button>
            )}
            <button
              className={`${button} flex-1 bg-sky-600`}
              disabled={busy || main.count < plan.step}
              onClick={() => onPlace(main.count)}
            >
              {main.label}
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
