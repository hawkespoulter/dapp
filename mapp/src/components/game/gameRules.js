// Mirrors the server's influence rules (app/services/games/actions.rb) so the
// area panel can say what placing influence would do. The server decides.

export const OWNER_LABELS = { players: "Yours", neutral: "Unclaimed", villain: "Villain" };

// What the team is working toward in an area, and how much influence it
// takes to get there.
export function placementPlan(state, name) {
  const { game, villain, areas } = state;
  const byName = Object.fromEntries(areas.map((a) => [a.area, a]));
  const area = byName[name];
  const step = area.placement_cost;

  let blocked = null;
  let steps = 0;
  let goal = "";
  if (area.owner === "players" && area.locked) {
    blocked = `Locked — safe from ${villain.name}`;
  } else if (area.owner === "villain" && !area.neighbors.some((n) => byName[n].owner === "players")) {
    blocked = "Hold an area next to it to attack";
  } else if (area.owner === "villain") {
    steps = area.influence + game.claim_cost;
    goal = "take it back";
  } else if (area.owner === "neutral") {
    steps = area.influence + game.claim_cost - area.claim;
    goal = "claim it";
  } else if (area.influence > 0) {
    steps = area.influence;
    goal = `clear ${villain.name}'s influence`;
  } else {
    steps = game.lock_cost - area.claim;
    goal = "lock it";
  }

  return { blocked, step, cost: steps * step, goal };
}

// A short description of where an area's meter sits.
export function meterText(state, area) {
  const { game, villain } = state;
  if (area.owner === "villain") return `${villain.name}'s strength ${area.influence}/${game.max_influence}`;
  const parts = [];
  if (area.influence > 0) parts.push(`${villain.name}'s influence ${area.influence}/${game.max_influence}`);
  if (area.claim > 0) {
    parts.push(area.owner === "players" ? `lock ${area.claim}/${game.lock_cost}` : `claim ${area.claim}/${game.claim_cost}`);
  }
  if (area.locked) parts.push("locked");
  return parts.join(" · ") || (area.owner === "players" ? "Not locked yet" : "No influence yet");
}
