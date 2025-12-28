class_name LightningBoltParams

var source
var damage
var travelTime
var startPosition
var destination
var target
var remainingBounces
var alreadyBounced = []
var finalBolt = false

var color = Color(1, 1, 1, 1)

func duplicate():
	var dup = LightningBoltParams.new()
	dup.source = source
	dup.damage = damage
	dup.travelTime = travelTime
	dup.startPosition = startPosition
	dup.destination = destination
	dup.target = target
	dup.remainingBounces = remainingBounces
	dup.alreadyBounced = alreadyBounced
	dup.finalBolt = finalBolt
	dup.color = color
	return dup

func chain(startPosition_, destination_, target_):
	startPosition = startPosition_
	destination = destination_
	target = target_
	return self

func set_destination(new_destination):
	destination = new_destination
	return self
func set_startPosition(new_startPosition):
	startPosition = new_startPosition
	return self
func set_target(new_target):
	target = new_target
	return self

func set_color(new_color):
	color = new_color
	return self
