import { useParams, Link } from "react-router-dom";
import { useFetchGameQuery } from "~/store/apis/gameApi";
import { errorMessage } from "./playerStorage";
import Lobby from "./Lobby";
import GameBoard from "./GameBoard";
import GameOver from "./GameOver";
import { JoinForm } from "./GameHome";

const POLL_MS = 4000;

function GameRoom() {
  const code = useParams().code.toUpperCase();
  const { data, error, isLoading, refetch } = useFetchGameQuery(code, {
    pollingInterval: POLL_MS,
    refetchOnFocus: true,
    skipPollingIfUnfocused: true,
  });

  if (isLoading) {
    return <div className="flex h-screen items-center justify-center bg-slate-950 text-white">Loading game…</div>;
  }
  if (error && !data) {
    return (
      <div className="flex h-screen flex-col items-center justify-center gap-3 bg-slate-950 text-white">
        <p>{errorMessage(error)}</p>
        <Link to="/game" className="rounded-lg bg-sky-600 px-4 py-2 font-bold">Back</Link>
      </div>
    );
  }

  if (data.game.status === "finished") return <GameOver state={data} />;

  const view = data.game.status === "lobby" ? <Lobby state={data} /> : <GameBoard state={data} refetch={refetch} />;
  if (data.me) return view;

  // Opened a shared link without being in the game yet.
  return (
    <div className="bg-slate-950 text-white">
      <div className="p-4">
        <JoinForm initialCode={code} />
      </div>
      {view}
    </div>
  );
}

export default GameRoom;
