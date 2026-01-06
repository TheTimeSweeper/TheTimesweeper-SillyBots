extends Node 

var currentState = null
var nextState

func setState(state):
	nextState = state

func update(delta):

	if(nextState != currentState):
		if currentState:
			currentState._onExit()
		if nextState:
			nextState.outer = self
			nextState._onEnter()
		currentState = nextState
		
	if currentState:
		currentState._onUpdate(delta)
	pass
