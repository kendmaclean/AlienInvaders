# AlienInvadersGame — Research Report

## Overview

The game is implemented as a full MVC architecture across four Pharo packages. It is a fully playable Alien Invaders clone built on top of the **Roassal** visualization framework, with clean separation between game logic, rendering, and input handling.

**Entry point:** `AlienInvadersController open`

---

## Package Structure

| Package | Classes | Responsibility |
|---|---|---|
| `AlienInvaders-Model` | `AIPlayer`, `AIAlien`, `AIBullet`, `AlienInvadersModel` | Pure game state and rules. Zero Roassal imports. |
| `AlienInvaders-View` | `AlienInvadersView` | Roassal rendering. Reads model state each tick, syncs shapes. |
| `AlienInvaders-Controller` | `AlienInvadersController` | Input handling and game loop animation. Wires model and view. |
| `AlienInvaders-Tests` | `AlienInvadersModelTest` | 21 SUnit tests covering all model behaviour. |

---

## Model Layer

### Entity Classes

Three lightweight value objects hold game state. Positions are plain `Point`s — no Roassal dependency.

#### `AIPlayer`
- Instance vars: `position`, `isExploding`, `explodingTicksRemaining`
- `startExploding` — sets flag, initialises 13-tick countdown
- `tickExplosion` — decrements counter, returns `true` when sequence finishes
- The 13-tick countdown at 16ms/tick ≈ 208ms, replacing the original `fork`/`wait`

#### `AIAlien`
- Instance var: `position`
- `AIAlien class >> at: aPoint` — convenience constructor

#### `AIBullet`
- Instance vars: `position`, `velocity`
- `AIBullet class >> playerBulletAt:` — velocity `0 @ -8` (upward)
- `AIBullet class >> alienBulletAt:` — velocity `0 @ 5` (downward)
- `tick` — advances `position` by `velocity`
- `isOffScreen` — `position y < 0 or: [ position y > 600 ]`

---

### `AlienInvadersModel`

Instance vars: `player`, `aliens`, `playerBullets`, `alienBullets`, `score`, `lives`, `gameOver`, `endMessage`, `alienDirection`, `alienSpeed`, `lastAlienShot`

#### Public Interface (called by Controller)

| Method | Description |
|---|---|
| `tick` | Advance one game step; guard on `gameOver` |
| `movePlayerLeft` | Move player left if x > 30 |
| `movePlayerRight` | Move player right if x < 700 |
| `shootPlayerBullet` | Add player bullet; capped at 3 simultaneous |
| `playerHit` | Start explosion (guarded against re-entry) |

#### Game Loop Step (inside `tick`)

1. `tickExplosion` — tick player explosion countdown; call `loseLife` when done
2. `movePlayerBullets` — tick each, reject off-screen
3. `moveAlienBullets` — tick each, reject off-screen
4. `moveAliens` — translate all; reverse+descend+accelerate at walls
5. `checkCollisions` — three AABB collision checks
6. `randomAlienShoot` — fire from a random alien every 30 ticks

#### Collision Detection

```smalltalk
AlienInvadersModel >> rectFor: anEntity size: aSize
    | pos half |
    pos := anEntity position.
    half := aSize / 2.
    ^ Rectangle origin: pos - half corner: pos + half

AlienInvadersModel >> entity: e1 size: s1 collidesWith: e2 size: s2
    ^ (self rectFor: e1 size: s1) intersects: (self rectFor: e2 size: s2)
```

Three checks per tick:
1. **`checkBulletAlienCollisions`** — player bullet (3@15) vs alien (25@20); removes both, +10 score; `winGame` if aliens empty
2. **`checkAlienBulletPlayerCollisions`** — alien bullet (3@15) vs player (30@20); calls `playerHit`, removes bullet
3. **`checkAlienPlayerCollisions`** — alien y > 520 or direct alien/player overlap → `endGame: 'Game Over - Aliens Reached Earth!'`

#### Alien Movement
- All aliens translate by `alienDirection * alienSpeed @ 0` each tick
- If any alien x > 780 or x < 20: reverse direction, descend 20px, `alienSpeed := (alienSpeed + 0.1) min: 8`
- Speed starts at 2, increases 0.1 per direction reversal, capped at 8

#### State Accessors
`player`, `aliens`, `playerBullets`, `alienBullets`, `score`, `lives`, `gameOver`, `endMessage`, `alienSpeed`, `alienSpeed:`

---

## View Layer — `AlienInvadersView`

Instance vars: `canvas`, `model`, `playerShape`, `alienShapes`, `playerBulletShapes`, `alienBulletShapes`, `scoreLabel`, `livesLabel`, `gameOverLabel`

Owns all Roassal objects. Has zero game logic. Called once per tick via `update`.

#### Initialization
```smalltalk
AlienInvadersView new initializeWithModel: aModel
```
Creates `RSCanvas` (black), builds player shape, all alien shapes, and HUD labels. Stores entity→shape mappings in three `IdentityDictionary`s.

#### Per-tick Sync (`update`)
1. `syncPlayer` — update position; set color red if exploding, green otherwise
2. `syncAliens` — remove dead shapes, add new shapes, update positions (IdentityDictionary)
3. `syncPlayerBullets` — same pattern, yellow RSBox 3@15
4. `syncAlienBullets` — same pattern, cyan RSBox 3@15
5. `syncHUD` — update score and lives label text
6. `syncGameOver` — lazy-create red 32pt label at 400@300 on first gameOver tick
7. `canvas signalUpdate` — trigger redraw

