import PropTypes from "prop-types";
import { OWNER_LABELS, placementPlan } from "./gameRules";
import { villainColor } from "./boardLayout";

const OWNER_STYLES = {
  players: "bg-sky-600",
  neutral: "bg-slate-600",
};

const button = "rounded-lg py-2 text-sm font-bold disabled:opacity-40";

// An unclaimed area is claimed by going there and completing its claim
// challenge; that's the only thing to do with it.
function ClaimChallenge({ area, busy, onClaim }) {
  return (
    <div className="mt-2 rounded-lg bg-slate-900 p-3">
      <p className="text-[10px] font-bold uppercase tracking-wide text-emerald-400">Claim challenge · go to {area.area}</p>
      <h3 className="font-bold">{area.claim.title}</h3>
      {area.claim.description && <p className="text-sm text-slate-300">{area.claim.description}</p>}
      <div className="mt-2 flex gap-2">
        <button className={`${button} flex-1 bg-emerald-600`} disabled={busy} onClick={onClaim}>
          Claim
        </button>
      </div>
    </div>
  );
}

// Placing coins: strengthens your areas and wears the villain's down.
function Influence({ state, area, busy, onPlace }) {
  const plan = placementPlan(state, area.area);
  if (plan.claimOnly) return null;
  if (plan.blocked) return <p className="mt-2 text-sm text-amber-400">{plan.blocked}</p>;

  const coins = state.game.coins;
  const all = coins - (coins % plan.step);
  let main;
  if (plan.goal === "strengthen") {
    const short = coins > 0 ? `Need ${plan.step} coins per point here` : "No coins to place";
    main = { count: all, label: all >= plan.step ? `Place ${all}` : short };
  } else if (all >= plan.cost) {
    main = { count: plan.cost, label: `Place ${plan.cost}` };
  } else {
    main = { count: 0, label: `Need ${plan.cost} coins to ${plan.goal}` };
  }

  return (
    <div className="mt-2 flex gap-2">
      <button className={`${button} bg-slate-700 px-4`} disabled={busy || coins < plan.step} onClick={() => onPlace(plan.step)}>
        Place {plan.step}
      </button>
      <button className={`${button} flex-1 bg-sky-600`} disabled={busy || main.count < plan.step} onClick={() => onPlace(main.count)}>
        {main.label}
      </button>
    </div>
  );
}

function AreaPanel({ state, area, busy, onPlace, onClaim }) {
  const { villain } = state;

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

      {area.owner === "neutral" ? (
        area.claim && <ClaimChallenge area={area} busy={busy} onClaim={onClaim} />
      ) : (
        <Influence state={state} area={area} busy={busy} onPlace={onPlace} />
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
  onClaim: PropTypes.func.isRequired,
};
ClaimChallenge.propTypes = {
  area: PropTypes.object.isRequired,
  busy: PropTypes.bool,
  onClaim: PropTypes.func.isRequired,
};
Influence.propTypes = {
  state: PropTypes.object.isRequired,
  area: PropTypes.object.isRequired,
  busy: PropTypes.bool,
  onPlace: PropTypes.func.isRequired,
};
