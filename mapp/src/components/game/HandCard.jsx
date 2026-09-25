import PropTypes from "prop-types";
import AttractionsIcon from "@mui/icons-material/Attractions";
import TheaterComedyIcon from "@mui/icons-material/TheaterComedy";
import RestaurantIcon from "@mui/icons-material/Restaurant";
import PhotoCameraIcon from "@mui/icons-material/PhotoCamera";
import SearchIcon from "@mui/icons-material/Search";
import GroupsIcon from "@mui/icons-material/Groups";
import QuizIcon from "@mui/icons-material/Quiz";
import { previewChallenge } from "./gameRules";

const CATEGORY_ICONS = {
  ride: AttractionsIcon,
  show: TheaterComedyIcon,
  food: RestaurantIcon,
  photo: PhotoCameraIcon,
  find: SearchIcon,
  social: GroupsIcon,
  trivia: QuizIcon,
};

function HandCard({ card, state, busy, onComplete, onFail }) {
  const Icon = CATEGORY_ICONS[card.category] || SearchIcon;
  const preview = previewChallenge(state, card);

  return (
    <div className="rounded-xl bg-slate-800 p-3 text-white shadow">
      <div className="flex items-start gap-2">
        <Icon className="mt-0.5 text-sky-400" fontSize="small" />
        <div className="flex-1">
          <div className="flex items-center justify-between gap-2">
            <h3 className="font-bold leading-tight">{card.title}</h3>
            <span className="whitespace-nowrap text-sm text-amber-300" title={`Difficulty ${card.difficulty}`}>
              {"★".repeat(card.difficulty)}
              <span className="text-slate-600">{"★".repeat(3 - card.difficulty)}</span>
            </span>
          </div>
          {card.description && <p className="mt-1 text-sm text-slate-300">{card.description}</p>}
          <p className="mt-1 text-xs text-slate-400">{card.area || "Anywhere"}</p>
        </div>
      </div>
      <p className={`mt-2 text-xs font-semibold ${preview.ok ? "text-emerald-400" : "text-amber-400"}`}>{preview.text}</p>
      <div className="mt-2 flex gap-2">
        <button
          className="flex-1 rounded-lg bg-emerald-600 py-2 font-bold disabled:opacity-40"
          disabled={!preview.ok || busy}
          onClick={() => onComplete(card)}
        >
          Done
        </button>
        <button
          className="rounded-lg bg-slate-700 px-4 py-2 text-sm disabled:opacity-40"
          disabled={busy}
          onClick={() => onFail(card)}
        >
          Couldn&apos;t
        </button>
      </div>
    </div>
  );
}

export default HandCard;

HandCard.propTypes = {
  card: PropTypes.object.isRequired,
  state: PropTypes.object.isRequired,
  busy: PropTypes.bool,
  onComplete: PropTypes.func.isRequired,
  onFail: PropTypes.func.isRequired,
};
