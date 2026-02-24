Class {
	#name : 'AlienInvadersModelTest',
	#superclass : 'TestCase',
	#category : 'AlienInvaders-Tests',
	#package : 'AlienInvaders-Tests'
}

{ #category : 'tests' }
AlienInvadersModelTest >> testAlienBulletHitsPlayer [
    | model bullet |
    model := AlienInvadersModel new.
    bullet := AIBullet alienBulletAt: model player position.
    model alienBullets add: bullet.
    model checkAlienBulletPlayerCollisions.
    self assert: model player isExploding.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testAlienBulletMovesDown [
    | model bullet initialY |
    model := AlienInvadersModel new.
    model shootAlienBullet.
    bullet := model alienBullets first.
    initialY := bullet position y.
    model moveAlienBullets.
    self assert: bullet position y equals: initialY + 5.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testAlienBulletRemovedOffScreen [
    | model bullet |
    model := AlienInvadersModel new.
    model shootAlienBullet.
    bullet := model alienBullets first.
    bullet position: bullet position x @ 596.
    model moveAlienBullets.
    self assert: model alienBullets isEmpty.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testAlienReachesEarthTriggersGameOver [
    | model |
    model := AlienInvadersModel new.
    model aliens do: [ :a | a position: a position x @ 521 ].
    model checkAlienPlayerCollisions.
    self assert: model gameOver.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testAlienSpeedCappedAt8 [
    | model |
    model := AlienInvadersModel new.
    model alienSpeed: 7.95.
    model aliens do: [ :a | a position: 779 @ a position y ].
    model moveAliens.
    self assert: model alienSpeed equals: 8.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testAlienSpeedIncreasesOnReverse [
    | model initialSpeed |
    model := AlienInvadersModel new.
    initialSpeed := model alienSpeed.
    model aliens do: [ :a | a position: 779 @ a position y ].
    model moveAliens.
    self assert: model alienSpeed closeTo: initialSpeed + 0.1.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testAliensMoveSideways [
    | model firstAlien initialX |
    model := AlienInvadersModel new.
    firstAlien := model aliens first.
    initialX := firstAlien position x.
    model moveAliens.
    self assert: firstAlien position x equals: initialX + 2.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testAliensReverseAndDescend [
    | model firstAlien initialY xAfterReverse |
    model := AlienInvadersModel new.
    model aliens do: [ :a | a position: 779 @ a position y ].
    firstAlien := model aliens first.
    initialY := firstAlien position y.
    model moveAliens.
    self assert: firstAlien position y equals: initialY + 20.
    xAfterReverse := firstAlien position x.
    model moveAliens.
    self assert: firstAlien position x < xAfterReverse.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testAllAliensDeadTriggersWin [
    | model bullet |
    model := AlienInvadersModel new.
    [ model aliens size > 1 ] whileTrue: [ model aliens removeFirst ].
    bullet := AIBullet playerBulletAt: model aliens first position.
    model playerBullets add: bullet.
    model checkBulletAlienCollisions.
    self assert: model gameOver.
    self assert: (model endMessage includesSubstring: 'Win').
]

{ #category : 'tests' }
AlienInvadersModelTest >> testBulletKillsAlien [
    | model alien bullet |
    model := AlienInvadersModel new.
    alien := model aliens first.
    bullet := AIBullet playerBulletAt: alien position.
    model playerBullets add: bullet.
    model checkBulletAlienCollisions.
    self deny: (model aliens includes: alien).
    self assert: model score equals: 10.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testDoubleHitIgnored [
    | model bullet1 bullet2 |
    model := AlienInvadersModel new.
    bullet1 := AIBullet alienBulletAt: model player position.
    bullet2 := AIBullet alienBulletAt: model player position.
    model alienBullets add: bullet1.
    model alienBullets add: bullet2.
    model checkAlienBulletPlayerCollisions.
    self assert: model alienBullets isEmpty.
    self assert: model player isExploding.
    self assert: model lives equals: 3.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testExplosionTicksDown [
    | model |
    model := AlienInvadersModel new.
    model playerHit.
    self assert: model player isExploding.
    1 to: 12 do: [ :i | model tickExplosion ].
    self assert: model player isExploding.
    self assert: model lives equals: 3.
    model tickExplosion.
    self deny: model player isExploding.
    self assert: model lives equals: 2.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testGameOverBlocksFurtherTicks [
    | model alienXBefore |
    model := AlienInvadersModel new.
    alienXBefore := model aliens first position x.
    model endGame: 'stopped'.
    model tick.
    self assert: model aliens first position x equals: alienXBefore.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testInitialState [
    | model |
    model := AlienInvadersModel new.
    self assert: model score equals: 0.
    self assert: model lives equals: 3.
    self deny: model gameOver.
    self assert: model aliens size equals: 55.
    self assert: model playerBullets isEmpty.
    self assert: model alienBullets isEmpty.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testLivesReachZeroTriggersGameOver [
    | model |
    model := AlienInvadersModel new.
    model loseLife.
    model loseLife.
    model loseLife.
    self assert: model gameOver.
    self assert: model endMessage equals: 'Game Over!'.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testLoseLifeDecrementsLives [
    | model |
    model := AlienInvadersModel new.
    model loseLife.
    self assert: model lives equals: 2.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testMovePlayerLeftBounded [
    | model |
    model := AlienInvadersModel new.
    model player position: 30 @ 550.
    model movePlayerLeft.
    self assert: model player position x equals: 30.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testMovePlayerRightBounded [
    | model |
    model := AlienInvadersModel new.
    model player position: 700 @ 550.
    model movePlayerRight.
    self assert: model player position x equals: 700.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testPlayerBulletMovesUp [
    | model bullet initialY |
    model := AlienInvadersModel new.
    model shootPlayerBullet.
    bullet := model playerBullets first.
    initialY := bullet position y.
    model movePlayerBullets.
    self assert: bullet position y equals: initialY - 8.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testPlayerBulletRemovedOffScreen [
    | model bullet |
    model := AlienInvadersModel new.
    model shootPlayerBullet.
    bullet := model playerBullets first.
    bullet position: bullet position x @ 0.
    model movePlayerBullets.
    self assert: model playerBullets isEmpty.
]

{ #category : 'tests' }
AlienInvadersModelTest >> testShootPlayerBulletCap [
    | model |
    model := AlienInvadersModel new.
    model shootPlayerBullet.
    model shootPlayerBullet.
    model shootPlayerBullet.
    model shootPlayerBullet.
    self assert: model playerBullets size equals: 3.
]
