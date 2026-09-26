# Park game challenges

Every challenge the game can deal lives in this folder. The app picks up
changes on its own the next time it deals cards, including new and deleted
files; there's nothing to run.

- `anywhere.yml` holds challenges that can be done in any park.
- Each park has its own file, named after the park in lowercase with
  underscores: `animal_kingdom.yml`, `sea_world.yml`, ... Every park the
  tracker knows already has one. A park's challenges are only dealt once
  that park is playable (it has a board and a villain); until then they just
  wait. A file with any other name is flagged as a mistake.

Each file is a list of challenges:

```yaml
- title: Night Blossom
  area: Pandora
  description: Drink a Night Blossom from Pongu Pongu.
  difficulty: 1
```

| Field | |
|---|---|
| `title` | Required, and unique across every file. It's how the app recognizes a challenge when you edit it, so renaming one makes it a new challenge. |
| `description` | What the players have to do. |
| `difficulty` | 1, 2 or 3: the coins it earns. |
| `area` | Optional, park files only: the area it happens in. It must match the map's area names exactly, e.g. `"DinoLand U.S.A."` (quote names with commas or periods). |

If a file has a mistake, games keep using the last good set of challenges and
the Game settings page shows what's wrong.
