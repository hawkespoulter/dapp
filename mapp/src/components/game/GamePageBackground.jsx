import { useEffect } from "react";
import { useLocation } from "react-router-dom";

const PAGE = "#020617"; // slate-950, the game screens' background
const BAR = "#0f172a"; // slate-900, the navbar

// On the park game pages, paint the whole document dark so scrolling past
// the top or bottom (Safari's rubber-band) shows dark instead of white, and
// tint Safari's toolbar to match the navbar. Other pages are left as they are.
function GamePageBackground() {
  const { pathname } = useLocation();

  useEffect(() => {
    const onGame = pathname === "/game" || pathname.startsWith("/game/");
    const root = document.documentElement;
    root.style.backgroundColor = onGame ? PAGE : "";
    document.body.style.backgroundColor = onGame ? PAGE : "";

    let meta = document.querySelector('meta[name="theme-color"]');
    if (onGame) {
      if (!meta) {
        meta = document.createElement("meta");
        meta.name = "theme-color";
        document.head.appendChild(meta);
      }
      meta.content = BAR;
    } else {
      meta?.remove();
    }
  }, [pathname]);

  return null;
}

export default GamePageBackground;
