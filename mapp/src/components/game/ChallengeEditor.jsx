import { useState } from "react";
import PropTypes from "prop-types";
import { Link, useSearchParams } from "react-router-dom";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import AddIcon from "@mui/icons-material/Add";
import { API_URL } from "~/constants";
import {
  useDeleteContentMutation,
  useFetchGameContentQuery,
  useSaveContentMutation,
} from "~/store/apis/gameApi";
import { errorMessage } from "./playerStorage";

const card = "rounded-xl bg-slate-800 p-3";
const input = "w-full rounded-lg bg-slate-900 px-2 py-1.5 text-white";
const button = "rounded-lg px-3 py-1.5 text-sm font-bold";
const TABS = { hand: "Hand", claims: "Claim", lists: "Lists" };

// Save and delete for one kind of content, keeping the last error to show.
function useContent(kind) {
  const [save, { isLoading: saving }] = useSaveContentMutation();
  const [remove] = useDeleteContentMutation();
  const [error, setError] = useState(null);
  const run = async (promise, done) => {
    setError(null);
    try {
      await promise.unwrap();
      done?.();
    } catch (e) {
      setError(errorMessage(e));
    }
  };
  return {
    saving,
    error,
    save: (id, body, done) => run(save({ kind, id, body }), done),
    remove: (id, done) => run(remove({ kind, id }), done),
  };
}

function Buttons({ saving, onCancel, onDelete }) {
  return (
    <div className="flex gap-2">
      <button type="submit" disabled={saving} className={`${button} bg-sky-600 disabled:opacity-50`}>
        Save
      </button>
      <button type="button" onClick={onCancel} className={`${button} bg-slate-700`}>
        Cancel
      </button>
      {onDelete && (
        <button
          type="button"
          onClick={() => window.confirm("Delete this for good?") && onDelete()}
          className={`${button} ml-auto bg-red-900 text-red-100`}
        >
          Delete
        </button>
      )}
    </div>
  );
}

Buttons.propTypes = { saving: PropTypes.bool, onCancel: PropTypes.func.isRequired, onDelete: PropTypes.func };

function AddButton({ label, onClick }) {
  return (
    <button type="button" onClick={onClick} className="flex items-center gap-1 self-start text-sm font-bold text-sky-400">
      <AddIcon fontSize="small" /> {label}
    </button>
  );
}

AddButton.propTypes = { label: PropTypes.string.isRequired, onClick: PropTypes.func.isRequired };

function ChallengeForm({ challenge, park, lists, onDone }) {
  const { save, remove, saving, error } = useContent("challenges");
  const [form, setForm] = useState({
    title: challenge?.title || "",
    description: challenge?.description || "",
    reward: challenge?.reward ?? 1,
    list_from: challenge?.list_from || "",
    list_count: challenge?.list_count ?? 1,
  });
  const set = (field) => (e) => setForm({ ...form, [field]: e.target.value });
  const submit = (e) => {
    e.preventDefault();
    save(challenge?.id, { challenge: { ...form, park } }, onDone);
  };

  return (
    <form onSubmit={submit} className={`${card} flex flex-col gap-2 ring-1 ring-sky-500`}>
      <input className={input} placeholder="Title" value={form.title} onChange={set("title")} required />
      <textarea
        className={input}
        rows={3}
        placeholder="What the team has to do"
        value={form.description}
        onChange={set("description")}
      />
      <label className="flex items-center gap-2 text-sm text-slate-300">
        Coins
        <input type="number" min={1} max={10} className={`${input} w-20`} value={form.reward} onChange={set("reward")} />
      </label>
      <label className="flex flex-wrap items-center gap-2 text-sm text-slate-300">
        Deal from list
        <select className={`${input} w-auto`} value={form.list_from} onChange={set("list_from")}>
          <option value="">None</option>
          {lists.map((name) => (
            <option key={name} value={name}>
              {name}
            </option>
          ))}
        </select>
        {form.list_from && (
          <>
            count
            <input type="number" min={1} className={`${input} w-20`} value={form.list_count} onChange={set("list_count")} />
          </>
        )}
      </label>
      {error && <p className="text-sm text-red-300">{error}</p>}
      <Buttons saving={saving} onCancel={onDone} onDelete={challenge && (() => remove(challenge.id, onDone))} />
    </form>
  );
}

