# Claim challenges

To take an area the team doesn't hold (unclaimed or the villain's), the team
goes to that area and completes its claim challenge. Completing it claims the
area at strength 1. Failing it counts as a failed challenge (in hard mode the
villain takes a turn).

One file per park, named like the challenge files (`animal_kingdom.yml`). Each
area lists its challenges; with several, the game takes turns through them.

```yaml
Discovery Island:
  - title: Tree of Life Portrait
    description: Take a group photo with the Tree of Life behind you.
```

An area with no challenge gets a stand-in ("take a group photo there").
Mistakes show on the Game settings page.
