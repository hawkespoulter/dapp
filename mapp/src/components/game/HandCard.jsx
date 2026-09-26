import PropTypes from "prop-types";
import PaidIcon from "@mui/icons-material/Paid";

function HandCard({ card, busy, onComplete, onFail }) {
  return (
    <div className="rounded-xl bg-slate-800 p-3 text-white shadow">
      <div className="flex items-center justify-between gap-2">
        <h3 className="font-bold leading-tight">{card.title}</h3>
        <span className="flex items-center gap-0.5 whitespace-nowrap text-sm font-bold text-amber-300">
          <PaidIcon sx={{ fontSize: 16 }} />+{card.reward}
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
          Done
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