ChallengeForm.propTypes = {
  challenge: PropTypes.object,
  park: PropTypes.string.isRequired,
  lists: PropTypes.arrayOf(PropTypes.string).isRequired,
  onDone: PropTypes.func.isRequired,
};

function HandChallenges({ data }) {
  const [editing, setEditing] = useState(null); // an id, or "new"
  const lists = [...data.lists.map((l) => l.name), ...data.photo_lists].sort();
  const done = () => setEditing(null);

  return (
    <div className="flex flex-col gap-2">
      {editing === "new" ? (
        <ChallengeForm park={data.park} lists={lists} onDone={done} />
      ) : (
        <AddButton label="Add a challenge" onClick={() => setEditing("new")} />
      )}
      {data.challenges.length === 0 && <p className="text-sm text-slate-400">No challenges here yet.</p>}
      {data.challenges.map((c) =>
        editing === c.id ? (
          <ChallengeForm key={c.id} challenge={c} park={data.park} lists={lists} onDone={done} />
        ) : (
          <button key={c.id} type="button" onClick={() => setEditing(c.id)} className={`${card} text-left`}>
            <div className="flex items-start justify-between gap-2">
              <span className="font-bold">{c.title}</span>
              <span className="shrink-0 text-sm font-bold text-amber-300">{c.reward} coins</span>
            </div>
            {c.description && <p className="text-sm text-slate-300">{c.description}</p>}
            {c.list_from && (
              <p className="mt-1 text-xs text-slate-500">
                Deals {c.list_count} from {c.list_from}
              </p>
            )}
          </button>
        ),
      )}
    </div>
  );
}

HandChallenges.propTypes = { data: PropTypes.object.isRequired };

function ClaimForm({ claim, park, area, onDone }) {
  const { save, remove, saving, error } = useContent("claim_challenges");
  const [title, setTitle] = useState(claim?.title || "");
  const [description, setDescription] = useState(claim?.description || "");
  const submit = (e) => {
    e.preventDefault();
    save(claim?.id, { claim: { park, area, title, description } }, onDone);
  };

  return (
    <form onSubmit={submit} className={`${card} flex flex-col gap-2 ring-1 ring-sky-500`}>
      <input className={input} placeholder="Title" value={title} onChange={(e) => setTitle(e.target.value)} required />
      <textarea
        className={input}
        rows={2}
        placeholder="What to touch"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
      />
      {error && <p className="text-sm text-red-300">{error}</p>}
      <Buttons saving={saving} onCancel={onDone} onDelete={claim && (() => remove(claim.id, onDone))} />
    </form>
  );
}

ClaimForm.propTypes = {
  claim: PropTypes.object,
  park: PropTypes.string.isRequired,
  area: PropTypes.string.isRequired,
  onDone: PropTypes.func.isRequired,
};

function ClaimChallenges({ data }) {
  const [editing, setEditing] = useState(null); // an id, or "new:<area>"
  const done = () => setEditing(null);
  if (data.areas.length === 0) {
    return <p className="text-sm text-slate-400">Pick a park with a game board to edit its claim challenges.</p>;
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-slate-400">
        To claim an unclaimed area, the team does one of its cards there. With more than one card, each try draws the next.
      </p>
      {data.areas.map((area) => {
        const cards = data.claims.filter((c) => c.area === area);
        return (
          <section key={area} className="flex flex-col gap-2">
            <h2 className="font-bold">{area}</h2>
            {cards.length === 0 && <p className="text-xs text-slate-500">No card yet: the stand-in is a group photo there.</p>}
            {cards.map((c) =>
              editing === c.id ? (
                <ClaimForm key={c.id} claim={c} park={data.park} area={area} onDone={done} />
              ) : (
                <button key={c.id} type="button" onClick={() => setEditing(c.id)} className={`${card} text-left`}>
                  <span className="font-bold">{c.title}</span>
                  {c.description && <p className="text-sm text-slate-300">{c.description}</p>}
                </button>
              ),
            )}
            {editing === `new:${area}` ? (
              <ClaimForm park={data.park} area={area} onDone={done} />
            ) : (
              <AddButton label="Add a card" onClick={() => setEditing(`new:${area}`)} />
            )}
          </section>
        );
      })}
    </div>
  );
}

ClaimChallenges.propTypes = { data: PropTypes.object.isRequired };

