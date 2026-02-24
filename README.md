# Load into the Pharo Image

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

# Claude Code - coding notes

(see [boris tane article: How I use Claude Code](https://boristane.com/blog/how-i-use-claude-code/) )

This game started out as a single class working game that I used Claude AI (website) to create.  I used Claude Code and the [Balise MCP](https://github.com/kendmaclean/Balise) to implement and test these changes

## Phase 1: Research

Claude Prompt:

>read this AlienInvaders* package in depth, understand how it works deeply, what it does and all its specificities. when that’s done, write a detailed report of your learnings and findings in research.md

The creates a [research.md](research.md) file in your images folder (e.g. '~/Pharo/images/AlienInvaders Pharo 12.0 - 64bit (stable)')

## Phase 2: Planning

Don't use Claude Code's plan mode, just prompt it with:

>I want to refactor the AlienInvadersGame to use Model View Controller architecture. write a detailed plan.md document outlining how to implement this. include code snippets

The [plan.md](plan.md) doc can then be edited and is a good reference document of what was done.

I reviewed the plan, answered Claude's questions, made some minor notes, and the prompted Claude with: 

> I added a few notes to the document, address all the notes and update the document accordingly. don’t implement yet
> 
The “don’t implement yet” guard is important, otherwise Claude will start generating code and waste tokens.

I only needed to repeat to do this once in this case, it is a simple task.

Lastely, tell Claude to update the plan with a checklist:

>add a detailed todo list to the plan, with all the phases and individual tasks necessary to complete the plan - don’t implement yet

## Phase 3: Implementation
prompt Claude with:

>implement it all. when you’re done with a task or phase, mark it as completed in the plan document. do not stop until all tasks and phases are completed. do not add unnecessary comments. continuously review code-critique to make sure you’re not introducing new issues.
