import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import IMAGES from "~/images/Images";
import { toCamelCase } from "~/constants.js";
import GameMap from "./GameMap";
import VillainTurnReplay from "./VillainTurnReplay";
import useUnseenVillainTurns from "./useUnseenVillainTurns";

const RESULTS = {
  gold: { title: "Gold!", logo: "Gold", filter: "none" },
  silver: { title: "Silver", logo: "Color", filter: "grayscale(1) brightness(1.3)" },
  bronze: { title: "Bronze", logo: "Bronze", filter: "none" },
  lost: { title: "Defeated", logo: "Grayscale", filter: "none" },
};

function GameOver({ state }) {
  const { game, villain, areas, events } = state;
  const result = RESULTS[game.result] || RESULTS.lost;
  const summary = events.find((e) => e.kind === "finished");
  // The turn that ended the game plays first, if this phone hasn't seen it.
  const [finalTurns, markTurnsSeen] = useUnseenVillainTurns(state);

  return (
    <div className="min-h-screen bg-slate-950 pb-10 text-white">
      <div className="flex flex-col items-center gap-2 p-6 text-center">
        <img
          className="h-28"
          src={IMAGES[`${toCamelCase(game.park)}${result.logo}`]}
          style={{ filter: result.filter }}
          alt={result.title}
        />
        <h1 className="text-3xl font-black">{result.title}</h1>
        {summary && <p className="text-slate-300">{summary.message}</p>}
        <Link to="/game" className="mt-2 rounded-lg bg-sky-600 px-4 py-2 font-bold">
          New game
        </Link>
      </div>
      <GameMap park={game.park} areas={areas} villainKey={villain.key} />
      {finalTurns.length > 0 && (
        <VillainTurnReplay
          turns={finalTurns}
          villain={villain}
          areas={areas}
          park={game.park}
          closeLabel="See the result"
          onClose={markTurnsSeen}
        />
      )}
    </div>
  );
}

export default GameOver;

GameOver.propTypes = { state: PropTypes.object.isRequired };
