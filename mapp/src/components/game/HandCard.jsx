import { useState } from "react";
import PropTypes from "prop-types";
import PaidIcon from "@mui/icons-material/Paid";

// A photo dealt with a card (e.g. GeoGuessr): the picture, its credit, and
// where it was taken behind a Show answer button.
function Photo({ photo }) {
  const [revealed, setRevealed] = useState(false);
  return (
    <figure className="mt-2">
      <img className="w-full rounded-lg" src={photo.image} alt="Where was this taken?" loading="lazy" />
      {photo.credit && <figcaption className="mt-1 text-[10px] text-slate-500">{photo.credit}</figcaption>}
      {photo.answer && (
        <button className="mt-1 text-xs text-sky-400" onClick={() => setRevealed(!revealed)}>
          {revealed ? photo.answer : "Show answer"}
        </button>
      )}
    </figure>
  );
}

function HandCard({ card, busy, onComplete, onFail }) {
  const items = card.list || [];
  const photos = items.filter((item) => typeof item === "object");
  const words = items.filter((item) => typeof item === "string");

  return (
    <div className="rounded-xl bg-slate-800 p-3 text-white shadow">
      <div className="flex items-center justify-between gap-2">
        <h3 className="font-bold leading-tight">{card.title}</h3>
        <span className="flex items-center gap-0.5 whitespace-nowrap text-sm font-bold text-amber-300">
          <PaidIcon sx={{ fontSize: 16 }} />+{card.reward}
        </span>
      </div>
      {card.description && <p className="mt-1 text-sm text-slate-300">{card.description}</p>}
      {photos.map((photo) => (
        <Photo key={photo.image} photo={photo} />
      ))}
      {words.length > 0 && (
        <ul className="mt-2 grid list-disc grid-cols-2 gap-x-4 pl-5 text-sm text-slate-200">
          {words.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      )}
      <div className="mt-2 flex gap-2">
        <button
          className="flex-1 rounded-lg bg-emerald-600 py-2 font-bold disabled:opacity-40"
          disabled={busy}
          onClick={() => onComplete(card)}
        >
          Completed
        </button>
        <button
          className="rounded-lg bg-slate-700 px-4 py-2 text-sm disabled:opacity-40"
          disabled={busy}
          onClick={() => onFail(card)}
        >
          Failed
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
Photo.propTypes = { photo: PropTypes.object.isRequired };
