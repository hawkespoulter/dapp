import { useState } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import {
  useFetchGameSettingsQuery,
  useResetGameSettingsMutation,
  useUpdateGameSettingsMutation,
} from "~/store/apis/gameApi";
import { errorMessage } from "./playerStorage";
import SettingsForm from "./SettingsForm";
import { RESULT_STYLES } from "./gameRules";
const RESULTS = ["gold", "silver", "bronze", "lost"];

const section = "rounded-xl bg-slate-800 p-4";

// Edit one preset's balance: the defaults for new games of that length.
function PresetForm({ preset }) {
  const [update] = useUpdateGameSettingsMutation();
  const [reset] = useResetGameSettingsMutation();

  return (
    <div className={section}>
      <SettingsForm
        id={preset.key}
        fields={preset.fields}
        settings={preset.settings}
        defaults={preset.defaults}
        note="Changes apply to games created after you save. To change a game in progress, use Balance at the bottom of its board."
        onSave={(edits) => update({ key: preset.key, settings: edits }).unwrap()}
        onReset={() => reset(preset.key).unwrap()}
      />
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
        Loaded: {counts.map(([group, n]) => `${n} ${group}`).join(" · ") || "none yet"}
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

function FinishedGamesLink({ count }) {
  return (
    <Link to="/game/finished" className={`${section} flex items-center justify-between`}>
      <span className="text-lg font-bold">Finished games</span>
      <span className="flex items-center gap-1 text-sm text-slate-400">
        {count} <ChevronRightIcon />
      </span>
    </Link>
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
      <FinishedGamesLink count={data.finished_count} />
    </div>
  );
}

export default GameSettings;

PresetForm.propTypes = { preset: PropTypes.object.isRequired };
Record.propTypes = { presets: PropTypes.array.isRequired, record: PropTypes.object.isRequired };
FinishedGamesLink.propTypes = { count: PropTypes.number.isRequired };
ChallengeFile.propTypes = { challenges: PropTypes.object.isRequired };
