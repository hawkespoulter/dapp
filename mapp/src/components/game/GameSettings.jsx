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

// Edit the game's balance: the defaults for new games.
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

function Record({ rows, record }) {
  return (
    <div className={section}>
      <h2 className="mb-2 text-lg font-bold">Results so far</h2>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-xs uppercase text-slate-400">
            <th className="text-left font-normal">Difficulty</th>
            {RESULTS.map((r) => (
              <th key={r} className={`font-normal ${RESULT_STYLES[r]}`}>{r}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((p) => (
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

function ChallengeFile({ challenges, claims }) {
  const counts = Object.entries(challenges.counts);
  const claimCounts = Object.entries(claims?.counts || {});
  return (
    <Link to="/game/challenges" className={`${section} block`}>
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-bold">Challenges</h2>
        <span className="flex items-center gap-1 text-sm text-sky-400">
          Edit <ChevronRightIcon />
        </span>
      </div>
      <p className="text-sm text-slate-400">
        Hand: {counts.map(([group, n]) => `${n} ${group}`).join(" · ") || "none yet"}
      </p>
      <p className="text-sm text-slate-400">
        Claim: {claimCounts.map(([park, n]) => `${n} ${park}`).join(" · ") || "none yet"}
      </p>
      {challenges.problem && (
        <pre className="mt-2 whitespace-pre-wrap rounded-lg bg-red-950 p-2 text-xs text-red-200">
          {challenges.problem}
          {"\n\n"}These entries from the files weren&apos;t added yet. Everything else is in play.
        </pre>
      )}
    </Link>
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

  if (isLoading) return <div className="min-h-screen bg-slate-950 p-4 text-white">Loading…</div>;
  if (error) return <div className="min-h-screen bg-slate-950 p-4 text-red-300">{errorMessage(error)}</div>;

  const current = data.presets[0];

  return (
    <div className="flex min-h-screen flex-col gap-4 bg-slate-950 p-4 text-white">
      <div className="flex items-center gap-2">
        <Link to="/game" className="text-sky-400" aria-label="Back">
          <ArrowBackIcon />
        </Link>
        <h1 className="text-2xl font-black">Game settings</h1>
      </div>

      <PresetForm key={current.key} preset={current} />

      <ChallengeFile challenges={data.challenges} claims={data.claims} />
      <Record rows={data.record_rows} record={data.record} />
      <FinishedGamesLink count={data.finished_count} />
    </div>
  );
}

export default GameSettings;

PresetForm.propTypes = { preset: PropTypes.object.isRequired };
Record.propTypes = { rows: PropTypes.array.isRequired, record: PropTypes.object.isRequired };
FinishedGamesLink.propTypes = { count: PropTypes.number.isRequired };
ChallengeFile.propTypes = { challenges: PropTypes.object.isRequired, claims: PropTypes.object };
