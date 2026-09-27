import { useState } from "react";
import PropTypes from "prop-types";
import { useStartGameMutation } from "~/store/apis/gameApi";
import { errorMessage } from "./playerStorage";
import { villainColor } from "./boardLayout";

function Lobby({ state }) {
  const { game, villain, players, me } = state;
  const [startGame, { isLoading, error }] = useStartGameMutation();
  const [copied, setCopied] = useState(false);

  const share = async () => {
    const url = `${window.location.origin}/game/${game.code}`;
    try {
      if (navigator.share) {
        await navigator.share({ title: "Join my park game", text: `Game code ${game.code}`, url });
      } else {
        await navigator.clipboard.writeText(url);
        setCopied(true);
      }
    } catch {
      // share sheet dismissed
    }
  };

  return (
    <div className="flex min-h-screen flex-col gap-4 bg-slate-950 p-4 text-white">
      <div className="rounded-xl bg-slate-800 p-4 text-center">
        <p className="text-xs uppercase tracking-wide text-slate-400">Game code</p>
        <p className="text-4xl font-black tracking-[0.3em]">{game.code}</p>
        <button className="mt-3 rounded-lg bg-sky-600 px-4 py-2 text-sm font-bold" onClick={share}>
          {copied ? "Link copied!" : "Invite players"}
        </button>
      </div>

      <div className="rounded-xl bg-slate-800 p-4">
        <div className="flex items-center gap-2">
          <span className="h-3 w-3 rounded-full" style={{ backgroundColor: villainColor(villain.key) }} />
          <h2 className="text-xl font-bold">{villain.name}</h2>
        </div>
        <ul className="mt-2 list-disc pl-5 text-sm text-slate-300">
          {villain.rules.map((rule) => (
            <li key={rule}>{rule}</li>
          ))}
        </ul>
        <p className="mt-3 text-sm text-slate-400">
          {game.park} · {game.preset_label} · villain moves every {game.tick_minutes} min
        </p>
      </div>

      <div className="rounded-xl bg-slate-800 p-4">
        <h2 className="text-sm font-bold uppercase tracking-wide text-slate-400">Villain rules</h2>
        <ul className="mt-2 list-disc pl-5 text-sm text-slate-300">
          {state.villain_rules.map((rule) => (
            <li key={rule}>{rule}</li>
          ))}
        </ul>
      </div>

      <div className="rounded-xl bg-slate-800 p-4">
        <h2 className="mb-2 text-xs font-bold uppercase tracking-wide text-slate-400">Players</h2>
        <ul className="flex flex-col gap-1">
          {players.map((p) => (
            <li key={p.id}>
              {p.name}
              {p.host && <span className="text-slate-400"> (host)</span>}
              {p.id === me?.id && <span className="text-sky-400"> · you</span>}
            </li>
          ))}
        </ul>
      </div>

      {error && <p className="text-sm text-red-300">{errorMessage(error)}</p>}
      {me?.host ? (
        <button
          className="rounded-xl bg-emerald-600 py-3 text-lg font-bold disabled:opacity-40"
          disabled={isLoading}
          onClick={() => startGame({ code: game.code })}
        >
          Start the game
        </button>
      ) : (
        <p className="text-center text-slate-400">Waiting for the host to start…</p>
      )}
    </div>
  );
}

export default Lobby;

Lobby.propTypes = { state: PropTypes.object.isRequired };
