import PropTypes from "prop-types";
import { Link, useSearchParams } from "react-router-dom";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import { useFetchFinishedGamesQuery } from "~/store/apis/gameApi";
import { errorMessage } from "./playerStorage";
import { RESULT_STYLES } from "./gameRules";


function FinishedGame({ game: g }) {
  return (
    <Link to={`/game/${g.code}`} className="block rounded-lg bg-slate-800 px-3 py-2">
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
  );
}

// Every finished game, newest first, a page at a time. The page lives in the
// URL (?page=2) so back and refresh keep your place.
function FinishedGames() {
  const [params, setParams] = useSearchParams();
  const requested = Math.max(1, parseInt(params.get("page"), 10) || 1);
  const { data, error, isFetching } = useFetchFinishedGamesQuery(requested);
  const goTo = (page) => {
    setParams(page > 1 ? { page: String(page) } : {});
    window.scrollTo(0, 0);
  };

  return (
    <div className="flex min-h-screen flex-col gap-4 bg-slate-950 p-4 text-white">
      <div className="flex items-center gap-2">
        <Link to="/game/settings" className="text-sky-400" aria-label="Back to game settings">
          <ArrowBackIcon />
        </Link>
        <h1 className="text-2xl font-black">Finished games</h1>
        {data && <span className="ml-auto text-sm text-slate-400">{data.total} total</span>}
      </div>

      {error && <p className="text-red-300">{errorMessage(error)}</p>}
      {!data && !error && <p className="text-slate-400">Loading…</p>}
      {data && data.total === 0 && <p className="text-sm text-slate-400">No finished games yet.</p>}

      {data && data.total > 0 && (
        <>
          <ul className={`flex flex-col gap-2 ${isFetching ? "opacity-60" : ""}`}>
            {data.games.map((g) => (
              <li key={g.code}>
                <FinishedGame game={g} />
              </li>
            ))}
          </ul>
          {data.pages > 1 && (
            <div className="flex items-center gap-2">
              <button
                className="rounded-lg bg-slate-800 px-4 py-2 text-sm font-bold disabled:opacity-40"
                disabled={data.page <= 1 || isFetching}
                onClick={() => goTo(data.page - 1)}
              >
                Newer
              </button>
              <span className="flex-1 text-center text-sm text-slate-400">
                Page {data.page} of {data.pages}
              </span>
              <button
                className="rounded-lg bg-slate-800 px-4 py-2 text-sm font-bold disabled:opacity-40"
                disabled={data.page >= data.pages || isFetching}
                onClick={() => goTo(data.page + 1)}
              >
                Older
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default FinishedGames;

FinishedGame.propTypes = { game: PropTypes.object.isRequired };
