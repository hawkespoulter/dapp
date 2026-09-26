// Remembers which games this phone has joined, so a refresh or a new tab
// drops you back into the game. Storage can be unavailable (private mode),
// so every access is guarded.
const KEY = "parkGame.players";

function readAll() {
  try {
    return JSON.parse(localStorage.getItem(KEY)) || {};
  } catch {
    return {};
  }
}

export function getPlayerToken(code) {
  return readAll()[code?.toUpperCase()]?.token;
}

export function savePlayer(code, token, name, park) {
  const all = readAll();
  all[code.toUpperCase()] = { token, name, park, savedAt: Date.now() };
  try {
    localStorage.setItem(KEY, JSON.stringify(all));
  } catch {
    // the game still works for this session without storage
  }
}

export function forgetGame(code) {
  const all = readAll();
  delete all[code.toUpperCase()];
  try {
    localStorage.setItem(KEY, JSON.stringify(all));
  } catch {
    // nothing to forget if storage is unavailable
  }
}

export function savedGames() {
  return Object.entries(readAll())
    .map(([code, info]) => ({ code, ...info }))
    .sort((a, b) => b.savedAt - a.savedAt);
}

export function errorMessage(error) {
  return error?.data?.error || error?.error || "Something went wrong";
}
