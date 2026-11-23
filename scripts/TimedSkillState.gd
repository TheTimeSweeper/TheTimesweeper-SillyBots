extends "res://mods-unpacked/TheTimesweeper-SillyBots/Scripts/SkillState.gd"

var duration = 1
var castTimeFraction = 0.5
var castEndTimeFraction = 1
var isCasting
var hasFired = false
var hasExited = false
var stopwatch

func _initTimes(duration_, castTimeFraction_ = 0.5, castEndTimeFraction_ = 1):
	duration = duration_
	castTimeFraction = castTimeFraction_
	castEndTimeFraction = castEndTimeFraction_

func _onUpdate(delta):
	super._onUpdate(delta)
	stopwatch += delta
	
	var fireStarted = stopwatch >= duration * castTimeFraction;
	var fireEnded = stopwatch >= duration * castEndTimeFraction;
	isCasting = false;

	if ((fireStarted && !fireEnded) || (fireStarted && fireEnded && !hasFired)):
		if !hasFired:
			hasFired = true
			_onCastEnter()
		isCasting = true;
		_onCastUpdate(delta)

	if (fireEnded && !hasExited):
		hasExited = true
		_onCastExit()

	if (stopwatch >= duration):
		_exitState()

func _onCastEnter():
	pass

func _onCastUpdate(delta):
	pass

func _onCastExit():
	pass

func _exitState():
	outer.setNextState(null)
