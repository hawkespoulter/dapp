import PropTypes from "prop-types";
import PaidIcon from "@mui/icons-material/Paid";
import BoltIcon from "@mui/icons-material/Bolt";
import PowerUps from "./PowerUps";

function Category({ title, children }) {
  return (
    <div className="flex flex-col gap-2">
      <h3 className="text-sm font-bold text-slate-200">{title}</h3>
      {children}
    </div>
  );
}

// Buying influence for the team stash, one at a time or with all the coins.
function Influence({ game, busy, onBuy }) {
  const price = game.influence_price;
  const canBuy = Math.floor(game.coins / price);
  return (
    <div className="rounded-xl bg-slate-800 p-3 text-white">
      <p className="flex items-center gap-1 text-sm text-slate-300">
        <BoltIcon sx={{ fontSize: 16 }} className="text-sky-400" />
        <span className="flex items-center gap-0.5 font-bold text-amber-300">
          <PaidIcon sx={{ fontSize: 16 }} />
          {price}
        </span>
        each, into the team stash to place on the map.
      </p>
      <div className="mt-2 flex gap-2">
        <button
          className="flex-1 rounded-lg bg-slate-700 py-2 text-sm font-bold disabled:opacity-40"
          disabled={busy || canBuy < 1}
          onClick={() => onBuy(1)}
        >
          Buy 1
        </button>
        <button
          className="flex-1 rounded-lg bg-amber-500 py-2 text-sm font-bold text-slate-900 disabled:opacity-40"
          disabled={busy || canBuy < 2}
          onClick={() => onBuy(canBuy)}
        >
          Buy all{canBuy > 1 ? ` (${canBuy})` : ""}
        </button>
      </div>
    </div>
  );
}

// Everything the team spends its coins on.
function Store({ state, area, busy, onBuyInfluence, onUsePower }) {
  return (
    <div className="flex flex-col gap-4">
      <Category title="Influence">
        <Influence game={state.game} busy={busy} onBuy={onBuyInfluence} />
      </Category>
      <Category title="Power-ups">
        <PowerUps state={state} area={area} busy={busy} onUse={onUsePower} />
      </Category>
    </div>
  );
}

export default Store;

Store.propTypes = {
  state: PropTypes.object.isRequired,
  area: PropTypes.object,
  busy: PropTypes.bool,
  onBuyInfluence: PropTypes.func.isRequired,
  onUsePower: PropTypes.func.isRequired,
};
Category.propTypes = { title: PropTypes.string.isRequired, children: PropTypes.node };
Influence.propTypes = { game: PropTypes.object.isRequired, busy: PropTypes.bool, onBuy: PropTypes.func.isRequired };
