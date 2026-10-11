import PropTypes from "prop-types";
import PowerUps from "./PowerUps";

// What the team can spend its coins on besides placing them on the map.
function Store({ state, area, busy, onUsePower }) {
  return (
    <div className="flex flex-col gap-2">
      <h3 className="text-sm font-bold text-slate-200">Power-ups</h3>
      <PowerUps state={state} area={area} busy={busy} onUse={onUsePower} />
    </div>
  );
}

export default Store;

Store.propTypes = {
  state: PropTypes.object.isRequired,
  area: PropTypes.object,
  busy: PropTypes.bool,
  onUsePower: PropTypes.func.isRequired,
};
