Class {
	#name : 'BaselineOfAlienInvaders',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfAlienInvaders',
	#package : 'BaselineOfAlienInvaders'
}

{ #category : 'baselines' }
BaselineOfAlienInvaders >> baseline: spec [
    <baseline>
    spec for: #common do: [
        spec baseline: 'Roassal' with: [
            spec repository: 'github://pharo-graphics/Roassal:v3/src' ].

        spec
            package: 'AlienInvaders-Model';
            package: 'AlienInvaders-View' with: [ spec requires: #('AlienInvaders-Model' 'Roassal') ];
            package: 'AlienInvaders-Controller' with: [ spec requires: #('AlienInvaders-Model' 'AlienInvaders-View') ];
            package: 'AlienInvaders-Tests' with: [ spec requires: 'AlienInvaders-Model' ].

        spec
            group: 'Core' with: #('AlienInvaders-Model' 'AlienInvaders-View' 'AlienInvaders-Controller');
            group: 'Tests' with: #('AlienInvaders-Tests');
            group: 'default' with: #('Core' 'Tests') ].
]
