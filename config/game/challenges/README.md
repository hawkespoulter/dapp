# Park game challenges

Every challenge the game can deal lives in this folder. The app picks up
changes on its own the next time it deals cards, including new and deleted
files; there's nothing to run.

- `anywhere.yml` holds challenges that can be done in any park.
- Each park has its own file, named after the park in lowercase with
  underscores: `animal_kingdom.yml`, `sea_world.yml`, ... Every park already
  has one. In the game, Universal Studios and Islands of Adventure are one
  park (`universal_orlando.yml`), and so are Disneyland and California
  Adventure (`disneyland_resort.yml`). A park's challenges are only dealt once
  that park is playable (it has a board and a villain); until then they just
  wait. A file with any other name is flagged as a mistake.

Each file is a list of challenges:

```yaml
- title: Night Blossom
  description: Drink a Night Blossom from Pongu Pongu.
  reward: 1
```

| Field | |
|---|---|
| `title` | Required, and unique across every file. It's how the app recognizes a challenge when you edit it, so renaming one makes it a new challenge. |
| `description` | What the players have to do. |
| `reward` | 1, 2 or 3: the coins the team earns for completing it. |
| `list` | Optional: deal some random items from a list with each card, e.g. `{from: tree_of_life_animals, count: 10}`. `from` names a file in `lists/`, and `count` is how many items each card gets. A card keeps its items until it's played. |

## Lists

`lists/` holds plain lists that challenges can deal from, one item per line:

```yaml
- African elephants
- Alligator
```

Edit a list and new cards pick up the change; cards already in someone's
hand keep the items they were dealt.

If a file has a mistake, games keep using the last good set of challenges and
the Game settings page shows what's wrong.
