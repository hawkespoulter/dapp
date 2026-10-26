import { useState } from "react";
import PropTypes from "prop-types";
import { useLocation } from "react-router-dom";
import BugReportIcon from "@mui/icons-material/BugReport";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/DeleteOutline";
import { useDeleteBugMutation, useFetchBugsQuery, useSaveBugMutation } from "~/store/apis/gameApi";
import { errorMessage } from "./game/playerStorage";

function Bug({ bug }) {
  const [save] = useSaveBugMutation();
  const [remove] = useDeleteBugMutation();
  return (
    <li className="flex items-start gap-2 rounded-lg bg-slate-900 p-2">
      <input
        type="checkbox"
        className="mt-1 h-4 w-4 shrink-0 accent-emerald-500"
        checked={bug.fixed}
        onChange={() => save({ id: bug.id, fixed: !bug.fixed })}
        aria-label={bug.fixed ? "Mark as not fixed" : "Mark as fixed"}
      />
      <div className="min-w-0 flex-1">
        <p className={`whitespace-pre-wrap text-sm ${bug.fixed ? "text-slate-500 line-through" : "text-white"}`}>{bug.note}</p>
        <p className="text-[10px] font-normal text-slate-500">
          {new Date(bug.created_at).toLocaleDateString([], { month: "short", day: "numeric" })}
          {bug.page && ` · ${bug.page}`}
        </p>
      </div>
      <button
        type="button"
        className="text-slate-500"
        onClick={() => window.confirm("Delete this bug?") && remove(bug.id)}
        aria-label="Delete bug"
      >
        <DeleteIcon sx={{ fontSize: 18 }} />
      </button>
    </li>
  );
}

Bug.propTypes = { bug: PropTypes.object.isRequired };

function BugPanel({ onClose }) {
  const { pathname, search } = useLocation();
  const { data: bugs, error } = useFetchBugsQuery();
  const [save, { isLoading }] = useSaveBugMutation();
  const [note, setNote] = useState("");
  const [saveError, setSaveError] = useState(null);
  const [showFixed, setShowFixed] = useState(false);
  const open = (bugs || []).filter((b) => !b.fixed);
  const fixed = (bugs || []).filter((b) => b.fixed);

  const add = async (e) => {
    e.preventDefault();
    setSaveError(null);
    try {
      await save({ note, page: pathname + search }).unwrap();
      setNote("");
    } catch (err) {
      setSaveError(errorMessage(err));
    }
  };

  return (
    <div className="fixed inset-0 z-[60] flex justify-end bg-black/60" onClick={onClose} role="presentation">
      <div
        className="flex h-full w-full max-w-sm flex-col gap-3 overflow-y-auto bg-slate-800 p-4 font-normal text-white shadow-xl"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-label="Bug list"
      >
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-bold">Bugs</h2>
          <button type="button" onClick={onClose} className="text-slate-400" aria-label="Close bug list">
            <CloseIcon />
          </button>
        </div>
        <form onSubmit={add} className="flex flex-col gap-2">
          <textarea
            className="w-full rounded-lg bg-slate-900 px-2 py-1.5 text-sm text-white"
            rows={3}
            placeholder="What went wrong?"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            required
          />
          <button type="submit" disabled={isLoading} className="rounded-lg bg-sky-600 py-2 text-sm font-bold disabled:opacity-50">
            Add bug
          </button>
          <p className="text-[10px] text-slate-500">Saves the page you&apos;re on ({pathname}) with it.</p>
          {saveError && <p className="text-sm text-red-300">{saveError}</p>}
        </form>
        {error && <p className="text-sm text-red-300">{errorMessage(error)}</p>}
        {bugs && open.length === 0 && <p className="text-sm text-slate-400">No open bugs. 🎉</p>}
        <ul className="flex flex-col gap-2">
          {open.map((bug) => (
            <Bug key={bug.id} bug={bug} />
          ))}
        </ul>
        {fixed.length > 0 && (
          <>
            <button type="button" onClick={() => setShowFixed(!showFixed)} className="self-start text-sm text-sky-400">
              {showFixed ? "Hide" : "Show"} fixed ({fixed.length})
            </button>
            {showFixed && (
              <ul className="flex flex-col gap-2">
                {fixed.map((bug) => (
                  <Bug key={bug.id} bug={bug} />
                ))}
              </ul>
            )}
          </>
        )}
      </div>
    </div>
  );
}

BugPanel.propTypes = { onClose: PropTypes.func.isRequired };

// The bug button in the navbar: a running list of bugs to fix, with a badge
// counting the open ones.
function BugList() {
  const [shown, setShown] = useState(false);
  const { data: bugs } = useFetchBugsQuery();
  const openCount = (bugs || []).filter((b) => !b.fixed).length;

  return (
    <>
      <button type="button" onClick={() => setShown(true)} className="relative ml-auto" aria-label="Bug list">
        <BugReportIcon />
        {openCount > 0 && (
          <span className="absolute -right-2 -top-1.5 rounded-full bg-red-600 px-1 text-[10px] leading-4 text-white">{openCount}</span>
        )}
      </button>
      {shown && <BugPanel onClose={() => setShown(false)} />}
    </>
  );
}

export default BugList;
