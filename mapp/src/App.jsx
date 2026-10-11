import { BrowserRouter as Router } from "react-router-dom";
import Navbar from "./components/Navbar.jsx";
import AppRoutes from "./components/AppRoutes.jsx";
import GamePageBackground from "./components/game/GamePageBackground.jsx";

function App() {
  return (
    <Router>
      <GamePageBackground />
      <div>
        <Navbar />
        <div style={{paddingTop: "60px"}}>
          <AppRoutes />
        </div>
      </div>
    </Router>
  );
}

export default App;
