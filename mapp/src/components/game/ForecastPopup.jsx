import PropTypes from "prop-types";
import { villainColor } from "./boardLayout";

const ORDER = ["Next", "Then", "Then"];

// A Forecast's reveal: the villain's next cards, in order. One has to be
// thrown away before this closes.
function ForecastPopup({ cards, villain, busy, onDiscard }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-3" role="dialog" aria-modal="true">
      <div className="w-full max-w-md rounded-xl bg-slate-800 p-4 text-white shadow-xl">
        <h2 className="text-lg font-bold">Forecast</h2>
        <p className="text-sm text-slate-300">{villain.name}&apos;s next cards. Throw one away.</p>
        <ol className="mt-3 flex flex-col gap-2">
          {cards.map((card, i) => {
            const rising = card === "rising";
            return (
              <li key={`${card}-${i}`} className="flex items-center gap-3">
                <span className="w-10 text-xs uppercase text-slate-400">{ORDER[i]}</span>
                <span
                  className={`flex-1 rounded-md border-2 px-2 py-1 text-sm font-black uppercase tracking-wide ${
                    rising ? "border-fuchsia-400 text-fuchsia-300" : ""
                  }`}
                  style={rising ? undefined : { borderColor: villainColor(villain.key) }}
                >
                  {rising ? "Villain Rising" : card.replace(/^area:/, "")}
                </span>
                <button
                  className="rounded-lg bg-violet-600 px-3 py-1.5 text-sm font-bold disabled:opacity-40"
                  disabled={busy}
                  onClick={() => onDiscard(i)}
                >
                  Throw away
                </button>
              </li>
            );
          })}
        </ol>
      </div>
    </div>
  );
}

export default ForecastPopup;

ForecastPopup.propTypes = {
  cards: PropTypes.arrayOf(PropTypes.string).isRequired,
  villain: PropTypes.object.isRequired,
  busy: PropTypes.bool,
  onDiscard: PropTypes.func.isRequired,
};
