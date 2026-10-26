import { useEffect } from "react";
import PropTypes from "prop-types";
import PauseIcon from "@mui/icons-material/Pause";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
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

function StatusBar({ game, villain, onVillainDue, onPause, onResume, busy }) {
  const paused = Boolean(game.paused_at);
  const nextMove = useCountdown(game.next_tick_at, game.server_time, game.paused_at);
  const timeLeft = useCountdown(game.ends_at, game.server_time, game.paused_at);

  // Ask the server to play the villain's turn as soon as it comes due.
  const due = !paused && (nextMove === 0 || timeLeft === 0);
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
        {onPause && !paused && (
          <button
            type="button"
            className="flex items-center gap-1 rounded-lg bg-slate-800 px-2 py-1 text-xs font-bold text-slate-300 disabled:opacity-40"
            disabled={busy}
            onClick={onPause}
          >
            <PauseIcon sx={{ fontSize: 16 }} /> Pause
          </button>
        )}
      </div>
      {paused && (
        <div className="mt-2 flex items-center gap-2 rounded-lg bg-amber-900/60 px-3 py-2 text-sm text-amber-100">
          <span className="flex-1">Paused. The villain and the clock are stopped.</span>
          {onResume && (
            <button
              type="button"
              className="flex items-center gap-1 rounded-lg bg-emerald-600 px-3 py-1.5 font-bold text-white disabled:opacity-40"
              disabled={busy}
              onClick={onResume}
            >
              <PlayArrowIcon sx={{ fontSize: 16 }} /> Resume
            </button>
          )}
        </div>
      )}
      <div className="mt-2 grid grid-cols-3 gap-1">
        <Stat label="Villain moves" value={formatDuration(nextMove)} warn={nextMove != null && nextMove < 60} />
        <Stat label="Cards/turn" value={game.villain_rate} />
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
  onPause: PropTypes.func,
  onResume: PropTypes.func,
  busy: PropTypes.bool,
};
Stat.propTypes = { label: PropTypes.string, value: PropTypes.node, warn: PropTypes.bool };
