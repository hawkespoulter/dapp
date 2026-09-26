import { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import {
  useFetchGameSettingsQuery,
  useResetGameSettingsMutation,
  useUpdateGameSettingsMutation,
} from "~/store/apis/gameApi";
import { errorMessage } from "./playerStorage";

const RESULT_STYLES = {
  gold: "text-amber-300",
  silver: "text-slate-200",
  bronze: "text-orange-400",
  lost: "text-red-400",
};
const RESULTS = ["gold", "silver", "bronze", "lost"];

const section = "rounded-xl bg-slate-800 p-4";
const input = "w-24 rounded-lg bg-slate-900 px-3 py-2 text-right text-white";

// Edit one preset's balance. Values are kept as typed and checked by the
// server on save.
function PresetForm({ preset }) {
  const [values, setValues] = useState(preset.settings);
  const [saved, setSaved] = useState(false);
  const [confirmReset, setConfirmReset] = useState(false);
  const [update, updateStatus] = useUpdateGameSettingsMutation();
  const [reset, resetStatus] = useResetGameSettingsMutation();

  useEffect(() => setValues(preset.settings), [preset.settings]);

  const changed = preset.fields.some((f) => String(values[f.key]) !== String(preset.settings[f.key]));
  const busy = updateStatus.isLoading || resetStatus.isLoading;
  const error = updateStatus.error || resetStatus.error;

  const save = async () => {
    const edits = Object.fromEntries(preset.fields.map((f) => [f.key, values[f.key]]));
    try {
      await update({ key: preset.key, settings: edits }).unwrap();
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {
      // shown below
    }
  };

  const doReset = () => {
    if (!confirmReset) return setConfirmReset(true);
    setConfirmReset(false);
    updateStatus.reset();
    reset(preset.key);
  };

  const edit = (field, value) => {
    updateStatus.reset();
    setValues({ ...values, [field]: value });
  };

  return (
    <div className={section}>
      <ul className="flex flex-col gap-3">
        {preset.fields.map((field) => {
          const isDefault = String(preset.settings[field.key]) === String(preset.defaults?.[field.key]);
          return (
            <li key={field.key} className="flex items-center justify-between gap-3">
              <label className="text-sm" htmlFor={`${preset.key}-${field.key}`}>
                {field.label}
                {!isDefault && preset.defaults && (
                  <span className="block text-xs text-slate-500">default {preset.defaults[field.key]}</span>
                )}
              </label>
              <input
                id={`${preset.key}-${field.key}`}
                className={input}
                type={field.time ? "time" : "number"}
                inputMode={field.time ? undefined : "numeric"}
                min={field.min}
                max={field.max}
                value={values[field.key] ?? ""}
                onChange={(e) => edit(field.key, e.target.value)}
              />
            </li>
          );
        })}
      </ul>

      {error && <p className="mt-3 text-sm text-red-300">{errorMessage(error)}</p>}
      <div className="mt-4 flex gap-2">
        <button className="flex-1 rounded-lg bg-emerald-600 py-2 font-bold disabled:opacity-40" disabled={busy || !changed} onClick={save}>
          {saved ? "Saved" : "Save"}
        </button>
        <button className="rounded-lg bg-slate-700 px-4 py-2 text-sm disabled:opacity-40" disabled={busy} onClick={doReset}>
          {confirmReset ? "Tap again to reset" : "Reset to defaults"}
        </button>
      </div>
      <p className="mt-2 text-xs text-slate-500">Changes apply to games created after you save.</p>
    </div>
  );
}

function Record({ presets, record }) {
  return (
    <div className={section}>
      <h2 className="mb-2 text-lg font-bold">Results so far</h2>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-xs uppercase text-slate-400">
            <th className="text-left font-normal">Length</th>
            {RESULTS.map((r) => (
              <th key={r} className={`font-normal ${RESULT_STYLES[r]}`}>{r}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {presets.map((p) => (
            <tr key={p.key}>
              <td className="py-1">{p.label}</td>
              {RESULTS.map((r) => (
                <td key={r} className="text-center">{record[p.key]?.[r] || 0}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ChallengeFile({ challenges }) {
  const counts = Object.entries(challenges.counts);
  return (
    <div className={section}>
      <h2 className="mb-1 text-lg font-bold">Challenges</h2>
      <p className="text-sm text-slate-400">
        From challenges.yml: {counts.map(([group, n]) => `${n} ${group}`).join(" · ") || "none yet"}
      </p>
      {challenges.problem && (
        <pre className="mt-2 whitespace-pre-wrap rounded-lg bg-red-950 p-2 text-xs text-red-200">
          {challenges.problem}
          {"\n\n"}Games keep using the last good version until this is fixed.
        </pre>
      )}
    </div>
  );
}

function FinishedGames({ games }) {
  return (
    <div className={section}>
      <h2 className="mb-2 text-lg font-bold">Finished games</h2>
      {games.length === 0 && <p className="text-sm text-slate-400">No finished games yet.</p>}
      <ul className="flex flex-col gap-2">
        {games.map((g) => (
          <li key={g.code}>
            <Link to={`/game/${g.code}`} className="block rounded-lg bg-slate-900 px-3 py-2">
              <div className="flex items-center justify-between">
                <span className="font-bold tracking-widest">{g.code}</span>
                <span className={`text-sm font-bold uppercase ${RESULT_STYLES[g.result]}`}>{g.result}</span>
              </div>
              <p className="text-xs text-slate-400">
                {g.finished_at && new Date(g.finished_at).toLocaleDateString([], { month: "short", day: "numeric" })} · {g.park} ·{" "}
                {g.preset_label} · {g.players.join(", ")}
              </p>
              {g.summary && <p className="mt-1 text-sm text-slate-300">{g.summary}</p>}
              <p className="mt-1 text-xs text-slate-500">
                Villain every {g.settings.tick_minutes} min · start strength {g.settings.starting_strength} ·{" "}
                {g.settings.influence_price} coin/influence
              </p>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

function GameSettings() {
  const { data, error, isLoading } = useFetchGameSettingsQuery();
  const [tab, setTab] = useState(null);

  if (isLoading) return <div className="min-h-screen bg-slate-950 p-4 text-white">Loading…</div>;
  if (error) return <div className="min-h-screen bg-slate-950 p-4 text-red-300">{errorMessage(error)}</div>;

  const current = data.presets.find((p) => p.key === tab) || data.presets[0];

  return (
    <div className="flex min-h-screen flex-col gap-4 bg-slate-950 p-4 text-white">
      <div className="flex items-center gap-2">
        <Link to="/game" className="text-sky-400" aria-label="Back">
          <ArrowBackIcon />
        </Link>
        <h1 className="text-2xl font-black">Game settings</h1>
      </div>

      <div className="grid grid-cols-3 gap-2">
        {data.presets.map((p) => (
          <button
            key={p.key}
            className={`rounded-lg px-2 py-2 text-sm font-bold ${p.key === current.key ? "bg-sky-600" : "bg-slate-800 text-slate-300"}`}
            onClick={() => setTab(p.key)}
          >
            {p.label}
          </button>
        ))}
      </div>
      <PresetForm key={current.key} preset={current} />

      <ChallengeFile challenges={data.challenges} />
      <Record presets={data.presets} record={data.record} />
      <FinishedGames games={data.finished_games} />
    </div>
  );
}

export default GameSettings;

PresetForm.propTypes = { preset: PropTypes.object.isRequired };
Record.propTypes = { presets: PropTypes.array.isRequired, record: PropTypes.object.isRequired };
FinishedGames.propTypes = { games: PropTypes.array.isRequired };
ChallengeFile.propTypes = { challenges: PropTypes.object.isRequired };
