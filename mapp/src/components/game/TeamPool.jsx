import PropTypes from "prop-types";
import PaidIcon from "@mui/icons-material/Paid";
import BoltIcon from "@mui/icons-material/Bolt";

// The team's shared coins and influence stash. Buying happens in the Store.
function TeamPool({ game }) {
  return (
    <div className="flex items-center gap-3 bg-slate-900 px-3 py-2 text-white">
      <span className="flex items-center gap-1 font-bold" title="Team coins">
        <PaidIcon sx={{ fontSize: 18 }} className="text-amber-300" /> {game.coins}
      </span>
      <span className="flex items-center gap-1 font-bold" title="Team influence">
        <BoltIcon sx={{ fontSize: 18 }} className="text-sky-400" /> {game.influence_stash}
      </span>
    </div>
  );
}

export default TeamPool;

TeamPool.propTypes = { game: PropTypes.object.isRequired };
