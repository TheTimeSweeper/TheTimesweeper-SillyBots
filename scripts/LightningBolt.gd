extends Node2D

@export var travelCurve : Curve
@export var orthogonalCurve : Curve

var travelTime
var startPosition
var destination
var target
var remainingBounces
var exclude

var pointIntervalDistance = 20
var pointVariance = 5
var orthogonalDistance = 12

var timer = 0
var lingerTime = 0.5
var currentLinePoint = 1
var totalDistance
var totalIntervals
var lerpInterval
var direction

var attack

var hasArrived

var line2d

func _fire(fireSource, fireDamage, firetravelTime, fireStartPosition, fireDestination, fireTarget, fireRemainingBounces, fireExclude = []):
	startPosition = fireStartPosition
	destination = fireDestination
	travelTime = firetravelTime
	target = fireTarget
	exclude = fireExclude
	if target: destination = target.global_position
	remainingBounces = fireRemainingBounces

	attack = Attack.new(fireSource, fireDamage, 0)
	attack.add_tag(Attack.Tag.ELECTRIC)

	global_position = Vector2.ZERO

	line2d = get_node("LightningTrail")
	line2d.points = [startPosition]

	totalDistance = startPosition.distance_to(destination)
	totalIntervals = floor(totalDistance/pointIntervalDistance)
	lerpInterval = 1.0/totalIntervals
	direction = (destination - startPosition).normalized()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	timer+=delta

	if target && is_instance_valid(target):
		destination = target.global_position

	if(timer >= travelTime + lingerTime):
		queue_free()

	var traveled = clamp(timer/travelTime, 0, 1)
	var t = travelCurve.sample(traveled)

	while(t >= lerpInterval * currentLinePoint):
		var endLastInterval = lerpInterval * currentLinePoint
		var point = startPosition.lerp(destination, endLastInterval)
		point += Vector2(randf_range(-pointVariance, pointVariance), randf_range(-pointVariance, pointVariance))
		var ortho = direction.orthogonal()
		# make the perpendicular variance generally go upwards
		if(ortho.normalized().dot(Vector2.UP) < 0):
			ortho *= -1
		point += ortho * orthogonalCurve.sample(endLastInterval) * orthogonalDistance
		# line2d.points[currentLinePoint] = point
		line2d.add_point(point)
		currentLinePoint += 1

		
	if(timer >= travelTime && target && is_instance_valid(target) && !hasArrived):
		var attack_hit = attack.inflict_on(target)
		hasArrived = true
		if target is TeslaConductor:
			if target not in exclude:
				remainingBounces += 2 # when bouncing on conductor, extend charge
			else:
				remainingBounces += 1 # already bounced off this. allow bounce again, but dont lose charge
		if (attack_hit || target is TeslaConductor) && remainingBounces > 0:
			fireNewBolt()
			

	# global_position = startPosition.lerp(destination, t)
	# line2d.points[currentLinePoint] = startPosition.lerp(destination, t)
				
func fireNewBolt():

	exclude.append(target)
	remainingBounces -= 1
	var enemy_candidates = Violence.get_targetable_enemies_in_radius(attack.causality.source, destination, 100)
	enemy_candidates.shuffle()
	var enemy_candidates_free = []
	var enemy_candidates_used = []
	for enemy in enemy_candidates:
		if enemy in exclude: 
			enemy_candidates_used.append(enemy)
		else:
			enemy_candidates_free.append(enemy)

	var conductor_candidates = TeslaConductor.instances_list.duplicate()
	conductor_candidates.shuffle()
	var conductor_candidates_free = []
	var conductor_candidates_used = []

	for conductor in conductor_candidates:
		if conductor.global_position.distance_to(destination) > 100:
			continue
		if conductor in exclude: 
			conductor_candidates_used.append(conductor)
		else:
			conductor_candidates_free.append(conductor)

	var candidates = conductor_candidates_free + enemy_candidates_free + enemy_candidates_used + conductor_candidates_used 
	var finalCandidate = null
	for candidate in candidates:
		# if candidate in exclude && not candidate is TeslaConductor: continue
		if candidate == attack.causality.source: continue
		if candidate == target: continue

		# temp until conductors are a thing
		if candidate is TeslaBot: 
			finalCandidate = candidate
			break

		finalCandidate = candidate
		break

	if finalCandidate:
		var lightningBolt = TeslaBot.lightning_scene.instantiate()
		attack.causality.source.get_parent().add_child(lightningBolt)
		
		lightningBolt._fire(attack.causality.source, attack.damage, TeslaBot.lightning_travelTime, destination, finalCandidate.global_position, finalCandidate, remainingBounces, exclude)

