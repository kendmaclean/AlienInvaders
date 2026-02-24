# MVC Refactoring Plan — AlienInvadersGame

## Context

The current `AlienInvadersGame` class mixes game state, movement logic, collision detection, Roassal rendering, and input handling in a single 28-method class. This makes the logic hard to test (you can't run the model without opening a window), hard to extend (changing rendering requires understanding game rules), and hard to reason about (Roassal shapes double as game-state holders via their `position`).

The goal is to introduce three distinct layers — **Model**, **View**, **Controller** — that communicate through well-defined interfaces, enabling the game logic to be tested without UI and the rendering to be swapped without touching rules.

---

## Proposed Package Structure

| Package | Responsibility |
|---|---|
| `AlienInvaders-Model` | Pure game state and rules. Zero Roassal imports. |
| `AlienInvaders-View` | Roassal rendering only. Reads model state, draws shapes. |
| `AlienInvaders-Controller` | Input handling and game loop. Wires model and view. |
| `AlienInvaders-Tests` | SUnit tests for the model layer. |
| `AlienInvaders` | Keep `AlienInvadersGame` during migration; remove after. |

---

## Layer 1 — Model (`AlienInvaders-Model`)

### Entity Classes

Three lightweight value objects replace Roassal shapes as state holders. Positions are plain `Point`s.

> **Prefix note:** `AI` = AlienInvaders throughout (not "Artificial Intelligence").

#### `AIPlayer`

```smalltalk
Object subclass: #AIPlayer
    instanceVariableNames: 'position isExploding explodingTicksRemaining'
    classVariableNames: ''
    package: 'AlienInvaders-Model'
```

Key methods:

```smalltalk
AIPlayer >> initialize
    position := 400 @ 550.
    isExploding := false.
    explodingTicksRemaining := 0.

AIPlayer >> startExploding
    "13 ticks × 16ms ≈ 208ms, replaces the forked 200ms wait"
    isExploding := true.
    explodingTicksRemaining := 13.

AIPlayer >> tickExplosion
    "Decrement timer. Returns true when the explosion sequence finishes."
    explodingTicksRemaining := explodingTicksRemaining - 1.
    explodingTicksRemaining <= 0 ifTrue: [
        isExploding := false.
        ^ true ].
    ^ false
```

> **Key improvement:** This tick-based counter replaces the `fork` / `200 milliSeconds wait` in the original. It is deterministic, thread-safe, and requires no Pharo process management.

---

#### `AIAlien`

```smalltalk
Object subclass: #AIAlien
    instanceVariableNames: 'position'
    classVariableNames: ''
    package: 'AlienInvaders-Model'
```

```smalltalk
AIAlien class >> at: aPoint
    ^ self new position: aPoint; yourself
```

---

#### `AIBullet`

```smalltalk
Object subclass: #AIBullet
    instanceVariableNames: 'position velocity'
    classVariableNames: ''
    package: 'AlienInvaders-Model'
```

```smalltalk
AIBullet class >> playerBulletAt: aPoint
    ^ self new position: aPoint; velocity: 0 @ -8; yourself

AIBullet class >> alienBulletAt: aPoint
    ^ self new position: aPoint; velocity: 0 @ 5; yourself

AIBullet >> tick
    position := position + velocity

AIBullet >> isOffScreen
    ^ position y < 0 or: [ position y > 600 ]
```

---

### `AlienInvadersModel`

The main model. Contains all game state and all game rules. No Roassal, no UI.

```smalltalk
Object subclass: #AlienInvadersModel
    instanceVariableNames: 'player aliens playerBullets alienBullets
                             score lives gameOver endMessage
                             alienDirection alienSpeed lastAlienShot'
    classVariableNames: ''
    package: 'AlienInvaders-Model'
```

#### Initialization

```smalltalk
AlienInvadersModel >> initialize
    score := 0.
    lives := 3.
    gameOver := false.
    alienDirection := 1.
    alienSpeed := 2.
    lastAlienShot := 0.
    player := AIPlayer new.
    playerBullets := OrderedCollection new.
    alienBullets  := OrderedCollection new.
    self initializeAliens.

AlienInvadersModel >> initializeAliens
    aliens := OrderedCollection new.
    1 to: 5 do: [ :row |
        1 to: 11 do: [ :col |
            aliens add: (AIAlien at: (50 + (col * 60)) @ (50 + (row * 50))) ] ].
```

#### Public Interface (called by Controller)

```smalltalk
AlienInvadersModel >> tick
    "Advance one game step. Controller calls this once per animation frame."
    gameOver ifTrue: [ ^ self ].
    self tickExplosion.
    self movePlayerBullets.
    self moveAlienBullets.
    self moveAliens.
    self checkCollisions.
    self randomAlienShoot.

AlienInvadersModel >> movePlayerLeft
    player position x > 30 ifTrue: [
        player position: player position - (5 @ 0) ].

AlienInvadersModel >> movePlayerRight
    player position x < 700 ifTrue: [
        player position: player position + (5 @ 0) ].

AlienInvadersModel >> shootPlayerBullet
    playerBullets size >= 3 ifTrue: [ ^ self ].
    playerBullets add: (AIBullet playerBulletAt: player position).
```

#### Private Movement

```smalltalk
AlienInvadersModel >> moveAliens
    | moveDown |
    moveDown := false.
    aliens do: [ :alien |
        alien position: alien position + (alienDirection * alienSpeed @ 0).
        (alien position x > 780 or: [ alien position x < 20 ])
            ifTrue: [ moveDown := true ] ].
    moveDown ifTrue: [
        alienDirection := alienDirection negated.
        aliens do: [ :alien | alien position: alien position + (0 @ 20) ].
        alienSpeed := (alienSpeed + 0.1) min: 8 ].

AlienInvadersModel >> movePlayerBullets
    playerBullets do: [ :b | b tick ].
    playerBullets := playerBullets reject: [ :b | b isOffScreen ].

AlienInvadersModel >> moveAlienBullets
    alienBullets do: [ :b | b tick ].
    alienBullets := alienBullets reject: [ :b | b isOffScreen ].
```

#### Collision Detection

The original `shape:collidesWith:` used `encompassingRectangle`. The model replicates this with plain geometry:

```smalltalk
AlienInvadersModel >> rectFor: anEntity size: aPoint
    | pos half |
    pos  := anEntity position.
    half := aPoint / 2.
    ^ Rectangle origin: pos - half corner: pos + half

AlienInvadersModel >> entity: e1 size: s1 collidesWith: e2 size: s2
    ^ (self rectFor: e1 size: s1) intersects: (self rectFor: e2 size: s2)
```

Example usage in collision checks:
```smalltalk
"bullet (3@15) vs alien (25@20)"
(self entity: bullet size: 3 @ 15 collidesWith: alien size: 25 @ 20)
```

#### Explosion (tick-based, no fork)

```smalltalk
AlienInvadersModel >> tickExplosion
    player isExploding ifFalse: [ ^ self ].
    player tickExplosion ifTrue: [ self loseLife ].

AlienInvadersModel >> playerHit
    player isExploding ifTrue: [ ^ self ].
    player startExploding.

AlienInvadersModel >> loseLife
    lives := lives - 1.
    lives <= 0 ifTrue: [ self endGame: 'Game Over!' ].

AlienInvadersModel >> endGame: aMessage
    gameOver := true.
    endMessage := aMessage.

AlienInvadersModel >> winGame
    self endGame: 'You Win! Score: ', score asString.
```

#### State Accessors (read by View)

```
player, aliens, playerBullets, alienBullets,
score, lives, gameOver, endMessage
```

---

## Layer 2 — View (`AlienInvaders-View`)

The view owns all Roassal objects. It reads model state on each `update` call and syncs shapes using `IdentityDictionary` maps (model entity → RSBox). It has **zero game logic**.

```smalltalk
Object subclass: #AlienInvadersView
    instanceVariableNames: 'canvas model
                             playerShape alienShapes
                             playerBulletShapes alienBulletShapes
                             scoreLabel livesLabel gameOverLabel'
    classVariableNames: ''
    package: 'AlienInvaders-View'
```

#### Initialization

```smalltalk
AlienInvadersView >> initializeWithModel: aModel
    model := aModel.
    alienShapes        := IdentityDictionary new.
    playerBulletShapes := IdentityDictionary new.
    alienBulletShapes  := IdentityDictionary new.
    self buildCanvas.
    ^ self

AlienInvadersView >> buildCanvas
    canvas := RSCanvas new color: Color black.
    self buildPlayerShape.
    self buildAlienShapes.
    self buildHUD.

AlienInvadersView >> buildPlayerShape
    playerShape := RSBox new
        size: 30 @ 20; color: Color green;
        position: model player position; yourself.
    canvas add: playerShape.

AlienInvadersView >> buildAlienShapes
    model aliens do: [ :alien | self addShapeForAlien: alien ].

AlienInvadersView >> addShapeForAlien: anAlien
    | shape |
    shape := RSBox new size: 25 @ 20; color: Color red; yourself.
    alienShapes at: anAlien put: shape.
    canvas add: shape.

AlienInvadersView >> buildHUD
    scoreLabel := RSLabel new
        text: 'Score: 0'; color: Color white; fontSize: 16;
        position: 50 @ 20; yourself.
    livesLabel := RSLabel new
        text: 'Lives: 3'; color: Color white; fontSize: 16;
        position: 750 @ 20; yourself.
    canvas add: scoreLabel; add: livesLabel.
```

#### Per-tick Update (called by Controller)

```smalltalk
AlienInvadersView >> update
    self syncPlayer.
    self syncAliens.
    self syncPlayerBullets.
    self syncAlienBullets.
    self syncHUD.
    self syncGameOver.
    canvas signalUpdate.
```

#### Sync Helpers

```smalltalk
AlienInvadersView >> syncPlayer
    playerShape position: model player position.
    playerShape color: (model player isExploding
        ifTrue:  [ Color red ]
        ifFalse: [ Color green ]).

AlienInvadersView >> syncAliens
    | living |
    living := model aliens asIdentitySet.
    (alienShapes keys reject: [ :a | living includes: a ]) do: [ :dead |
        canvas removeShape: (alienShapes at: dead).
        alienShapes removeKey: dead ].
    model aliens do: [ :alien |
        (alienShapes at: alien ifAbsent: [ self addShapeForAlien: alien ])
            position: alien position ].

AlienInvadersView >> syncPlayerBullets
    | active |
    active := model playerBullets asIdentitySet.
    (playerBulletShapes keys reject: [ :b | active includes: b ]) do: [ :gone |
        canvas removeShape: (playerBulletShapes at: gone).
        playerBulletShapes removeKey: gone ].
    model playerBullets do: [ :bullet |
        | shape |
        shape := playerBulletShapes
            at: bullet
            ifAbsent: [
                | s |
                s := RSBox new size: 3 @ 15; color: Color yellow; yourself.
                playerBulletShapes at: bullet put: s.
                canvas add: s.
                s ].
        shape position: bullet position ].

"syncAlienBullets follows the same pattern with Color cyan"

AlienInvadersView >> syncHUD
    scoreLabel text: 'Score: ', model score asString.
    livesLabel text: 'Lives: ', model lives asString.

AlienInvadersView >> syncGameOver
    model gameOver ifFalse: [ ^ self ].
    gameOverLabel ifNil: [
        gameOverLabel := RSLabel new
            text: model endMessage;
            color: Color red; fontSize: 32;
            position: 400 @ 300; yourself.
        canvas add: gameOverLabel ].
```

---

## Layer 3 — Controller (`AlienInvaders-Controller`)

The controller owns the `RSAnimation` and key-state booleans. It translates input into model commands and drives the render loop.

```smalltalk
Object subclass: #AlienInvadersController
    instanceVariableNames: 'model view animation leftKeyPressed rightKeyPressed'
    classVariableNames: ''
    package: 'AlienInvaders-Controller'
```

#### Entry Point

```smalltalk
AlienInvadersController class >> open
    self new start

AlienInvadersController >> start
    model := AlienInvadersModel new.
    view  := AlienInvadersView new initializeWithModel: model.
    leftKeyPressed  := false.
    rightKeyPressed := false.
    self setupKeyHandlers.
    self startAnimation.
    view canvas open
        setLabel: 'Alien Invaders';
        extent: 800 @ 640.
```

#### Game Loop

```smalltalk
AlienInvadersController >> startAnimation
    animation := view canvas newAnimation
        repeat;
        duration: 16 milliSeconds;
        onStepDo: [ :t | self tick ];
        yourself.

AlienInvadersController >> tick
    model gameOver ifTrue: [ ^ self ].
    leftKeyPressed  ifTrue: [ model movePlayerLeft ].
    rightKeyPressed ifTrue: [ model movePlayerRight ].
    model tick.
    view update.
```

#### Input Handling

```smalltalk
AlienInvadersController >> setupKeyHandlers
    view canvas
        when: RSKeyDown do: [ :evt | self handleKeyDown: evt ] for: self;
        when: RSKeyUp   do: [ :evt | self handleKeyUp: evt ]   for: self.

AlienInvadersController >> handleKeyDown: evt
    model gameOver ifTrue: [ ^ self ].
    evt keyValue = 28 ifTrue: [ leftKeyPressed  := true ].
    evt keyValue = 29 ifTrue: [ rightKeyPressed := true ].
    evt keyValue = 32 ifTrue: [ model shootPlayerBullet ].

AlienInvadersController >> handleKeyUp: evt
    evt keyValue = 28 ifTrue: [ leftKeyPressed  := false ].
    evt keyValue = 29 ifTrue: [ rightKeyPressed := false ].
```

---

## Data Flow

```
  [Keyboard events]
        |
        v
[AlienInvadersController]   <-- owns animation (RSAnimation)
  leftKeyPressed / rightKeyPressed
        |                          \
        | model commands            \ tick → model.tick → view.update
        v                            v
[AlienInvadersModel]         [AlienInvadersView]
  AIPlayer                      RSCanvas
  AIAlien[]           <--read--  RSBox (player)
  AIBullet[]          each tick  RSBox[] (aliens via IdentityDictionary)
  score/lives/gameOver           RSBox[] (bullets via IdentityDictionary)
                                 RSLabel (HUD)
```

---

## Key Architectural Improvements

| Issue in Original | Solution in Refactor |
|---|---|
| Position stored in RSBox (Roassal shape) | Position stored in `AIPlayer`/`AIAlien`/`AIBullet` as plain `Point` |
| Explosion uses `fork` + `200 milliSeconds wait` | Tick-based `explodingTicksRemaining` counter in `AIPlayer` — no threads |
| Model untestable without a window | `AlienInvadersModel` has zero Roassal dependencies; full SUnit coverage possible |
| Single god-class with 28 methods | Three focused classes + three entity classes |
| Key state (`leftKeyPressed`) lives in game class | Key state lives in `AlienInvadersController` where it belongs |

---

## Todo List

### Phase 0 — Rename existing code ✓
- [x] Rename class `SpaceInvadersGame` → `AlienInvadersGame` (temporary placeholder, deleted in Phase 7)
- [x] Rename package `SpaceInvaders` → `AlienInvaders`

### Phase 1 — Create packages ✓
- [x] Create package `AlienInvaders-Model`
- [x] Create package `AlienInvaders-View`
- [x] Create package `AlienInvaders-Controller`
- [x] Create package `AlienInvaders-Tests`

### Phase 2 — Entity classes ✓
- [x] Create class `AIPlayer` (instance vars: `position`, `isExploding`, `explodingTicksRemaining`)
- [x] `AIPlayer >> initialize` — default position 400@550, flags false, timer 0
- [x] `AIPlayer >> position` / `AIPlayer >> position:`
- [x] `AIPlayer >> isExploding`
- [x] `AIPlayer >> startExploding` — set flag, set timer to 13
- [x] `AIPlayer >> tickExplosion` — decrement timer, return true when done
- [x] Create class `AIAlien` (instance var: `position`)
- [x] `AIAlien class >> at:` — convenience constructor
- [x] `AIAlien >> position` / `AIAlien >> position:`
- [x] Create class `AIBullet` (instance vars: `position`, `velocity`)
- [x] `AIBullet class >> playerBulletAt:` — velocity 0@-8
- [x] `AIBullet class >> alienBulletAt:` — velocity 0@5
- [x] `AIBullet >> position` / `AIBullet >> position:`
- [x] `AIBullet >> tick` — advance position by velocity
- [x] `AIBullet >> isOffScreen` — y < 0 or y > 600

### Phase 3 — `AlienInvadersModel` ✓
- [x] Create class `AlienInvadersModel`
- [x] `initialize` — zero state, create `AIPlayer`, empty collections
- [x] `initializeAliens` — build 5×11 grid of `AIAlien` instances
- [x] `tick` — main step: guard gameOver, call all sub-steps in order
- [x] `movePlayerLeft` — move player left if x > 30
- [x] `movePlayerRight` — move player right if x < 700
- [x] `shootPlayerBullet` — guard at 3 bullets, add `AIBullet playerBulletAt:` player position
- [x] `moveAliens` — translate all, detect wall hit, reverse + descend + accelerate (capped at 8)
- [x] `movePlayerBullets` — tick each, reject off-screen
- [x] `moveAlienBullets` — tick each, reject off-screen
- [x] `rectFor:size:` — AABB rectangle from entity position and size
- [x] `entity:size:collidesWith:size:` — intersects: check using above
- [x] `checkCollisions` — dispatch to the three sub-checks
- [x] `checkBulletAlienCollisions` — remove hit bullets/aliens, increment score, check win
- [x] `checkAlienBulletPlayerCollisions` — call `playerHit` on match, remove bullet
- [x] `checkAlienPlayerCollisions` — endGame if any alien y > 520 or touches player
- [x] `tickExplosion` — delegate to `AIPlayer >> tickExplosion`, call `loseLife` on completion
- [x] `playerHit` — guard re-entry, call `AIPlayer >> startExploding`
- [x] `loseLife` — decrement lives, call `endGame:` if 0
- [x] `incrementScore` — score +10
- [x] `randomAlienShoot` — increment counter, fire every 30 ticks
- [x] `shootAlienBullet` — pick random alien, add `AIBullet alienBulletAt:` its position
- [x] `endGame:` — set gameOver true, store endMessage
- [x] `winGame` — call `endGame:` with win string
- [x] State accessors: `player`, `aliens`, `playerBullets`, `alienBullets`, `score`, `lives`, `gameOver`, `endMessage`

### Phase 4 — Tests (`AlienInvaders-Tests`) ✓ 21/21 passing
- [x] Create class `AlienInvadersModelTest`
- [x] `testInitialState` — score=0, lives=3, gameOver=false, 55 aliens
- [x] `testMovePlayerLeftBounded` — player doesn't move past x=30
- [x] `testMovePlayerRightBounded` — player doesn't move past x=700
- [x] `testShootPlayerBulletCap` — 4th shoot ignored, count stays at 3
- [x] `testPlayerBulletMovesUp` — bullet y decreases by 8 per tick
- [x] `testAlienBulletMovesDown` — bullet y increases by 5 per tick
- [x] `testPlayerBulletRemovedOffScreen` — bullet removed when y < 0
- [x] `testAlienBulletRemovedOffScreen` — bullet removed when y > 600
- [x] `testAliensMoveSideways` — all aliens shift by alienSpeed each tick
- [x] `testAliensReverseAndDescend` — direction reverses, all aliens drop 20px at wall
- [x] `testAlienSpeedIncreasesOnReverse` — alienSpeed grows by 0.1 per bounce
- [x] `testAlienSpeedCappedAt8` — speed never exceeds 8 regardless of bounces
- [x] `testBulletKillsAlien` — alien removed from collection on hit, score becomes 10
- [x] `testAllAliensDeadTriggersWin` — last alien killed sets gameOver=true, endMessage contains 'Win'
- [x] `testAlienBulletHitsPlayer` — player isExploding becomes true after hit
- [x] `testDoubleHitIgnored` — second alien bullet during explosion does not re-trigger
- [x] `testExplosionTicksDown` — after 13 ticks, isExploding=false and lives decremented
- [x] `testLoseLifeDecrementsLives` — lives goes from 3 to 2
- [x] `testLivesReachZeroTriggersGameOver` — gameOver=true when lives reach 0
- [x] `testAlienReachesEarthTriggersGameOver` — alien y > 520 triggers endGame
- [x] `testGameOverBlocksFurtherTicks` — model tick is a no-op after gameOver=true

### Phase 5 — `AlienInvadersView` ✓
- [x] Create class `AlienInvadersView`
- [x] `initializeWithModel:` — store model, init IdentityDictionaries, call buildCanvas
- [x] `buildCanvas` — RSCanvas black, call buildPlayerShape + buildAlienShapes + buildHUD
- [x] `buildPlayerShape` — green RSBox 30@20 at player position
- [x] `buildAlienShapes` — iterate model aliens, call addShapeForAlien: each
- [x] `addShapeForAlien:` — create red RSBox 25@20, store in alienShapes dict, add to canvas
- [x] `buildHUD` — score and lives RSLabels, white 16pt
- [x] `update` — call all sync methods + canvas signalUpdate
- [x] `syncPlayer` — update position and colour (red if exploding, green otherwise)
- [x] `syncAliens` — remove dead shapes, add new shapes, sync positions (IdentityDictionary)
- [x] `syncPlayerBullets` — remove culled shapes, add new shapes, sync positions (IdentityDictionary)
- [x] `syncAlienBullets` — same pattern as syncPlayerBullets with cyan colour
- [x] `syncHUD` — update scoreLabel and livesLabel text
- [x] `syncGameOver` — lazy-create red 32pt endMessage label at 400@300 on first gameOver tick
- [x] `canvas` accessor

### Phase 6 — `AlienInvadersController` ✓
- [x] Create class `AlienInvadersController`
- [x] `AlienInvadersController class >> open` — convenience entry point
- [x] `start` — create model, create view, init key flags, call setupKeyHandlers + startAnimation + open window
- [x] `startAnimation` — RSAnimation repeat, 16ms, onStepDo: tick
- [x] `tick` — guard gameOver, apply key state to model, call model tick, call view update
- [x] `setupKeyHandlers` — register RSKeyDown and RSKeyUp on view canvas
- [x] `handleKeyDown:` — set leftKeyPressed / rightKeyPressed; call model shootPlayerBullet on space
- [x] `handleKeyUp:` — clear leftKeyPressed / rightKeyPressed

### Phase 7 — Integration & Cleanup ✓
- [x] Smoke test: `AlienInvadersController open` — window opens titled 'Alien Invaders', game runs
- [x] Verify player movement (left/right arrow keys, boundary clamping)
- [x] Verify player shooting (space bar fires, max 3 simultaneous bullets)
- [x] Verify alien movement (sideways march, descent on reversal, speed increase)
- [x] Verify alien speed cap (aliens never become unplayably fast)
- [x] Verify player bullet kills alien, score increments by 10
- [x] Verify alien bullet triggers red flash on player, life lost after ~200ms
- [x] Verify double-hit protection: rapid alien bullets don't drain multiple lives at once
- [x] Verify win screen when all aliens are eliminated
- [x] Verify lose screen when lives reach 0
- [x] Verify lose screen when aliens reach y > 520
- [x] Run full `AlienInvadersModelTest` suite — all tests green
- [x] Delete `AlienInvadersGame` class
- [x] Delete or repurpose `AlienInvaders` package
- [x] Update `research.md` with new class names and architecture
