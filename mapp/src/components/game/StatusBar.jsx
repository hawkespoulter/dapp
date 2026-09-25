import { useEffect } from "react";
import PropTypes from "prop-types";
import useCountdown, { formatDuration } from "./useCountdown";
import { villainColor } from "./boardLayout";

function Stat({ label, value, warn }) {
  return (
    <div className="flex flex-col items-center">
      <span className={`text-sm font-bold ${warn ? "text-red-400" : "text-white"}`}>{value}</span>
      <span className="text-[10px] uppercase tracking-wide text-slate-400">{label}</span>
    </div>
  );
}

function StatusBar({ game, villain, onVillainDue }) {
  const nextMove = useCountdown(game.next_tick_at, game.server_time);
  const timeLeft = useCountdown(game.ends_at, game.server_time);

  // Ask the server to play the villain's turn as soon as it comes due.
  const due = nextMove === 0 || timeLeft === 0;
  useEffect(() => {
    if (due) onVillainDue();
  }, [due, onVillainDue]);

  return (
    <div className="bg-slate-900 px-3 py-2">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="h-3 w-3 rounded-full" style={{ backgroundColor: villainColor(villain.key) }} />
          <span className="font-bold text-white">{villain.name}</span>
        </div>
        <span className="text-xs text-slate-400">Game {game.code}</span>
      </div>
      <div className="mt-2 grid grid-cols-4 gap-1">
        <Stat label="Villain moves" value={formatDuration(nextMove)} warn={nextMove != null && nextMove < 60} />
        <Stat label="Cards/turn" value={game.villain_rate} />
        <Stat label="Outbreaks" value={`${game.outbreaks}/${game.outbreak_limit}`} warn={game.outbreak_limit - game.outbreaks <= 1} />
        <Stat label="Time left" value={formatDuration(timeLeft)} />
      </div>
    </div>
  );
}

export default StatusBar;

StatusBar.propTypes = {
  game: PropTypes.object.isRequired,
  villain: PropTypes.object.isRequired,
  onVillainDue: PropTypes.func.isRequired,
};
Stat.propTypes = { label: PropTypes.string, value: PropTypes.node, warn: PropTypes.bool };
