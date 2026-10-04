# Claim challenges

Each claim challenge is touching something in that area. To take an area the team doesn't hold (unclaimed or the villain's), the team
goes to that area and completes its claim challenge. Completing it claims the
area at strength 1. There's no failing a claim challenge: you just
claim the area once you've done it.

One file per park, named like the challenge files (`animal_kingdom.yml`). Each
area lists its challenges; with several, the game takes turns through them.

```yaml
Discovery Island:
  - title: Roots of Life
    description: Touch one of the Tree of Life's roots along the Discovery Island trails.
```

An area with no challenge gets a stand-in ("take a group photo there").
Mistakes show on the Game settings page.
