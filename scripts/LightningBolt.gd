extends Node2D

@export var travelCurve : Curve
@export var orthogonalCurve : Curve

@onready var shootAudio2 = get_node("ShootAudio2")

var lightningBoltParams : LightningBoltParams

var target:
	get: return lightningBoltParams.target
var remainingBounces:
	get: return lightningBoltParams.remainingBounces
	set(value): lightningBoltParams.remainingBounces = value
var alreadyBounced:
	get: return lightningBoltParams.alreadyBounced
var finalBolt:
	get: return lightningBoltParams.finalBolt

var travelTime
var startPosition
var destination

# Assigned here
var pointIntervalDistance = 20
var pointVariance = 5
var orthogonalDistance = 12

# used and modified in code
var timer = 0
var lingerTime = 0.5
var currentLinePoint = 1
var hasArrived = false

# calculated in code
var totalDistance
var totalIntervals
var lerpInterval
var direction
var startWidth

# used in code
var attack
var line2d : Line2D

func _fire(fireLightningBoltParams):
	lightningBoltParams = fireLightningBoltParams

	attack = Attack.new(lightningBoltParams.source, lightningBoltParams.damage, 0)
	attack.add_tag(Attack.Tag.ELECTRIC)

	travelTime = lightningBoltParams.travelTime
	startPosition = lightningBoltParams.startPosition
	destination = lightningBoltParams.destination

	global_position = Vector2.ZERO

	line2d = get_node("LightningTrail")
	line2d.points = [startPosition]
	line2d.default_color = lightningBoltParams.color
	if lightningBoltParams.finalBolt:
		line2d.width *= 3
	startWidth = line2d.width

	totalDistance = startPosition.distance_to(destination)
	totalIntervals = floor(totalDistance/pointIntervalDistance)
	lerpInterval = 1.0/totalIntervals
	direction = (destination - startPosition).normalized()

	var trauma_add = attack.damage * 0.005
	var trauma_min = attack.damage * 0.01

	if attack.causality.source.is_player:
		GameManager.camera.set_trauma(max(GameManager.camera.trauma + trauma_add, trauma_min), 10)

	if attack.can_hit(target) && remainingBounces > -1:
		fireNewBolt(false, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	timer+=delta

	if target && is_instance_valid(target):
		destination = target.global_position

	if(timer >= travelTime + lingerTime):
		queue_free()

	var traveled = clamp(timer/travelTime, 0, 1)
	var t = travelCurve.sample(traveled)

	line2d.width = lerp(startWidth, 0.0, (timer/(travelTime + lingerTime)) + randf_range(-0.1, 0.1))

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
		
	if(timer >= travelTime && !hasArrived):
		hasArrived = true
		shootAudio2.play()
		if target && is_instance_valid(target):
			var attack_hit = attack.inflict_on(target)
			if (attack_hit) && remainingBounces > 0:
				remainingBounces -= 1
				fireNewBolt()
			if false: # target is TeslaConductor:
				# don't spend a bounce on conductors
				fireNewBolt()
				# fireNewBolt(true) likely an upgrade calls this
				if finalBolt:
					fireNewBolt(true)
					target.take_hit()
				# if target not in alreadyBounced:
				# 	remainingBounces += 2 # when bouncing on conductor, extend charge
				# else:
				# 	remainingBounces += 1 # already bounced off this. allow bounce again, but dont lose charge
			

	# global_position = startPosition.lerp(destination, t)
	# line2d.points[currentLinePoint] = startPosition.lerp(destination, t)
				
func fireNewBolt(all = false, oll = false):
	alreadyBounced.append(target)
	# get all nearby enemies
	var enemy_candidates = Violence.get_targetable_enemies_in_radius(attack.causality.source, destination, 100)
	enemy_candidates.shuffle()
	var enemy_candidates_free = []
	var enemy_candidates_used = []
	# split them into lists based on if they've been bounced or not
	for enemy in enemy_candidates:
		if enemy in alreadyBounced: 
			enemy_candidates_used.append(enemy)
		else:
			enemy_candidates_free.append(enemy)

	# get all conductors
	var conductor_candidates = TeslaConductor.instances_list.duplicate()
	conductor_candidates.shuffle()
	var conductor_candidates_free = []
	var conductor_candidates_used = []
	# filter if they're close enough, and split them into lists as above
	for conductor in conductor_candidates:
		if conductor.global_position.distance_to(destination) > 100:
			continue
		if conductor in alreadyBounced: 
			conductor_candidates_used.append(conductor)
		else:
			conductor_candidates_free.append(conductor)

	# prioritize targets in this order
	var candidates = conductor_candidates_free + enemy_candidates_free + enemy_candidates_used + (conductor_candidates_used if not all else []) 
	var finalCandidate = null
	for candidate in candidates:
		# if candidate in alreadyBounced && not candidate is TeslaConductor: continue
		if candidate == attack.causality.source: continue
		if candidate == target: continue
		# fire from all nearby conductors to the current target
		if candidate is TeslaConductor && oll:
			
			# todo pull this out of the for loop but also do the `all` thing a little better
			var params = LightningBoltParams.new()
			params.source = attack.causality.source
			params.damage = attack.damage
			params.travelTime = TeslaBot.lightning_travelTime
			params.startPosition = candidate.global_position
			params.destination = destination
			params.target = target
			params.remainingBounces = -1
			params.alreadyBounced = []
			params.color = Color(0, 1, 1, 1)

			SillyViolence.fire_lightning(params)
		else: if all:
			
			# todo pull this out of the for loop but also do the `all` thing a little better
			var params = LightningBoltParams.new()
			params.source = attack.causality.source
			params.damage = attack.damage
			params.travelTime = TeslaBot.lightning_travelTime
			params.startPosition = destination
			params.destination = candidate.global_position
			params.target = candidate
			params.remainingBounces = 0
			params.alreadyBounced = alreadyBounced
			params.color = Color(0, 1, 1, 1)

			SillyViolence.fire_lightning(params)
		else: if not candidate is TeslaConductor:
			finalCandidate = candidate
			break

	if finalCandidate && !oll:
		
		var params = lightningBoltParams.duplicate().chain(destination, finalCandidate.global_position, finalCandidate)

		SillyViolence.fire_lightning(params)