function ListForm({ list, onDone }) {
  const { save, remove, saving, error } = useContent("challenge_lists");
  const [name, setName] = useState(list?.name || "");
  const [items, setItems] = useState((list?.items || []).join("\n"));
  const submit = (e) => {
    e.preventDefault();
    save(list?.id, { list: { name, items: items.split("\n") } }, onDone);
  };

  return (
    <form onSubmit={submit} className={`${card} flex flex-col gap-2 ring-1 ring-sky-500`}>
      <input className={input} placeholder="name_like_this" value={name} onChange={(e) => setName(e.target.value)} required />
      <label className="text-sm text-slate-300">
        One item per line
        <textarea className={`${input} mt-1`} rows={10} value={items} onChange={(e) => setItems(e.target.value)} />
      </label>
      {error && <p className="text-sm text-red-300">{error}</p>}
      <Buttons saving={saving} onCancel={onDone} onDelete={list && (() => remove(list.id, onDone))} />
    </form>
  );
}

ListForm.propTypes = { list: PropTypes.object, onDone: PropTypes.func.isRequired };

function Lists({ data }) {
  const [editing, setEditing] = useState(null);
  const done = () => setEditing(null);

  return (
    <div className="flex flex-col gap-2">
      <p className="text-sm text-slate-400">
        A challenge can deal a few random items from a list with each card. Lists are shared by every park.
      </p>
      {editing === "new" ? <ListForm onDone={done} /> : <AddButton label="Add a list" onClick={() => setEditing("new")} />}
      {data.lists.map((l) =>
        editing === l.id ? (
          <ListForm key={l.id} list={l} onDone={done} />
        ) : (
          <button key={l.id} type="button" onClick={() => setEditing(l.id)} className={`${card} text-left`}>
            <div className="flex justify-between gap-2">
              <span className="font-bold">{l.name}</span>
              <span className="shrink-0 text-sm text-slate-400">{l.items.length} items</span>
            </div>
            <p className="truncate text-sm text-slate-300">{l.items.join(" · ")}</p>
            {l.used_by.length > 0 && <p className="mt-1 text-xs text-slate-500">Used by {l.used_by.join(", ")}</p>}
          </button>
        ),
      )}
      {data.photo_lists.length > 0 && (
        <p className="mt-2 text-xs text-slate-500">
          Per-park lists ({data.photo_lists.join(", ")}) are still edited in the files.
        </p>
      )}
    </div>
  );
}

Lists.propTypes = { data: PropTypes.object.isRequired };

// Add, edit and delete the park game's challenges. They're saved in the
// database; new entries in the repo's files are added on top.
function ChallengeEditor() {
  const [params, setParams] = useSearchParams();
  const tab = TABS[params.get("tab")] ? params.get("tab") : "hand";
  const park = params.get("park") || "Magic Kingdom";
  const { data, error } = useFetchGameContentQuery(park);
  const go = (changes) => setParams({ tab, park, ...changes });

  return (
    <div className="flex min-h-screen flex-col gap-4 bg-slate-950 p-4 pb-[calc(2.5rem+env(safe-area-inset-bottom))] text-white">
      <div className="flex items-center gap-2">
        <Link to="/game/settings" className="text-sky-400" aria-label="Back to game settings">
          <ArrowBackIcon />
        </Link>
        <h1 className="text-2xl font-black">Challenges</h1>
        <a href={`${API_URL}/game_content/export`} className="ml-auto text-sm font-bold text-sky-400">
          Export
        </a>
      </div>

      <div className="flex gap-1 rounded-xl bg-slate-800 p-1">
        {Object.entries(TABS).map(([key, label]) => (
          <button
            key={key}
            type="button"
            onClick={() => go({ tab: key })}
            className={`flex-1 rounded-lg px-2 py-1.5 text-sm font-bold ${tab === key ? "bg-sky-600" : "text-slate-300"}`}
          >
            {label}
          </button>
        ))}
      </div>

      {tab !== "lists" && data && (
        <select className={input} value={data.park} onChange={(e) => go({ park: e.target.value })}>
          {data.parks.map((p) => (
            <option key={p} value={p}>
              {p === "anywhere" ? "Any park" : p}
            </option>
          ))}
        </select>
      )}

      {error && <p className="text-red-300">{errorMessage(error)}</p>}
      {!data && !error && <p className="text-slate-400">Loading…</p>}
      {data && tab === "hand" && <HandChallenges key={data.park} data={data} />}
      {data && tab === "claims" && <ClaimChallenges key={data.park} data={data} />}
      {data && tab === "lists" && <Lists data={data} />}
    </div>
  );
}

export default ChallengeEditor;
