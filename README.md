Load into the Pharo Image

Open a Playground in the Pharo image and evaluate:

```smalltalk
Metacello new
    baseline: 'AlienInvaders';
    repository: 'github://kendmaclean/AlienInvaders:master/src';
    load.
```
To Run (from Playground):

```smalltalk
AlienInvadersController new start
```
