import { useEffect, useState } from "react";
import { saveSeenVillainTurn, seenVillainTurn } from "./playerStorage";

// The villain turns this phone hasn't shown yet, and a way to mark them seen.
// A phone opening a game for the first time starts from now rather than
// replaying old turns.
export default function useUnseenVillainTurns(state) {
  const { code, tick_count: tick } = state.game;
  const [seen, setSeen] = useState(() => seenVillainTurn(code) ?? tick);

  useEffect(() => {
    if (seenVillainTurn(code) == null) saveSeenVillainTurn(code, seen);
  }, [code, seen]);

  const turns = (state.villain_turns || []).filter((t) => t.turn > seen);
  const markSeen = () => {
    setSeen(tick);
    saveSeenVillainTurn(code, tick);
  };
  return [turns, markSeen];
}
