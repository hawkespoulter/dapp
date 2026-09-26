import { Route, Routes } from "react-router-dom";
import Completions from "./Completions/Completions.jsx";
import Map from "./Map.jsx";
import Edit from "./Edit.jsx";
import Attractions from "./pages/Attractions.jsx";
import Restaurants from "./pages/Restaurants.jsx";
import Shows from "./pages/Shows.jsx";
import DateGenerator from "./pages/DateGenerator.jsx";
import Info from "./pages/Info.jsx";
import GameHome from "./game/GameHome.jsx";
import GameRoom from "./game/GameRoom.jsx";
import GameSettings from "./game/GameSettings.jsx";

function AppRoutes() {
  return (
    <Routes>
      <Route exact path="/" element={<Completions />} />
      <Route exact path="/attractions" element={<Attractions />} />
      <Route exact path="/attractions/:id/edit" element={<Edit type="attractions" />} />
      <Route exact path="/attractions/new" element={<Edit type="attractions" />} />
      <Route exact path="/shows" element={<Shows />} />
      <Route exact path="/shows/:id/edit" element={<Edit type="shows" />} />
      <Route exact path="/shows/new" element={<Edit type="shows"/>} />
      <Route exact path="/restaurants" element={<Restaurants />} />
      <Route exact path="/restaurants/:id/edit" element={<Edit type="restaurants" />} />W
      <Route exact path="/restaurants/new" element={<Edit type="restaurants"/>} />
      <Route exact path="/map/animalKingdom" element={<Map park="Animal Kingdom" />} />
      <Route exact path="/map/epcot" element={<Map park="Epcot" />} />
      <Route exact path="/map/magicKingdom" element={<Map park="Magic Kingdom" />} />
      <Route exact path="/map/hollywoodStudios" element={<Map park="Hollywood Studios" />} />
      <Route exact path="/map/universalStudios" element={<Map park="Universal Studios" />} />
      <Route exact path="/map/islandsOfAdventure" element={<Map park="Islands Of Adventure" />} />
      <Route exact path="/dateNight" element={<DateGenerator />} />
      <Route exact path="/info" element={<Info />} />
      <Route exact path="/game" element={<GameHome />} />
      <Route exact path="/game/settings" element={<GameSettings />} />
      <Route exact path="/game/:code" element={<GameRoom />} />
    </Routes>
  );
}

export default AppRoutes;
