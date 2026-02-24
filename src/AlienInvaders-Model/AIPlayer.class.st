Class {
	#name : 'AIPlayer',
	#superclass : 'Object',
	#instVars : [
		'position',
		'isExploding',
		'explodingTicksRemaining'
	],
	#category : 'AlienInvaders-Model',
	#package : 'AlienInvaders-Model'
}

{ #category : 'initialization' }
AIPlayer >> initialize [
    position := 400 @ 550.
    isExploding := false.
    explodingTicksRemaining := 0.
]

{ #category : 'accessing' }
AIPlayer >> isExploding [
    ^ isExploding
]

{ #category : 'accessing' }
AIPlayer >> position [
    ^ position
]

{ #category : 'accessing' }
AIPlayer >> position: aPoint [
    position := aPoint
]

{ #category : 'explosion' }
AIPlayer >> startExploding [
    isExploding := true.
    explodingTicksRemaining := 13.
]

{ #category : 'explosion' }
AIPlayer >> tickExplosion [
    explodingTicksRemaining := explodingTicksRemaining - 1.
    explodingTicksRemaining <= 0 ifTrue: [
        isExploding := false.
        ^ true ].
    ^ false
]
