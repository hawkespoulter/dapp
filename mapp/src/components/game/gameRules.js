// Mirrors the server's influence rules (app/services/games/actions.rb) so the
// area panel can say what placing influence would do. The server decides.

export const OWNER_LABELS = { players: "Yours", neutral: "Unclaimed", villain: "Villain" };

// What placing influence in an area would do: `step` is the influence per
// point of strength, `cost` what it takes to reach the goal.
export function placementPlan(state, name) {
  const { villain, areas } = state;
  const byName = Object.fromEntries(areas.map((a) => [a.area, a]));
  const area = byName[name];
  const step = area.placement_cost;

  if (area.owner === "villain" && !area.neighbors.some((n) => byName[n].owner === "players")) {
    return { blocked: "Hold an area next to it to attack", step };
  }
  if (area.owner === "villain") {
    return { step, cost: (area.strength + 1) * step, goal: "take it", hint: `Each point knocks ${villain.name}'s strength down by 1.` };
  }
  if (area.owner === "neutral") {
    return { step, cost: step, goal: "claim it", hint: "One point claims it at strength 1." };
  }
  return { step, goal: "strengthen", hint: "Each point adds 1 strength." };
}

export function strengthText(state, area) {
  if (area.owner === "villain") return `${state.villain.name}'s strength ${area.strength}`;
  if (area.owner === "players") return `Your strength ${area.strength}`;
  return "Nobody holds it";
}

// Text colors for each game result.
export const RESULT_STYLES = {
  gold: "text-amber-300",
  silver: "text-slate-200",
  bronze: "text-orange-400",
  lost: "text-red-400",
};