#### Key Roassal APIs Used

| API | Usage |
|---|---|
| `RSCanvas new` | Rendering surface |
| `RSBox new` | Player, aliens, bullets |
| `RSLabel new` | HUD labels, game-over message |
| `canvas add:` / `canvas removeShape:` | Shape lifecycle |
| `canvas color:` | Black background |
| `canvas signalUpdate` | Trigger redraw each tick |
| `canvas newAnimation` | Game loop animation |
| `canvas when:do:for:` | Key event subscription |
| `shape position:` | Sync position from model entity |
| `shape color:` | Update player explosion flash |

---

## Controller Layer — `AlienInvadersController`

Instance vars: `model`, `view`, `animation`, `leftKeyPressed`, `rightKeyPressed`

Owns the `RSAnimation`, key-state booleans, and references to model and view.

#### Entry Point
```smalltalk
AlienInvadersController open   "class-side convenience"
```

#### Game Loop
```smalltalk
AlienInvadersController >> tick
    model gameOver ifTrue: [ ^ self ].
    leftKeyPressed  ifTrue: [ model movePlayerLeft ].
    rightKeyPressed ifTrue: [ model movePlayerRight ].
    model tick.
    view update.
```
RSAnimation fires every 16ms (~62.5 FPS). Controller translates held-key state into model commands before each model tick.

#### Input
- `RSKeyDown` / `RSKeyUp` registered on `view canvas`
- Key values: 28 = left arrow, 29 = right arrow, 32 = space
- Space triggers `model shootPlayerBullet` (enforces 3-bullet cap in model)

---

## Data Flow

```
  [Keyboard events]
        |
        v
[AlienInvadersController]   owns RSAnimation (16ms tick)
  leftKeyPressed / rightKeyPressed
        |                          \
        | model commands            \ each tick
        v                            v
[AlienInvadersModel]         [AlienInvadersView]
  AIPlayer (position, explosion) RSCanvas
  AIAlien[] (positions)  <-read- RSBox player
  AIBullet[] (pos+vel)   each    RSBox[] aliens (IdentityDictionary)
  score/lives/gameOver    tick   RSBox[] bullets (IdentityDictionary)
                                 RSLabel HUD
```

---

## Architectural Improvements Over Original

| Original (`SpaceInvadersGame`) | Refactored |
|---|---|
| Single 28-method god class | 6 focused classes across 4 packages |
| Position held in RSBox shapes | Position held in `AIPlayer`/`AIAlien`/`AIBullet` as plain `Point` |
| Explosion via `fork` + `200 milliSeconds wait` | Tick-based `explodingTicksRemaining` counter — no threads |
| Model untestable without opening a window | `AlienInvadersModel` has zero Roassal dependencies; 21 SUnit tests |
| Key state in game class | Key state in `AlienInvadersController` |
| HUD labels stored via canvas property bag | Labels stored as direct instance vars on the view |

---

## Test Suite — `AlienInvadersModelTest` (21 tests, all passing)

| Test | Verifies |
|---|---|
| `testInitialState` | score=0, lives=3, gameOver=false, 55 aliens |
| `testMovePlayerLeftBounded` | Player doesn't move past x=30 |
| `testMovePlayerRightBounded` | Player doesn't move past x=700 |
| `testShootPlayerBulletCap` | 4th shot ignored, count stays at 3 |
| `testPlayerBulletMovesUp` | Player bullet y decreases 8px per tick |
| `testAlienBulletMovesDown` | Alien bullet y increases 5px per tick |
| `testPlayerBulletRemovedOffScreen` | Bullet removed when y < 0 |
| `testAlienBulletRemovedOffScreen` | Bullet removed when y > 600 |
| `testAliensMoveSideways` | All aliens shift by alienSpeed each tick |
| `testAliensReverseAndDescend` | Direction reverses, aliens drop 20px at wall |
| `testAlienSpeedIncreasesOnReverse` | alienSpeed grows by 0.1 per bounce |
| `testAlienSpeedCappedAt8` | Speed never exceeds 8 |
| `testBulletKillsAlien` | Alien removed, score +10 |
| `testAllAliensDeadTriggersWin` | Last alien death sets gameOver, endMessage contains 'Win' |
| `testAlienBulletHitsPlayer` | Player isExploding=true after hit |
| `testDoubleHitIgnored` | Second bullet during explosion doesn't re-trigger |
| `testExplosionTicksDown` | After 13 ticks: isExploding=false, lives decremented |
| `testLoseLifeDecrementsLives` | lives goes from 3 to 2 |
| `testLivesReachZeroTriggersGameOver` | gameOver=true when lives=0 |
| `testAlienReachesEarthTriggersGameOver` | Alien y > 520 triggers endGame |
| `testGameOverBlocksFurtherTicks` | tick is no-op after gameOver=true |

---

## Remaining Design Notes

- **No restart mechanism**: Once `gameOver` is true, a new `AlienInvadersController open` is required. The model and view are stateless enough that this is a single-line fix if needed.
- **alienSpeed / alienSpeed: accessors**: Exposed on `AlienInvadersModel` to support test setup; not part of the controller-facing API.
