import PropTypes from "prop-types";
import PaidIcon from "@mui/icons-material/Paid";
import BoltIcon from "@mui/icons-material/Bolt";

// The team's shared coins and influence stash, with buttons to buy influence.
function TeamPool({ game, busy, onBuy }) {
  const price = game.influence_price;
  const canBuy = Math.floor(game.coins / price);

  return (
    <div className="flex items-center gap-3 bg-slate-900 px-3 py-2 text-white">
      <span className="flex items-center gap-1 font-bold" title="Team coins">
        <PaidIcon sx={{ fontSize: 18 }} className="text-amber-300" /> {game.coins}
      </span>
      <span className="flex items-center gap-1 font-bold" title="Team influence">
        <BoltIcon sx={{ fontSize: 18 }} className="text-sky-400" /> {game.influence_stash}
      </span>
      <div className="ml-auto flex gap-2">
        <button
          className="rounded-lg bg-slate-700 px-3 py-1.5 text-sm font-bold disabled:opacity-40"
          disabled={busy || canBuy < 1}
          onClick={() => onBuy(1)}
        >
          Buy 1
        </button>
        <button
          className="rounded-lg bg-amber-500 px-3 py-1.5 text-sm font-bold text-slate-900 disabled:opacity-40"
          disabled={busy || canBuy < 2}
          onClick={() => onBuy(canBuy)}
        >
          Buy all{canBuy > 1 ? ` (${canBuy})` : ""}
        </button>
      </div>
    </div>
  );
}

export default TeamPool;

TeamPool.propTypes = {
  game: PropTypes.object.isRequired,
  busy: PropTypes.bool,
  onBuy: PropTypes.func.isRequired,
};
