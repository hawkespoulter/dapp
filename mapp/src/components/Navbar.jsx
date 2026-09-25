import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import FavoriteIcon from '@mui/icons-material/Favorite';
import FlagIcon from '@mui/icons-material/Flag';
import { Link } from "react-router-dom";

function Navbar() {
  return (
    <div className="flex flex-row gap-4 p-4 w-full top-0 fixed z-50 font-bold bg-slate-900 text-sky-400">
      <Link to="/">
        <EmojiEventsIcon />
      </Link>
      <Link to="/dateNight">
        <FavoriteIcon />
      </Link>
      <Link to="/game">
        <FlagIcon />
      </Link>
      <Link to="/attractions">Rides</Link>
      <Link to="/shows">Shows</Link>
      <Link to="/restaurants">Restaurants</Link>
    </div>
  );
}

export default Navbar;
