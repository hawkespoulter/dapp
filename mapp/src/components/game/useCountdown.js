import { useEffect, useState } from "react";

// Seconds until `target`, corrected for the gap between this phone's clock
// and the server's.
export default function useCountdown(target, serverTime) {
  const [now, setNow] = useState(Date.now());
  const [offset, setOffset] = useState(0);

  useEffect(() => {
    if (serverTime) setOffset(Date.parse(serverTime) - Date.now());
  }, [serverTime]);

  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, []);

  if (!target) return null;
  return Math.max(0, Math.round((Date.parse(target) - (now + offset)) / 1000));
}

export function formatDuration(seconds) {
  if (seconds == null) return "--";
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}h ${String(m).padStart(2, "0")}m`;
  return `${m}:${String(s).padStart(2, "0")}`;
}
