Class {
	#name : 'AIBullet',
	#superclass : 'Object',
	#instVars : [
		'position',
		'velocity'
	],
	#category : 'AlienInvaders-Model',
	#package : 'AlienInvaders-Model'
}

{ #category : 'instance creation' }
AIBullet class >> alienBulletAt: aPoint [
    ^ self new position: aPoint; velocity: 0 @ 5; yourself
]

{ #category : 'instance creation' }
AIBullet class >> playerBulletAt: aPoint [
    ^ self new position: aPoint; velocity: 0 @ -8; yourself
]

{ #category : 'testing' }
AIBullet >> isOffScreen [
    ^ position y < 0 or: [ position y > 600 ]
]

{ #category : 'accessing' }
AIBullet >> position [
    ^ position
]

{ #category : 'accessing' }
AIBullet >> position: aPoint [
    position := aPoint
]

{ #category : 'movement' }
AIBullet >> tick [
    position := position + velocity
]

{ #category : 'accessing' }
AIBullet >> velocity: aPoint [
    velocity := aPoint
]
