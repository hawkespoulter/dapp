import { useState } from "react";
import PropTypes from "prop-types";
import PaidIcon from "@mui/icons-material/Paid";

// A challenge photo (e.g. GeoGuessr). Tap it to see it full screen; tap
// again to shrink it back.
function Photo({ photo }) {
  const [full, setFull] = useState(false);
  return (
    <>
      <button type="button" className="mt-2 block w-full" onClick={() => setFull(true)} aria-label="Show the photo full screen">
        <img className="w-full rounded-lg" src={photo.image} alt="Where was this taken?" loading="lazy" />
      </button>
      {full && (
        <button
          type="button"
          className="fixed inset-0 z-50 flex items-center justify-center bg-black"
          onClick={() => setFull(false)}
          aria-label="Shrink the photo"
        >
          <img className="max-h-full max-w-full object-contain" src={photo.image} alt="Where was this taken?" />
        </button>
      )}
    </>
  );
}

// Text with a hidden answer (e.g. a ride and the year it opened): guess,
// then tap Reveal.
function Fact({ fact }) {
  const [shown, setShown] = useState(false);
  return (
    <div className="mt-2 flex items-center justify-between gap-2 rounded-lg bg-slate-900 px-3 py-2">
      <span className="font-bold">{fact.text}</span>
      {shown ? (
        <span className="text-lg font-black text-amber-300">{fact.answer}</span>
      ) : (
        <button type="button" className="text-sm font-bold text-sky-400" onClick={() => setShown(true)}>
          Reveal
        </button>
      )}
    </div>
  );
}

function HandCard({ card, busy, onComplete, onFail, onSkip }) {
  const items = card.list || [];
  const photos = items.filter((item) => typeof item === "object" && item.image);
  const facts = items.filter((item) => typeof item === "object" && !item.image);
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
      {/* Photos (e.g. GeoGuessr) show on their own; the answer and credit
          appear when the card is failed (see AnswerPopup). */}
      {photos.map((photo) => (
        <Photo key={photo.image} photo={photo} />
      ))}
      {facts.map((fact) => (
        <Fact key={fact.text} fact={fact} />
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
        <button
          className="rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-300 disabled:opacity-40"
          disabled={busy}
          onClick={() => onSkip(card)}
          title="Can't be done? Swap it for a new one with no penalty."
        >
          Skip
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
  onSkip: PropTypes.func.isRequired,
};
Photo.propTypes = { photo: PropTypes.object.isRequired };
Fact.propTypes = { fact: PropTypes.object.isRequired };
