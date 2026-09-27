import PropTypes from "prop-types";

// Shown after failing a photo card (e.g. GeoGuessr): where each photo was
// taken, with its credit. Only the button closes it, so nobody misses it.
function AnswerPopup({ photos, onClose }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4" role="dialog" aria-modal="true">
      <div className="max-h-full w-full max-w-md overflow-y-auto rounded-xl bg-slate-800 p-4 text-white shadow-xl">
        <h2 className="text-xs font-bold uppercase tracking-wide text-slate-400">The answer</h2>
        {photos.map((photo) => (
          <figure key={photo.image} className="mt-2">
            <img className="w-full rounded-lg" src={photo.image} alt={photo.answer || "Challenge photo"} />
            {photo.answer && <p className="mt-2 text-lg font-bold">{photo.answer}</p>}
            {photo.credit && (
              <figcaption className="mt-1 text-[10px] text-slate-500">
                {photo.source ? (
                  <a href={photo.source} target="_blank" rel="noreferrer" className="underline">
                    {photo.credit}
                  </a>
                ) : (
                  photo.credit
                )}
              </figcaption>
            )}
          </figure>
        ))}
        <button className="mt-4 w-full rounded-lg bg-sky-600 py-2 font-bold" onClick={onClose}>
          Got it
        </button>
      </div>
    </div>
  );
}

export default AnswerPopup;

AnswerPopup.propTypes = {
  photos: PropTypes.arrayOf(PropTypes.object).isRequired,
  onClose: PropTypes.func.isRequired,
};
