import { useEffect, useMemo, useRef, useState } from "react";
import PropTypes from "prop-types";
import GameMap from "./GameMap";
import { villainColor } from "./boardLayout";

const STEP_MS = 1100;
const CARD_MS = 1600;

// Events the players should notice first.
const TONE = {
  takeover: "text-red-300",
  lost_area: "text-red-300",
  weakened: "text-amber-300",
  rising: "text-fuchsia-300 font-bold",
  outbreak: "text-orange-300",
  villain_turn: "text-slate-400 italic",
  finished: "text-red-300 font-bold",
};

// One frame per event: the board as it stood after that event. Each turn
// starts from the board recorded when it began; each change then updates
// the area it names.
function buildFrames(turns, areas) {
  let board = Object.fromEntries(areas.map((a) => [a.area, [a.owner, a.strength]]));
  return turns.flatMap((turn) =>
    turn.events.map((event) => {
      if (event.board) board = { ...event.board };
      else if (event.area && event.owner) board = { ...board, [event.area]: [event.owner, event.strength] };
      return { event, board, turn: turn.turn };
    }),
  );
}

function CardChip({ event, villainKey }) {
  const rising = event.card === "Villain Rising";
  return (
    <span className="flex items-center gap-2">
      <span
        className={`rounded-md border-2 px-2 py-1 text-xs font-black uppercase tracking-wide ${
          rising ? "border-fuchsia-400 text-fuchsia-300" : "text-white"
        }`}
        style={rising ? undefined : { borderColor: villainColor(villainKey) }}
      >
        {event.card}
      </span>
      <span className="text-xs text-slate-400">{event.note || "card played"}</span>
    </span>
  );
}

// Plays the villain's turns on the map one step at a time: each card and
// each hit lights up its area while the strengths change, with the moves
// listed underneath. Only the button closes it.
function VillainTurnReplay({ turns, villain, areas, park, closeLabel = "Got it", onClose }) {
  const frames = useMemo(() => buildFrames(turns, areas), [turns, areas]);
  const [step, setStep] = useState(0);
  const last = frames.length - 1;
  const playing = step < last;
  const current = useRef(null);

  useEffect(() => {
    if (!playing) return undefined;
    const id = setTimeout(() => setStep((s) => s + 1), frames[step].event.card ? CARD_MS : STEP_MS);
    return () => clearTimeout(id);
  }, [step, playing, frames]);

  useEffect(() => {
    current.current?.scrollIntoView({ block: "nearest", behavior: "smooth" });
  }, [step]);

  const frame = frames[Math.min(step, last)];
  const shownAreas = areas.map((a) => {
    const [owner, strength] = frame.board[a.area] || [a.owner, a.strength];
    return { ...a, owner, strength };
  });
  const ours = shownAreas.filter((a) => a.owner === "players").length;
  const hers = shownAreas.filter((a) => a.owner === "villain").length;
  const title = turns.length === 1 ? `${villain.name}'s turn` : `${villain.name} took ${turns.length} turns`;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-3" role="dialog" aria-modal="true">
      <div className="flex max-h-full w-full max-w-md flex-col overflow-hidden rounded-xl bg-slate-800 text-white shadow-xl">
        <div className="flex items-center gap-2 px-4 pt-3 pb-2">
          <span className="h-3 w-3 rounded-full" style={{ backgroundColor: villainColor(villain.key) }} />
          <h2 className="flex-1 text-lg font-bold">{title}</h2>
          <span className="text-xs text-slate-400">
            You {ours} · {villain.name} {hers}
          </span>
        </div>
        <GameMap park={park} areas={shownAreas} villainKey={villain.key} highlight={frame.event.area} />

        <ol className="min-h-24 flex-1 overflow-y-auto px-4 py-2 text-sm">
          {frames.slice(0, step + 1).map(({ event, turn }, i) => (
            <li
              key={i}
              ref={i === step ? current : null}
              className={`rounded px-2 py-1 transition-colors ${i === step && playing ? "bg-slate-700" : ""} ${
                i > 0 && frames[i - 1].turn !== turn ? "mt-2 border-t border-slate-700 pt-2" : ""
              }`}
            >
              {event.card ? (
                <CardChip event={event} villainKey={villain.key} />
              ) : (
                <span className={TONE[event.kind] || "text-slate-200"}>{event.message}</span>
              )}
            </li>
          ))}
        </ol>

        <div className="flex gap-2 p-3">
          {playing ? (
            <button className="flex-1 rounded-lg bg-slate-700 py-2 font-bold" onClick={() => setStep(last)}>
              Skip
            </button>
          ) : (
            <>
              <button className="rounded-lg bg-slate-700 px-4 py-2 text-sm" onClick={() => setStep(0)}>
                Replay
              </button>
              <button className="flex-1 rounded-lg bg-sky-600 py-2 font-bold" onClick={onClose}>
                {closeLabel}
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

export default VillainTurnReplay;

VillainTurnReplay.propTypes = {
  turns: PropTypes.arrayOf(PropTypes.object).isRequired,
  villain: PropTypes.object.isRequired,
  areas: PropTypes.arrayOf(PropTypes.object).isRequired,
  park: PropTypes.string.isRequired,
  closeLabel: PropTypes.string,
  onClose: PropTypes.func.isRequired,
};
CardChip.propTypes = { event: PropTypes.object.isRequired, villainKey: PropTypes.string.isRequired };
