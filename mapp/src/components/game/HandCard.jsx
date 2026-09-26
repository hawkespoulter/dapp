import PropTypes from "prop-types";

function HandCard({ card, busy, onComplete, onFail }) {
  return (
    <div className="rounded-xl bg-slate-800 p-3 text-white shadow">
      <div className="flex items-center justify-between gap-2">
        <h3 className="font-bold leading-tight">{card.title}</h3>
        <span className="whitespace-nowrap text-sm text-amber-300" title={`Difficulty ${card.difficulty}`}>
          {"★".repeat(card.difficulty)}
          <span className="text-slate-600">{"★".repeat(3 - card.difficulty)}</span>
        </span>
      </div>
      {card.description && <p className="mt-1 text-sm text-slate-300">{card.description}</p>}
      {card.area && <p className="mt-1 text-xs text-slate-400">{card.area}</p>}
      <div className="mt-2 flex gap-2">
        <button
          className="flex-1 rounded-lg bg-emerald-600 py-2 font-bold disabled:opacity-40"
          disabled={busy}
          onClick={() => onComplete(card)}
        >
          Done · +{card.difficulty} coin{card.difficulty > 1 ? "s" : ""}
        </button>
        <button
          className="rounded-lg bg-slate-700 px-4 py-2 text-sm disabled:opacity-40"
          disabled={busy}
          onClick={() => onFail(card)}
        >
          Couldn&apos;t
        </button>
      </div>
    </div>
  );
}

export default HandCard;

HandCard.propTypes = {
  card: PropTypes.object.isRequired,
  busy: PropTypes.bool,
  onComplete: PropTypes.func.isRequired,
  onFail: PropTypes.func.isRequired,
};
