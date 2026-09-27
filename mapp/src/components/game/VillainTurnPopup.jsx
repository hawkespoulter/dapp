import PropTypes from "prop-types";
import { villainColor } from "./boardLayout";

// Events the players should notice first.
const TONE = {
  takeover: "text-red-300",
  lost_area: "text-red-300",
  weakened: "text-amber-300",
  rising: "text-fuchsia-300 font-bold",
  outbreak: "text-orange-300",
  villain_turn: "text-slate-400 italic",
};

// What the villain did on the turns this phone hasn't shown yet, with where
// the park stands now. Only the button closes it.
function VillainTurnPopup({ turns, villain, areas, onClose }) {
  const ours = areas.filter((a) => a.owner === "players").length;
  const hers = areas.filter((a) => a.owner === "villain").length;
  const title = turns.length === 1 ? `${villain.name}'s turn` : `${villain.name} took ${turns.length} turns`;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4" role="dialog" aria-modal="true">
      <div className="max-h-full w-full max-w-md overflow-y-auto rounded-xl bg-slate-800 p-4 text-white shadow-xl">
        <div className="flex items-center gap-2">
          <span className="h-3 w-3 rounded-full" style={{ backgroundColor: villainColor(villain.key) }} />
          <h2 className="text-lg font-bold">{title}</h2>
        </div>
        {turns.map((turn) => (
          <ul key={turn.turn} className="mt-3 flex flex-col gap-1 border-t border-slate-700 pt-2 text-sm">
            {turn.events.map((event, i) =>
              event.card ? (
                <li key={i} className="mt-1 flex items-center gap-2">
                  <span
                    className={`rounded-md border-2 px-2 py-1 text-xs font-black uppercase tracking-wide ${
                      event.card === "Villain Rising" ? "border-fuchsia-400 text-fuchsia-300" : "text-white"
                    }`}
                    style={event.card === "Villain Rising" ? undefined : { borderColor: villainColor(villain.key) }}
                  >
                    {event.card}
                  </span>
                  <span className="text-xs text-slate-400">{event.note || "card played"}</span>
                </li>
              ) : (
                <li key={i} className={`pl-3 ${TONE[event.kind] || "text-slate-200"}`}>
                  {event.message}
                </li>
              ),
            )}
          </ul>
        ))}
        <p className="mt-3 rounded-lg bg-slate-900 px-3 py-2 text-sm">
          You hold <span className="font-bold text-sky-300">{ours}</span> areas · {villain.name} holds{" "}
          <span className="font-bold" style={{ color: villainColor(villain.key) }}>{hers}</span>
        </p>
        <button className="mt-4 w-full rounded-lg bg-sky-600 py-2 font-bold" onClick={onClose}>
          Got it
        </button>
      </div>
    </div>
  );
}

export default VillainTurnPopup;

VillainTurnPopup.propTypes = {
  turns: PropTypes.arrayOf(PropTypes.object).isRequired,
  villain: PropTypes.object.isRequired,
  areas: PropTypes.arrayOf(PropTypes.object).isRequired,
  onClose: PropTypes.func.isRequired,
};
