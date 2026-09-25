import { useEffect, useState } from "react";
import PropTypes from "prop-types";
import UndoIcon from "@mui/icons-material/Undo";
import GameMap from "./GameMap";
import StatusBar from "./StatusBar";
import AreaPanel from "./AreaPanel";
import HandCard from "./HandCard";
import { errorMessage } from "./playerStorage";
import {
  useCompleteChallengeMutation,
  useFailChallengeMutation,
  useUndoChallengeMutation,
} from "~/store/apis/gameApi";

function Section({ title, children }) {
  return (
    <section className="px-3 pt-4">
      <h2 className="mb-2 text-xs font-bold uppercase tracking-wide text-slate-400">{title}</h2>
      {children}
    </section>
  );
}

function GameBoard({ state, refetch }) {
  const { game, villain, areas, players, me } = state;
  const [selected, setSelected] = useState(null);
  const [error, setError] = useState(null);

  const [complete, completeStatus] = useCompleteChallengeMutation();
  const [fail, failStatus] = useFailChallengeMutation();
  const [undo, undoStatus] = useUndoChallengeMutation();
  const busy = [completeStatus, failStatus, undoStatus].some((s) => s.isLoading);

  useEffect(() => {
    if (!error) return;
    const id = setTimeout(() => setError(null), 5000);
    return () => clearTimeout(id);
  }, [error]);

  const run = (promise) => promise.unwrap().catch((e) => setError(errorMessage(e)));
  const code = game.code;
  const selectedArea = areas.find((a) => a.area === selected);

  return (
    <div className="min-h-screen bg-slate-950 pb-10">
      <div className="sticky top-[56px] z-40 shadow-lg">
        <StatusBar game={game} villain={villain} onVillainDue={refetch} />
      </div>

      <GameMap park={game.park} areas={areas} villainKey={villain.key} onSelect={setSelected} />

      {selectedArea ? (
        <AreaPanel area={selectedArea} villainName={villain.name} />
      ) : (
        <p className="bg-slate-800 px-3 py-3 text-sm text-slate-300">Tap an area on the map to select it.</p>
      )}

      {error && <div className="mx-3 mt-3 rounded-lg bg-red-900/80 px-3 py-2 text-sm text-red-100">{error}</div>}

      {me?.undo && (
        <div className="mx-3 mt-3 flex items-center gap-2 rounded-lg bg-slate-800 px-3 py-2 text-sm text-slate-300">
          <span className="flex-1">{me.undo}</span>
          <button
            className="flex items-center gap-1 rounded-lg bg-slate-700 px-3 py-1.5 font-bold text-white disabled:opacity-40"
            disabled={busy}
            onClick={() => run(undo({ code }))}
          >
            <UndoIcon sx={{ fontSize: 16 }} /> Undo
          </button>
        </div>
      )}

      {me ? (
        <Section title={`Your challenges Â· ${me.coins} coins`}>
          <div className="flex flex-col gap-3">
            {me.hand.map((card) => (
              <HandCard
                key={card.id}
                card={card}
                state={state}
                selected={selected}
                busy={busy}
                onComplete={(c) => run(complete({ code, challengeId: c.id, area: c.area || selected }))}
                onFail={(c) => run(fail({ code, challengeId: c.id }))}
              />
            ))}
          </div>
        </Section>
      ) : (
        <p className="px-3 pt-4 text-sm text-slate-400">You&apos;re watching this game. Join above to play.</p>
      )}

      <Section title="Team">
        <div className="flex flex-wrap gap-2">
          {players.map((p) => (
            <span key={p.id} className="rounded-full bg-slate-800 px-3 py-1 text-sm text-white">
              {p.name}
              <span className="text-slate-400"> · {p.coins} coins</span>
            </span>
          ))}
        </div>
      </Section>

      <Section title={`${villain.name}'s rules`}>
        <ul className="list-disc pl-5 text-sm text-slate-300">
          {villain.rules.map((rule) => (
            <li key={rule}>{rule}</li>
          ))}
        </ul>
      </Section>
    </div>
  );
}

export default GameBoard;

GameBoard.propTypes = {
  state: PropTypes.object.isRequired,
  refetch: PropTypes.func.isRequired,
};
Section.propTypes = { title: PropTypes.string, children: PropTypes.node };
