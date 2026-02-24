Class {
	#name : 'AlienInvadersView',
	#superclass : 'Object',
	#instVars : [
		'canvas',
		'model',
		'playerShape',
		'alienShapes',
		'playerBulletShapes',
		'alienBulletShapes',
		'scoreLabel',
		'livesLabel',
		'gameOverLabel'
	],
	#category : 'AlienInvaders-View',
	#package : 'AlienInvaders-View'
}

{ #category : 'initialization' }
AlienInvadersView >> addShapeForAlien: anAlien [
    | shape |
    shape := RSBox new
        size: 25 @ 20;
        color: Color red;
        yourself.
    alienShapes at: anAlien put: shape.
    canvas add: shape.
]

{ #category : 'initialization' }
AlienInvadersView >> buildAlienShapes [
    model aliens do: [ :alien | self addShapeForAlien: alien ].
]

{ #category : 'initialization' }
AlienInvadersView >> buildCanvas [
    canvas := RSCanvas new color: Color black.
    self buildPlayerShape.
    self buildAlienShapes.
    self buildHUD.
    canvas zoomToFit.
]

{ #category : 'initialization' }
AlienInvadersView >> buildHUD [
    scoreLabel := RSLabel new
        text: 'Score: 0';
        color: Color white;
        fontSize: 16;
        position: 50 @ 20;
        yourself.
    livesLabel := RSLabel new
        text: 'Lives: 3';
        color: Color white;
        fontSize: 16;
        position: 750 @ 20;
        yourself.
    canvas add: scoreLabel.
    canvas add: livesLabel.
]

{ #category : 'initialization' }
AlienInvadersView >> buildPlayerShape [
    playerShape := RSBox new
        size: 30 @ 20;
        color: Color green;
        position: model player position;
        yourself.
    canvas add: playerShape.
]

{ #category : 'accessing' }
AlienInvadersView >> canvas [
    ^ canvas
]

{ #category : 'initialization' }
AlienInvadersView >> initializeWithModel: aModel [
    model := aModel.
    alienShapes := IdentityDictionary new.
    playerBulletShapes := IdentityDictionary new.
    alienBulletShapes := IdentityDictionary new.
    self buildCanvas.
    ^ self
]

{ #category : 'updating' }
AlienInvadersView >> syncAlienBullets [
    | active |
    active := model alienBullets asIdentitySet.
    (alienBulletShapes keys reject: [ :b | active includes: b ]) do: [ :gone |
        canvas removeShape: (alienBulletShapes at: gone).
        alienBulletShapes removeKey: gone ].
    model alienBullets do: [ :bullet |
        | shape |
        shape := alienBulletShapes at: bullet ifAbsent: [
            | s |
            s := RSBox new size: 3 @ 15; color: Color cyan; yourself.
            alienBulletShapes at: bullet put: s.
            canvas add: s.
            s ].
        shape position: bullet position ].
]

{ #category : 'updating' }
AlienInvadersView >> syncAliens [
    | living |
    living := model aliens asIdentitySet.
    (alienShapes keys reject: [ :a | living includes: a ]) do: [ :dead |
        canvas removeShape: (alienShapes at: dead).
        alienShapes removeKey: dead ].
    model aliens do: [ :alien |
        (alienShapes at: alien ifAbsent: [ self addShapeForAlien: alien ])
            position: alien position ].
]

{ #category : 'updating' }
AlienInvadersView >> syncGameOver [
    model gameOver ifFalse: [ ^ self ].
    gameOverLabel ifNil: [
        gameOverLabel := RSLabel new
            text: model endMessage;
            color: Color red;
            fontSize: 32;
            position: 400 @ 300;
            yourself.
        canvas add: gameOverLabel ].
]

{ #category : 'updating' }
AlienInvadersView >> syncHUD [
    scoreLabel text: 'Score: ', model score asString.
    livesLabel text: 'Lives: ', model lives asString.
]

{ #category : 'updating' }
AlienInvadersView >> syncPlayer [
    playerShape position: model player position.
    playerShape color: (model player isExploding
        ifTrue: [ Color red ]
        ifFalse: [ Color green ]).
]

{ #category : 'updating' }
AlienInvadersView >> syncPlayerBullets [
    | active |
    active := model playerBullets asIdentitySet.
    (playerBulletShapes keys reject: [ :b | active includes: b ]) do: [ :gone |
        canvas removeShape: (playerBulletShapes at: gone).
        playerBulletShapes removeKey: gone ].
    model playerBullets do: [ :bullet |
        | shape |
        shape := playerBulletShapes at: bullet ifAbsent: [
            | s |
            s := RSBox new size: 3 @ 15; color: Color yellow; yourself.
            playerBulletShapes at: bullet put: s.
            canvas add: s.
            s ].
        shape position: bullet position ].
]

{ #category : 'updating' }
AlienInvadersView >> update [
    self syncPlayer.
    self syncAliens.
    self syncPlayerBullets.
    self syncAlienBullets.
    self syncHUD.
    self syncGameOver.
    canvas signalUpdate.
]
