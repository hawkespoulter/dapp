import { useCallback, useEffect, useState } from "react";
import PropTypes from "prop-types";
import { Link, useNavigate } from "react-router-dom";
import { useCreateGameMutation, useFetchGameParksQuery, useFetchGameQuery, useJoinGameMutation } from "~/store/apis/gameApi";
import { errorMessage, forgetGame, savePlayer, savedGames } from "./playerStorage";

const input = "w-full rounded-lg bg-slate-900 px-3 py-2 text-white placeholder-slate-500";
const label = "text-xs font-bold uppercase tracking-wide text-slate-400";

export function JoinForm({ initialCode = "" }) {
  const navigate = useNavigate();
  const [code, setCode] = useState(initialCode);
  const [name, setName] = useState("");
  const [joinGame, { isLoading, error }] = useJoinGameMutation();

  const submit = async (event) => {
    event.preventDefault();
    try {
      const { token, state } = await joinGame({ code: code.trim().toUpperCase(), name: name.trim() }).unwrap();
      savePlayer(state.game.code, token, name.trim(), state.game.park);
      navigate(`/game/${state.game.code}`);
    } catch {
      // shown below
    }
  };

  return (
    <form className="flex flex-col gap-3 rounded-xl bg-slate-800 p-4" onSubmit={submit}>
      <h2 className="text-lg font-bold">Join a game</h2>
      {!initialCode && (
        <input className={`${input} uppercase tracking-widest`} placeholder="Game code" value={code} maxLength={6} onChange={(e) => setCode(e.target.value)} />
      )}
      <input className={input} placeholder="Your name" value={name} maxLength={30} onChange={(e) => setName(e.target.value)} />
      {error && <p className="text-sm text-red-300">{errorMessage(error)}</p>}
      <button className="rounded-lg bg-sky-600 py-2 font-bold disabled:opacity-40" disabled={isLoading || !code.trim() || !name.trim()}>
        Join
      </button>
    </form>
  );
}

function NewGameForm() {
  const navigate = useNavigate();
  const { data } = useFetchGameParksQuery();
  const [createGame, { isLoading, error }] = useCreateGameMutation();
  const [name, setName] = useState("");
  const [park, setPark] = useState("");
  const [preset, setPreset] = useState("full_day");
  const [villainOnFail, setVillainOnFail] = useState(false);
  const [days, setDays] = useState(3);

  const parks = data?.parks || [];
  const chosenPark = park || parks[0]?.park;
  const villain = parks.find((p) => p.park === chosenPark)?.villain;

  const submit = async (event) => {
    event.preventDefault();
    const rules = { villain_on_fail: villainOnFail };
    if (preset === "multi_day") rules.days = days;
    try {
      const { token, state } = await createGame({ name: name.trim(), park: chosenPark, preset, rules }).unwrap();
      savePlayer(state.game.code, token, name.trim(), state.game.park);
      navigate(`/game/${state.game.code}`);
    } catch {
      // shown below
    }
  };

  return (
    <form className="flex flex-col gap-3 rounded-xl bg-slate-800 p-4" onSubmit={submit}>
      <h2 className="text-lg font-bold">New game</h2>
      <input className={input} placeholder="Your name" value={name} maxLength={30} onChange={(e) => setName(e.target.value)} />

      <label className={label}>
        Park
        <select className={`${input} mt-1`} value={chosenPark || ""} onChange={(e) => setPark(e.target.value)}>
          {parks.map((p) => (
            <option key={p.park} value={p.park}>{p.park}</option>
          ))}
        </select>
      </label>
      {villain && (
        <p className="text-sm text-slate-300">
          Villain: <span className="font-bold text-purple-300">{villain.name}</span> <span className="italic text-slate-400">— {villain.tagline}</span>
        </p>
      )}

      <div className={label}>Length</div>
      <div className="grid grid-cols-3 gap-2">
        {(data?.presets || []).map((p) => (
          <button
            type="button"
            key={p.key}
            className={`rounded-lg px-2 py-2 text-sm font-bold ${preset === p.key ? "bg-sky-600" : "bg-slate-900 text-slate-300"}`}
            onClick={() => setPreset(p.key)}
          >
            {p.label}
          </button>
        ))}
      </div>
      {preset === "multi_day" && (
        <label className={label}>
          Days (9am–9pm each day)
          <input className={`${input} mt-1`} type="number" min={2} max={7} value={days} onChange={(e) => setDays(Number(e.target.value))} />
        </label>
      )}

      <label className="flex items-center gap-2 text-sm text-slate-300">
        <input type="checkbox" checked={villainOnFail} onChange={(e) => setVillainOnFail(e.target.checked)} />
        Hard mode: the villain also moves when you fail a challenge
      </label>

      {error && <p className="text-sm text-red-300">{errorMessage(error)}</p>}
      <button className="rounded-lg bg-emerald-600 py-2 font-bold disabled:opacity-40" disabled={isLoading || !name.trim() || !chosenPark}>
        Create game
      </button>
    </form>
  );
}

const STATUS_LABELS = { lobby: "Waiting to start", active: "In progress", finished: "Finished" };

// A game this phone joined. Checks with the server and hides itself (and
// forgets the game) if the game is gone or this phone is no longer in it.
function SavedGame({ game, onGone }) {
  const { data, error } = useFetchGameQuery(game.code);
  const gone = error?.status === 404 || (data && !data.me);

  useEffect(() => {
    if (gone) onGone(game.code);
  }, [gone, game.code, onGone]);

  if (gone || !data) return null;

  return (
    <li>
      <Link className="flex items-center justify-between rounded-lg bg-slate-900 px-3 py-2" to={`/game/${game.code}`}>
        <span className="font-bold tracking-widest">{game.code}</span>
        <span className="text-right text-sm text-slate-400">
          {game.park} · {game.name}
          <span className={`block text-xs ${data.game.status === "active" ? "text-emerald-400" : ""}`}>
            {STATUS_LABELS[data.game.status]}
          </span>
        </span>
      </Link>
    </li>
  );
}

function GameHome() {
  const [saved, setSaved] = useState(() => savedGames().slice(0, 5));

  const onGone = useCallback((code) => {
    forgetGame(code);
    setSaved((games) => games.filter((g) => g.code !== code));
  }, []);

  return (
    <div className="flex min-h-screen flex-col gap-4 bg-slate-950 p-4 text-white">
      <div>
        <h1 className="text-2xl font-black">Park Takeover</h1>
        <p className="text-sm text-slate-400">Claim the park with real-life challenges before the villain does.</p>
      </div>
      {saved.length > 0 && (
        <div className="rounded-xl bg-slate-800 p-4">
          <h2 className="mb-2 text-lg font-bold">Your games</h2>
          <ul className="flex flex-col gap-2">
            {saved.map((g) => (
              <SavedGame key={g.code} game={g} onGone={onGone} />
            ))}
          </ul>
        </div>
      )}
      <NewGameForm />
      <JoinForm />
    </div>
  );
}

export default GameHome;

JoinForm.propTypes = { initialCode: PropTypes.string };
SavedGame.propTypes = { game: PropTypes.object.isRequired, onGone: PropTypes.func.isRequired };
