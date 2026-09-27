import PropTypes from "prop-types";
import PaidIcon from "@mui/icons-material/Paid";

// Power-ups the team buys with its shared coins. Redraw, Double Down and
// Safety Net are for the player who buys them; Shield protects the area
// selected on the map.
function powerList({ game, villain }, area) {
  const name = villain.name;
  const shieldable = area?.owner === "players" && !area.shielded;
  return [
    { key: "forecast", title: "Forecast", text: `See ${name}'s next 3 cards and throw one away.` },
    { key: "stall", title: "Stall", text: `${name} skips the next turn.` },
    {
      key: "shield",
      title: "Shield",
      text: `The area selected on the map can't lose influence on ${name}'s next turn.`,
      button: shieldable ? `Shield ${area.area}` : "Pick one of your areas",
      disabled: !shieldable,
    },
    { key: "redraw", title: "Redraw", text: "Swap your whole hand for new challenges." },
    { key: "double_down", title: "Double Down", text: "Your next completed challenge pays double." },
    game.hard_mode && {
      key: "safety_net",
      title: "Safety Net",
      text: `Your next failed challenge doesn't wake ${name}, and you can undo it.`,
    },
  ].filter(Boolean);
}

// What's already bought and waiting to go off.
function activeEffects({ powers, villain }) {
  const effects = [];
  if (powers.stalls > 0) effects.push(`${villain.name} skips the next ${powers.stalls > 1 ? `${powers.stalls} turns` : "turn"}`);
  if (powers.shields.length > 0) effects.push(`Shielded: ${powers.shields.join(", ")}`);
  if (powers.double_down > 0) effects.push(`Your Double Down${powers.double_down > 1 ? ` ×${powers.double_down}` : ""} is ready`);
  if (powers.safety_net > 0) effects.push(`Your Safety Net${powers.safety_net > 1 ? ` ×${powers.safety_net}` : ""} is ready`);
  return effects;
}

function PowerUps({ state, area, busy, onUse }) {
  const { game, powers } = state;
  const effects = activeEffects(state);

  return (
    <div className="flex flex-col gap-2">
      {effects.length > 0 && (
        <ul className="rounded-lg bg-emerald-900/40 px-3 py-2 text-sm text-emerald-200">
          {effects.map((effect) => (
            <li key={effect}>{effect}</li>
          ))}
        </ul>
      )}
      {powerList(state, area).map((power) => {
        const price = powers.prices[power.key];
        const short = game.coins < price;
        return (
          <div key={power.key} className="flex items-center gap-3 rounded-xl bg-slate-800 p-3 text-white">
            <div className="flex-1">
              <div className="flex items-center gap-2">
                <h3 className="font-bold">{power.title}</h3>
                <span className="flex items-center gap-0.5 text-sm font-bold text-amber-300">
                  <PaidIcon sx={{ fontSize: 16 }} />
                  {price}
                </span>
              </div>
              <p className="text-sm text-slate-300">{power.text}</p>
            </div>
            <button
              className="max-w-32 shrink-0 rounded-lg bg-violet-600 px-3 py-2 text-sm font-bold disabled:opacity-40"
              disabled={busy || short || power.disabled}
              onClick={() => onUse(power.key, power.key === "shield" ? area.area : undefined)}
            >
              {power.button || "Use"}
            </button>
          </div>
        );
      })}
    </div>
  );
}

export default PowerUps;

PowerUps.propTypes = {
  state: PropTypes.object.isRequired,
  area: PropTypes.object,
  busy: PropTypes.bool,
  onUse: PropTypes.func.isRequired,
};
