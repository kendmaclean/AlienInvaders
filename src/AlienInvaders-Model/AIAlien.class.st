Class {
	#name : 'AIAlien',
	#superclass : 'Object',
	#instVars : [
		'position'
	],
	#category : 'AlienInvaders-Model',
	#package : 'AlienInvaders-Model'
}

{ #category : 'instance creation' }
AIAlien class >> at: aPoint [
    ^ self new position: aPoint; yourself
]

{ #category : 'accessing' }
AIAlien >> position [
    ^ position
]

{ #category : 'accessing' }
AIAlien >> position: aPoint [
    position := aPoint
]
