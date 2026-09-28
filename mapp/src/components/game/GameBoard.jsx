import { useEffect, useState } from "react";
import PropTypes from "prop-types";
import UndoIcon from "@mui/icons-material/Undo";
import GameMap from "./GameMap";
import StatusBar from "./StatusBar";
import TeamPool from "./TeamPool";
import AreaPanel from "./AreaPanel";
import HandCard from "./HandCard";
import AnswerPopup from "./AnswerPopup";
import VillainTurnReplay from "./VillainTurnReplay";
import Store from "./Store";
import ForecastPopup from "./ForecastPopup";
import SettingsForm from "./SettingsForm";
import useUnseenVillainTurns from "./useUnseenVillainTurns";
import { errorMessage } from "./playerStorage";
import {
  useBuyInfluenceMutation,
  useCompleteChallengeMutation,
  useFailChallengeMutation,
  useForceVillainTurnMutation,
  useUsePowerUpMutation,
  useForecastDiscardMutation,
  useUpdateBalanceMutation,
  useCompleteClaimMutation,
  useFailClaimMutation,
  usePlaceInfluenceMutation,
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
  const [answers, setAnswers] = useState(null);
  const [newTurns, markTurnsSeen] = useUnseenVillainTurns(state);

  const [complete, completeStatus] = useCompleteChallengeMutation();
  const [fail, failStatus] = useFailChallengeMutation();
  const [buy, buyStatus] = useBuyInfluenceMutation();
  const [place, placeStatus] = usePlaceInfluenceMutation();
  const [undo, undoStatus] = useUndoChallengeMutation();
  const [forceTurn, forceTurnStatus] = useForceVillainTurnMutation();
  const [buyPower, powerStatus] = useUsePowerUpMutation();
  const [forecastDiscard, forecastStatus] = useForecastDiscardMutation();
  const [updateBalance] = useUpdateBalanceMutation();
  const [completeClaim, completeClaimStatus] = useCompleteClaimMutation();
  const [failClaim, failClaimStatus] = useFailClaimMutation();
  const [showBalance, setShowBalance] = useState(false);
  const busy = [
    completeStatus,
    failStatus,
    buyStatus,
    placeStatus,
    undoStatus,
    forceTurnStatus,
    powerStatus,
    forecastStatus,
    completeClaimStatus,
    failClaimStatus,
  ].some((s) => s.isLoading);

  useEffect(() => {
    if (!error) return;
    const id = setTimeout(() => setError(null), 5000);
    return () => clearTimeout(id);
  }, [error]);

  const run = (promise) => promise.unwrap().catch((e) => setError(errorMessage(e)));
  const code = game.code;

  // Failing a photo card reveals where the photos were taken.
  const failCard = (card) => {
    const photos = (card.list || []).filter((item) => typeof item === "object");
    fail({ code, challengeId: card.id })
      .unwrap()
      .then(() => photos.length > 0 && setAnswers(photos))
      .catch((e) => setError(errorMessage(e)));
  };

  // Until someone taps the map, show one of the areas the team holds.
  const current = selected || areas.find((a) => a.owner === "players")?.area || areas[0].area;
  const currentArea = areas.find((a) => a.area === current);

  return (
    <div className="min-h-screen bg-slate-950 pb-10">
      {/* One solid background, extended up under the fixed navbar so no gap or
          seam shows the page behind it while scrolling. */}
      <div className="sticky top-[56px] z-40 bg-slate-900 shadow-lg before:absolute before:inset-x-0 before:bottom-full before:h-4 before:bg-slate-900 before:content-['']">
        <StatusBar game={game} villain={villain} onVillainDue={refetch} />
        <TeamPool game={game} />
      </div>

      <GameMap
        park={game.park}
        areas={areas}
        villainKey={villain.key}
        onSelect={setSelected}
      />

      <AreaPanel
        state={state}
        area={currentArea}
        busy={busy || !me}
        onPlace={(count) => run(place({ code, area: current, count }))}
        onClaim={(done) => run((done ? completeClaim : failClaim)({ code, area: current }))}
      />

      {error && (
        <div className="fixed inset-x-3 bottom-4 z-50 rounded-lg bg-red-900 px-3 py-2 text-sm text-red-100 shadow-lg">{error}</div>
      )}

      {me ? (
        <Section title="Your challenges">
          <div className="flex flex-col gap-3">
            {me.hand.map((card) => (
              <HandCard
                key={card.id}
                card={card}
                busy={busy}
                onComplete={(c) => run(complete({ code, challengeId: c.id }))}
                onFail={failCard}
              />
            ))}
          </div>
        </Section>
      ) : (
        <p className="px-3 pt-4 text-sm text-slate-400">You&apos;re watching this game. Join above to play.</p>
      )}

      {me && (
        <Section title="Store">
          <Store
            state={state}
            area={currentArea}
            busy={busy}
            onBuyInfluence={(count) => run(buy({ code, count }))}
            onUsePower={(power, area) => run(buyPower({ code, power, area }))}
          />
        </Section>
      )}

      <Section title="Team">
        <div className="flex flex-wrap gap-2">
          {players.map((p) => (
            <span key={p.id} className="rounded-full bg-slate-800 px-3 py-1 text-sm text-white">
              {p.name}
              <span className="text-slate-400"> · earned {p.coins}</span>
            </span>
          ))}
        </div>
      </Section>

      {newTurns.length > 0 && (
        <VillainTurnReplay turns={newTurns} villain={villain} areas={areas} park={game.park} onClose={markTurnsSeen} />
      )}
      {answers && <AnswerPopup photos={answers} onClose={() => setAnswers(null)} />}
      {state.powers?.forecast && (
        <ForecastPopup
          cards={state.powers.forecast}
          villain={villain}
          busy={busy}
          onDiscard={(index) => run(forecastDiscard({ code, index }))}
        />
      )}

      <Section title={`${villain.name}'s rules`}>
        <ul className="list-disc pl-5 text-sm text-slate-300">
          {villain.rules.map((rule) => (
            <li key={rule}>{rule}</li>
          ))}
        </ul>
      </Section>

      <Section title="Villain rules">
        <ul className="list-disc pl-5 text-sm text-slate-300">
          {state.villain_rules.map((rule) => (
            <li key={rule}>{rule}</li>
          ))}
        </ul>
      </Section>

      {me?.undo && (
        <div className="mx-3 mt-4 flex items-center gap-2 rounded-lg bg-slate-800 px-3 py-2 text-sm text-slate-300">
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

      {me && (
        <Section title="Balance">
          <button
            className="w-full rounded-lg border border-slate-700 py-2 text-sm text-slate-300"
            onClick={() => setShowBalance(!showBalance)}
          >
            {showBalance ? "Hide" : "Tweak this game's balance"}
          </button>
          {showBalance && (
            <div className="mt-3 rounded-xl bg-slate-800 p-4 text-white">
              <SettingsForm
                id={`game-${code}`}
                fields={state.balance.fields}
                settings={state.balance.settings}
                note="Changes this game right away. A new villain timer starts after the turn that's already scheduled."
                onSave={(settings) => updateBalance({ code, settings }).unwrap()}
              />
            </div>
          )}
        </Section>
      )}

      <Section title="Testing">
        <button
          className="w-full rounded-lg border border-slate-700 py-2 text-sm text-slate-300 disabled:opacity-40"
          disabled={busy}
          onClick={() => run(forceTurn({ code }))}
        >
          Make {villain.name} move now
        </button>
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
