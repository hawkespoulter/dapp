import { useState } from "react";
import PropTypes from "prop-types";
import { useSaveContentMutation } from "~/store/apis/gameApi";
import { errorMessage } from "./playerStorage";

const input = "w-full rounded-lg bg-slate-900 px-2 py-1.5 text-white";

// Fix a challenge mid-game without leaving the board: a hand card (title,
// description, coins) or an area's claim card (title, description). Saves
// to the challenge itself, so every game sees the change. A claim area
// still on its stand-in card gets a real card of its own.
function QuickEdit({ edit, onSaved, onClose }) {
  const { kind, card, park, area } = edit;
  const claim = kind === "claim";
  const [save, { isLoading }] = useSaveContentMutation();
  const [error, setError] = useState(null);
  const [form, setForm] = useState({
    title: card.title || "",
    description: card.description || "",
    reward: card.reward ?? 1,
  });
  const set = (field) => (e) => setForm({ ...form, [field]: e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    setError(null);
    const { title, description, reward } = form;
    const request = claim
      ? { kind: "claim_challenges", id: card.id, body: { claim: { park, area, title, description } } }
      : { kind: "challenges", id: card.id, body: { challenge: { title, description, reward } } };
    try {
      await save(request).unwrap();
      onSaved();
      onClose();
    } catch (err) {
      setError(errorMessage(err));
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4" role="dialog" aria-modal="true">
      <form onSubmit={submit} className="flex w-full max-w-md flex-col gap-2 rounded-xl bg-slate-800 p-4 text-white shadow-xl">
        <h2 className="text-xs font-bold uppercase tracking-wide text-slate-400">
          {claim ? `Edit ${area}'s claim challenge` : "Edit challenge"}
        </h2>
        <input className={input} placeholder="Title" value={form.title} onChange={set("title")} required />
        <textarea className={input} rows={4} placeholder="Description" value={form.description} onChange={set("description")} />
        {!claim && (
          <label className="flex items-center gap-2 text-sm text-slate-300">
            Coins
            <input type="number" min={1} max={10} className={`${input} w-20`} value={form.reward} onChange={set("reward")} />
          </label>
        )}
        <p className="text-xs text-slate-500">
          Changes the challenge everywhere, not just this game.
          {!claim && " Lists and deleting are on the full challenge editor."}
        </p>
        {error && <p className="text-sm text-red-300">{error}</p>}
        <div className="flex gap-2">
          <button type="submit" disabled={isLoading} className="flex-1 rounded-lg bg-sky-600 py-2 font-bold disabled:opacity-50">
            Save
          </button>
          <button type="button" onClick={onClose} className="rounded-lg bg-slate-700 px-4 py-2">
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}

QuickEdit.propTypes = {
  edit: PropTypes.shape({
    kind: PropTypes.oneOf(["challenge", "claim"]).isRequired,
    card: PropTypes.object.isRequired,
    park: PropTypes.string,
    area: PropTypes.string,
  }).isRequired,
  onSaved: PropTypes.func.isRequired,
  onClose: PropTypes.func.isRequired,
};

export default QuickEdit;
