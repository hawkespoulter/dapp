import { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { errorMessage } from "./playerStorage";

const input = "w-24 rounded-lg bg-slate-900 px-3 py-2 text-right text-white";

// A form for balance settings: number, time and on/off fields. Values are
// kept as typed and checked by the server on save. `onSave` and `onReset`
// return promises that reject with the server's error.
function SettingsForm({ id, fields, settings, defaults, note, onSave, onReset }) {
  const [values, setValues] = useState(settings);
  const [saved, setSaved] = useState(false);
  const [confirmReset, setConfirmReset] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => setValues(settings), [settings]);

  const changed = fields.some((f) => String(values[f.key]) !== String(settings[f.key]));

  const run = async (promise) => {
    setBusy(true);
    setError(null);
    try {
      await promise;
      return true;
    } catch (e) {
      setError(errorMessage(e));
      return false;
    } finally {
      setBusy(false);
    }
  };

  const save = async () => {
    const edits = Object.fromEntries(fields.map((f) => [f.key, values[f.key]]));
    if (await run(onSave(edits))) {
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    }
  };

  const reset = () => {
    if (!confirmReset) return setConfirmReset(true);
    setConfirmReset(false);
    run(onReset());
  };

  const edit = (field, value) => {
    setError(null);
    setValues({ ...values, [field]: value });
  };

  return (
    <div>
      <ul className="flex flex-col gap-3">
        {fields.map((field) => {
          const isDefault = !defaults || String(settings[field.key]) === String(defaults[field.key]);
          return (
            <li key={field.key} className="flex items-center justify-between gap-3">
              <label className="text-sm" htmlFor={`${id}-${field.key}`}>
                {field.label}
                {!isDefault && (
                  <span className="block text-xs text-slate-500">
                    default {field.boolean ? (defaults[field.key] ? "on" : "off") : defaults[field.key]}
                  </span>
                )}
              </label>
              {field.boolean ? (
                <input
                  id={`${id}-${field.key}`}
                  className="h-6 w-6 shrink-0 accent-emerald-500"
                  type="checkbox"
                  checked={values[field.key] === true}
                  onChange={(e) => edit(field.key, e.target.checked)}
                />
              ) : (
                <input
                  id={`${id}-${field.key}`}
                  className={input}
                  type={field.time ? "time" : "number"}
                  inputMode={field.time ? undefined : "numeric"}
                  min={field.min}
                  max={field.max}
                  value={values[field.key] ?? ""}
                  onChange={(e) => edit(field.key, e.target.value)}
                />
              )}
            </li>
          );
        })}
      </ul>

      {error && <p className="mt-3 text-sm text-red-300">{error}</p>}
      <div className="mt-4 flex gap-2">
        <button className="flex-1 rounded-lg bg-emerald-600 py-2 font-bold disabled:opacity-40" disabled={busy || !changed} onClick={save}>
          {saved ? "Saved" : "Save"}
        </button>
        {onReset && (
          <button className="rounded-lg bg-slate-700 px-4 py-2 text-sm disabled:opacity-40" disabled={busy} onClick={reset}>
            {confirmReset ? "Tap again to reset" : "Reset to defaults"}
          </button>
        )}
      </div>
      {note && <p className="mt-2 text-xs text-slate-500">{note}</p>}
    </div>
  );
}

export default SettingsForm;

SettingsForm.propTypes = {
  id: PropTypes.string.isRequired,
  fields: PropTypes.array.isRequired,
  settings: PropTypes.object.isRequired,
  defaults: PropTypes.object,
  note: PropTypes.string,
  onSave: PropTypes.func.isRequired,
  onReset: PropTypes.func,
};
