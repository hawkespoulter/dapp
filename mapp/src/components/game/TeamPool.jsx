import PropTypes from "prop-types";
import PaidIcon from "@mui/icons-material/Paid";

// The team's shared coins, spent on areas and power-ups.
function TeamPool({ game }) {
  return (
    <div className="flex items-center gap-3 bg-slate-900 px-3 py-2 text-white">
      <span className="flex items-center gap-1 font-bold" title="Team coins">
        <PaidIcon sx={{ fontSize: 18 }} className="text-amber-300" /> {game.coins}
      </span>
    </div>
  );
}

export default TeamPool;

TeamPool.propTypes = { game: PropTypes.object.isRequired };
