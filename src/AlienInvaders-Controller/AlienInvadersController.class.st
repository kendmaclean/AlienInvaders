Class {
	#name : 'AlienInvadersController',
	#superclass : 'Object',
	#instVars : [
		'model',
		'view',
		'animation',
		'leftKeyPressed',
		'rightKeyPressed'
	],
	#category : 'AlienInvaders-Controller',
	#package : 'AlienInvaders-Controller'
}

{ #category : 'instance creation' }
AlienInvadersController class >> open [
    self new start
]

{ #category : 'input' }
AlienInvadersController >> handleKeyDown: evt [
    model gameOver ifTrue: [ ^ self ].
    evt keyValue = 28 ifTrue: [ leftKeyPressed := true ].
    evt keyValue = 29 ifTrue: [ rightKeyPressed := true ].
    evt keyValue = 32 ifTrue: [ model shootPlayerBullet ].
]

{ #category : 'input' }
AlienInvadersController >> handleKeyUp: evt [
    evt keyValue = 28 ifTrue: [ leftKeyPressed := false ].
    evt keyValue = 29 ifTrue: [ rightKeyPressed := false ].
]

{ #category : 'input' }
AlienInvadersController >> setupKeyHandlers [
    view canvas
        when: RSKeyDown do: [ :evt | self handleKeyDown: evt ] for: self;
        when: RSKeyUp do: [ :evt | self handleKeyUp: evt ] for: self.
]

{ #category : 'initialization' }
AlienInvadersController >> start [
    model := AlienInvadersModel new.
    view := AlienInvadersView new initializeWithModel: model.
    leftKeyPressed := false.
    rightKeyPressed := false.
    self setupKeyHandlers.
    self startAnimation.
    view canvas open
        setLabel: 'Alien Invaders';
        extent: 800 @ 640.
]

{ #category : 'game loop' }
AlienInvadersController >> startAnimation [
    animation := view canvas newAnimation
        repeat;
        duration: 16 milliSeconds;
        onStepDo: [ :t | self tick ];
        yourself.
]

{ #category : 'game loop' }
AlienInvadersController >> tick [
    model gameOver ifTrue: [ ^ self ].
    leftKeyPressed ifTrue: [ model movePlayerLeft ].
    rightKeyPressed ifTrue: [ model movePlayerRight ].
    model tick.
    view update.
]
