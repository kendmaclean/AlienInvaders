Class {
	#name : 'AlienInvadersModel',
	#superclass : 'Object',
	#instVars : [
		'player',
		'aliens',
		'playerBullets',
		'alienBullets',
		'score',
		'lives',
		'gameOver',
		'endMessage',
		'alienDirection',
		'alienSpeed',
		'lastAlienShot'
	],
	#category : 'AlienInvaders-Model',
	#package : 'AlienInvaders-Model'
}

{ #category : 'accessing' }
AlienInvadersModel >> alienBullets [
    ^ alienBullets
]

{ #category : 'accessing' }
AlienInvadersModel >> alienSpeed [
    ^ alienSpeed
]

{ #category : 'accessing' }
AlienInvadersModel >> alienSpeed: aNumber [
    alienSpeed := aNumber
]

{ #category : 'accessing' }
AlienInvadersModel >> aliens [
    ^ aliens
]

{ #category : 'private' }
AlienInvadersModel >> checkAlienBulletPlayerCollisions [
    | toRemove |
    toRemove := OrderedCollection new.
    alienBullets do: [ :bullet |
        (self entity: bullet size: 3 @ 15 collidesWith: player size: 30 @ 20) ifTrue: [
            toRemove add: bullet.
            self playerHit ] ].
    toRemove do: [ :b | alienBullets remove: b ifAbsent: [] ].
]

{ #category : 'private' }
AlienInvadersModel >> checkAlienPlayerCollisions [
    aliens do: [ :alien |
        (alien position y > 520 or: [
            self entity: alien size: 25 @ 20 collidesWith: player size: 30 @ 20 ])
                ifTrue: [ self endGame: 'Game Over - Aliens Reached Earth!' ] ].
]

{ #category : 'private' }
AlienInvadersModel >> checkBulletAlienCollisions [
    | hitBullets hitAliens |
    hitBullets := Set new.
    hitAliens := Set new.
    playerBullets do: [ :bullet |
        aliens do: [ :alien |
            (self entity: bullet size: 3 @ 15 collidesWith: alien size: 25 @ 20) ifTrue: [
                hitBullets add: bullet.
                hitAliens add: alien.
                self incrementScore ] ] ].
    hitBullets do: [ :b | playerBullets remove: b ifAbsent: [] ].
    hitAliens do: [ :a | aliens remove: a ifAbsent: [] ].
    aliens isEmpty ifTrue: [ self winGame ].
]

{ #category : 'private' }
AlienInvadersModel >> checkCollisions [
    self checkBulletAlienCollisions.
    self checkAlienBulletPlayerCollisions.
    self checkAlienPlayerCollisions.
]

{ #category : 'private' }
AlienInvadersModel >> endGame: aMessage [
    gameOver := true.
    endMessage := aMessage.
]

{ #category : 'accessing' }
AlienInvadersModel >> endMessage [
    ^ endMessage
]

{ #category : 'private' }
AlienInvadersModel >> entity: e1 size: s1 collidesWith: e2 size: s2 [
    ^ (self rectFor: e1 size: s1) intersects: (self rectFor: e2 size: s2)
]

{ #category : 'accessing' }
AlienInvadersModel >> gameOver [
    ^ gameOver
]

{ #category : 'private' }
AlienInvadersModel >> incrementScore [
    score := score + 10.
]

{ #category : 'initialization' }
AlienInvadersModel >> initialize [
    score := 0.
    lives := 3.
    gameOver := false.
    alienDirection := 1.
    alienSpeed := 2.
    lastAlienShot := 0.
    player := AIPlayer new.
    playerBullets := OrderedCollection new.
    alienBullets := OrderedCollection new.
    self initializeAliens.
]

{ #category : 'initialization' }
AlienInvadersModel >> initializeAliens [
    aliens := OrderedCollection new.
    1 to: 5 do: [ :row |
        1 to: 11 do: [ :col |
            aliens add: (AIAlien at: (50 + (col * 60)) @ (50 + (row * 50))) ] ].
]

{ #category : 'accessing' }
AlienInvadersModel >> lives [
    ^ lives
]

{ #category : 'private' }
AlienInvadersModel >> loseLife [
    lives := lives - 1.
    lives <= 0 ifTrue: [ self endGame: 'Game Over!' ].
]

{ #category : 'private' }
AlienInvadersModel >> moveAlienBullets [
    alienBullets do: [ :b | b tick ].
    alienBullets := alienBullets reject: [ :b | b isOffScreen ].
]

{ #category : 'private' }
AlienInvadersModel >> moveAliens [
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
]

{ #category : 'private' }
AlienInvadersModel >> movePlayerBullets [
    playerBullets do: [ :b | b tick ].
    playerBullets := playerBullets reject: [ :b | b isOffScreen ].
]

{ #category : 'public' }
AlienInvadersModel >> movePlayerLeft [
    player position x > 30 ifTrue: [
        player position: player position - (8 @ 0) ].
]

{ #category : 'public' }
AlienInvadersModel >> movePlayerRight [
    player position x < 700 ifTrue: [
        player position: player position + (8 @ 0) ].
]

{ #category : 'accessing' }
AlienInvadersModel >> player [
    ^ player
]

{ #category : 'accessing' }
AlienInvadersModel >> playerBullets [
    ^ playerBullets
]

{ #category : 'public' }
AlienInvadersModel >> playerHit [
    player isExploding ifTrue: [ ^ self ].
    player startExploding.
]

{ #category : 'private' }
AlienInvadersModel >> randomAlienShoot [
    lastAlienShot := lastAlienShot + 1.
    (lastAlienShot > 30 and: [ aliens notEmpty ]) ifTrue: [
        self shootAlienBullet.
        lastAlienShot := 0 ].
]

{ #category : 'private' }
AlienInvadersModel >> rectFor: anEntity size: aSize [
    | pos half |
    pos := anEntity position.
    half := aSize / 2.
    ^ Rectangle origin: pos - half corner: pos + half
]

{ #category : 'accessing' }
AlienInvadersModel >> score [
    ^ score
]

{ #category : 'private' }
AlienInvadersModel >> shootAlienBullet [
    | alien |
    alien := aliens atRandom.
    alienBullets add: (AIBullet alienBulletAt: alien position).
]

{ #category : 'public' }
AlienInvadersModel >> shootPlayerBullet [
    playerBullets size >= 3 ifTrue: [ ^ self ].
    playerBullets add: (AIBullet playerBulletAt: player position).
]

{ #category : 'public' }
AlienInvadersModel >> tick [
    gameOver ifTrue: [ ^ self ].
    self tickExplosion.
    self movePlayerBullets.
    self moveAlienBullets.
    self moveAliens.
    self checkCollisions.
    self randomAlienShoot.
]

{ #category : 'private' }
AlienInvadersModel >> tickExplosion [
    player isExploding ifFalse: [ ^ self ].
    player tickExplosion ifTrue: [ self loseLife ].
]

{ #category : 'private' }
AlienInvadersModel >> winGame [
    self endGame: 'You Win! Score: ', score asString.
]
