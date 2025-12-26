class_name TimedSkillState 
extends SkillState

var duration = 1
var castTimeFraction = 0.5
var hasCasted = false

func _initTimes(duration_, castTimeFraction_ = 0.5):
	duration = duration_
	castTimeFraction = castTimeFraction_

func _onUpdate(delta):
	super._onUpdate(delta)
	
	if(age >= duration * castTimeFraction):
		if not hasCasted:
			hasCasted = true
			_onCastEnter()
		_onCastUpdate(delta)

	if (age >= duration):
		_onCastExit()

func _onCastEnter():
	pass

func _onCastUpdate(delta):
	pass

func _onCastExit():
	outer.setNextState(null)
