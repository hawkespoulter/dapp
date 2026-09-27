import { useEffect, useMemo, useState } from "react";
import PropTypes from "prop-types";
import GameMap from "./GameMap";
import { villainColor } from "./boardLayout";

const STEP_MS = 1100;
const CARD_MS = 1500;
const START_MS = 500;
const WEAKENED = "#d97706";
const LOST = "#dc2626";
const SPILL = "#ea580c";

// What pops up over an area when this event changes it, given its strength before.
function markerFor(event, before, villainHex) {
  const [, was = 0] = before || [];
  switch (event.kind) {
    case "strength":
      return { text: `+${event.strength - was}`, color: villainHex };
    case "weakened":
      return { text: `\u2212${was - event.strength}`, color: WEAKENED };
    case "lost_area":
      return { text: `\u2212${was}`, color: LOST };
    case "takeover":
      return { text: "Taken!", color: villainHex };
    case "outbreak":
      return { text: "Spills over!", color: SPILL };
    default:
      return null;
  }
}

// One frame per event: the board after it, the areas to light up, what pops
// up over them, and the card (or named action) being played. The hits of a
// named action like a hyena raid strike the whole park at once, so they
// share one frame. Each turn starts from the board recorded when it began.
function buildFrames(turns, areas, villainHex) {
  let board = Object.fromEntries(areas.map((a) => [a.area, [a.owner, a.strength]]));
  let action = null;
  const frames = [];
  turns.forEach((turn) =>
    turn.events.forEach((event, i) => {
      if (event.board) {
        board = { ...event.board };
        action = null;
      }
      const pop = event.area ? markerFor(event, board[event.area], villainHex) : null;
      const marker = pop && { ...pop, area: event.area, id: `${turn.turn}-${i}` };
      if (event.area && event.owner) board = { ...board, [event.area]: [event.owner, event.strength] };
      const starts = Boolean(event.card || event.action);
      if (starts) action = event;

      const volley = action?.action && !starts ? action : null;
      const prev = frames[frames.length - 1];
      if (volley && prev?.volley === volley) {
        prev.board = board;
        if (!prev.highlights.includes(event.area)) prev.highlights.push(event.area);
        // An area knocked out then taken shows only the last label.
        if (marker) prev.markers = [...prev.markers.filter((m) => m.area !== event.area), marker];
        return;
      }
      frames.push({
        board,
        action,
        volley,
        highlights: event.area ? [event.area] : [],
        markers: marker ? [marker] : [],
      });
    }),
  );
  return frames;
}

function ActionBanner({ event, villain }) {
  if (!event) return <p className="text-sm italic text-slate-400">{villain.name} gets ready…</p>;
  const rising = event.card === "Villain Rising";
  return (
    <div className="flex items-center gap-2">
      <span className="text-sm text-slate-400">{event.card ? `${villain.name} plays` : `${villain.name}'s`}</span>
      <span
        className={`rounded-md border-2 px-2 py-1 text-sm font-black uppercase tracking-wide ${
          rising ? "border-fuchsia-400 text-fuchsia-300" : "text-white"
        }`}
        style={rising ? undefined : { borderColor: villainColor(villain.key) }}
      >
        {event.card || event.action}
      </span>
      {event.note && <span className="text-xs text-slate-400">{event.note}</span>}
    </div>
  );
}

// Plays the villain's turns on the map one step at a time: the card being
// played shows above the map, and each change lights up its area with a
// label popping up over it. Only the button closes it.
function VillainTurnReplay({ turns, villain, areas, park, closeLabel = "Got it", onClose }) {
  const villainHex = villainColor(villain.key);
  const frames = useMemo(() => buildFrames(turns, areas, villainHex), [turns, areas, villainHex]);
  const [step, setStep] = useState(0);
  const last = frames.length - 1;
  const playing = step < last;

  useEffect(() => {
    if (!playing) return undefined;
    const next = frames[step + 1];
    const wait = step === 0 ? START_MS : next.action !== frames[step].action ? CARD_MS : STEP_MS;
    const id = setTimeout(() => setStep((s) => s + 1), wait);
    return () => clearTimeout(id);
  }, [step, playing, frames]);

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
      <div className="flex w-full max-w-md flex-col overflow-hidden rounded-xl bg-slate-800 text-white shadow-xl">
        <div className="flex items-center gap-2 px-4 pt-3">
          <span className="h-3 w-3 rounded-full" style={{ backgroundColor: villainHex }} />
          <h2 className="flex-1 text-lg font-bold">{title}</h2>
          <span className="text-sm">
            You <span className="font-bold text-sky-300">{ours}</span> · {villain.name}{" "}
            <span className="font-bold" style={{ color: villainHex }}>{hers}</span>
          </span>
        </div>
        <div className="flex min-h-12 items-center px-4 py-2">
          <ActionBanner event={frame.action} villain={villain} />
        </div>
        <GameMap
          park={park}
          areas={shownAreas}
          villainKey={villain.key}
          highlights={frame.highlights}
          markers={frame.markers}
        />
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
ActionBanner.propTypes = { event: PropTypes.object, villain: PropTypes.object.isRequired };
