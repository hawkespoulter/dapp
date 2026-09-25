import PropTypes from "prop-types";

const KIND_STYLES = {
  claimed: "text-sky-300",
  locked: "text-amber-300",
  takeover: "text-purple-300 font-semibold",
  outbreak: "text-red-400 font-semibold",
  rising: "text-red-300 font-semibold",
  influence: "text-purple-200",
  finished: "text-white font-bold",
  undo: "text-slate-400 italic",
};

const time = (iso) => new Date(iso).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });

function EventFeed({ events }) {
  return (
    <ul className="flex flex-col gap-1.5">
      {events.map((event) => (
        <li key={event.id} className="flex gap-2 text-sm">
          <span className="w-14 shrink-0 text-xs leading-5 text-slate-500">{time(event.occurred_at)}</span>
          <span className={`${KIND_STYLES[event.kind] || "text-slate-300"} ${event.data?.undone ? "line-through opacity-50" : ""}`}>
            {event.message}
          </span>
        </li>
      ))}
    </ul>
  );
}

export default EventFeed;

EventFeed.propTypes = { events: PropTypes.array.isRequired };
