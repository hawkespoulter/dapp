// Mirrors the server's challenge rules (app/services/games/actions.rb) so a
// card can say what it would do before you play it. The server still decides.
// Area cards count in their own area; "anywhere" cards in the selected one.
export function previewChallenge(state, card, selected) {
  const here = card.area || selected;
  if (!here) return { ok: false, text: "Select an area on the map" };

  const areas = Object.fromEntries(state.areas.map((a) => [a.area, a]));
  const area = areas[here];
  const villain = state.villain.name;

  if (card.difficulty < area.min_difficulty) {
    return { ok: false, text: `${villain} requires difficulty ${area.min_difficulty}+ here` };
  }
  if (area.owner === "villain" && !area.neighbors.some((n) => areas[n].owner === "players")) {
    return { ok: false, text: "Hold a neighboring area to attack here" };
  }
  if (area.owner === "players" && area.locked) return { ok: false, text: `${here} is already locked` };
  if (area.owner === "players" && area.influence === 0) {
    return card.difficulty < 2
      ? { ok: false, text: "Locking takes difficulty 2+" }
      : { ok: true, text: `Locks ${here}` };
  }

  const left = Math.max(area.influence - card.difficulty, 0);
  if (left > 0) return { ok: true, text: `Weakens ${villain} here (${area.influence} → ${left})` };
  if (area.owner === "villain") return { ok: true, text: `Takes back ${here}!` };
  if (area.owner === "players") return { ok: true, text: `Clears influence from ${here}` };
  return { ok: true, text: `Claims ${here}` };
}

export const OWNER_LABELS = { players: "Yours", neutral: "Unclaimed", villain: "Villain" };
