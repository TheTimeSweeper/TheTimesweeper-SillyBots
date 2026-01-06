class_name TeslaBot
extends Enemy

@onready var spawn_audio = $SpawnAudio
@onready var aim_indicator = $AimIndicator
@onready var shootAudio1 = $ShootAudio
@onready var shootAudio2 = $ShootAudio2
@onready var lightningScanCollision : CollisionShape2D = $LightningScanCollision
@onready var chargeSprite : AnimatedSprite2D = $ChargeSprite
@onready var primaryStateMachine = $PrimaryStateMachine

var default_skin_path = "res://mods-unpacked/TheTimesweeper-SillyBots/Tesla/sTesla.png"
# var red_skin_path = "res://Art/Characters/ShotgunnerRAM/Red 63x113.png"
# var blue_skin_path = "res://Art/Characters/ShotgunnerRAM/blue 63x113.png"
# var yellow_skin_path = "res://Art/Characters/ShotgunnerRAM/yellow 63x113.png"

var max_range = 150
var ai_can_shoot = false
var ai_move_timer = 0
var ai_shoot_timer = 0
var ai_target_point = Vector2.ZERO 

var reload_audio_preempt_interval = 0.25
var reload_audio_has_played = false

const lightning_scene = preload("res://mods-unpacked/TheTimesweeper-SillyBots/Assets/Tesla/LightningBolt.tscn")
const conductor_scene = preload("res://mods-unpacked/TheTimesweeper-SillyBots/Assets/Tesla/TeslaConductor.tscn")

var shoot_offset = 13
var facing_offset:
	get: return -shoot_offset if facing_left else shoot_offset
var facing_offset_position:
	get: return global_position + Vector2(facing_offset, 0)

var charge_sprite_offset = 11.275

var lightning_damage = 4
var lightning_damage_final_mult = 4

var charged_lightning_min_damage = 2
var charged_lightning_max_damage = 10
var charged_lightning_charge_time = 3

var lightning_max_range = 180
var lightning_walk_speed = 90
var lightning_travelTime = 0.1

var lightning_scan_radius_player = 10
var lightning_scan_radius_enemy = 2

var lightning_scan_radius:
	get: return lightning_scan_radius_player if is_player else lightning_scan_radius_enemy

var secondary_base_cooldown = 2

var condcutor_throw_distance = 69

var allowed_conductors = 3
var thrown_conductors = []

var holding_primary = false
# Called when the node enters the scene tree for the first time.
func _ready():
	
	enemy_type = GameManager.teslabotIndex
	if not is_previous_floor_host: max_health = 75
	accel = 10
	max_speed = 120
	#bullet_spawn_offset = 13
	#vertical_bullet_spawn_offset = -3
	flip_offset = -4
	max_special_cooldown = 1.5
	#attack_cooldown_audio_preempt = 0.2
	aim_indicator.visible = false
	chargeSprite.visible = false
	default_skin = default_skin_path
	on_swapped_into.connect(update_conductors)
	super._ready()
	
func toggle_playerhood(state):
	super(state)
	update_aim_indicator_visibility()
		
func update_aim_indicator_visibility():
	# aim_indicator.visible = should_show_aim_indicator()
	pass
	
func should_show_aim_indicator():
	return super() and SaveManager.settings.steeltoe_aiming_reticle
	
# As far as I can tell here state is really is_player?
func toggle_enhancement(state):
	var level = 1 if is_player else 0
	super.toggle_enhancement(state)
	
func misc_update(delta):
	super.misc_update(delta)

	primaryStateMachine.update(delta)

func update_conductors():
	for conductor in thrown_conductors:
		if conductor != null && is_instance_valid(conductor):
			conductor.update_appearance(is_player)

func _physics_process(delta):
	super._physics_process(delta)
	if dead:
		for conductor in thrown_conductors:
			if conductor != null && is_instance_valid(conductor):
				conductor.queue_free()
	if was_recently_player():
		update_conductors()
	else:
		holding_primary = false

func player_action():

	holding_primary = Input.is_action_pressed("attack1")
	
	if holding_primary:
		charge_shoot()
		
	if Input.is_action_just_released("attack2") and special_cooldown < 0:
		throw_conductor()
		
	update_aim_indicators()

func charge_shoot():
	if not primaryStateMachine.currentState:
		var state = ChargeLightning.new()
		state.selfEnemy = self
		primaryStateMachine.setState(state)
		# attack_cooldown = state.baseDuration

func shoot():
	if not primaryStateMachine.currentState:
		var state = FireLightning.new()
		state.selfEnemy = self
		primaryStateMachine.setState(state)
		attack_cooldown = state.baseDuration
	
func _on_animation_finished(anim_name):
	super(anim_name)
	if anim_name == "Special":
		attacking = false
	
func throw_conductor():
	special_cooldown = secondary_base_cooldown
	attacking = true
	if !holding_primary:
		play_animation("Special")
	var conductor = conductor_scene.instantiate()
	thrown_conductors.push_back(conductor)
	conductor.global_position = facing_offset_position
	conductor.causality.set_source(self)
	conductor.destination = global_position + (aim_direction.normalized() * condcutor_throw_distance)

	if check_conductor_count() > allowed_conductors:
		kill_conductor()

	Util.set_object_elevation(conductor, Util.elevation_from_z_index(z_index))
	GameManager.call_deferred('add_entity_to_scene_tree',  conductor, get_parent() , facing_offset_position)

func check_conductor_count():
	var count = 0
	for conductor in thrown_conductors:
		if conductor == null:
			continue
		count += 1
	return count

func remove_conductor(toRemove):
	var size = thrown_conductors.size()
	for i in size:
		if thrown_conductors[i] == toRemove:
			thrown_conductors.remove_at(i)
			return

func kill_conductor():
	var size = thrown_conductors.size()
	for i in size:
		var last = thrown_conductors.pop_front()
		if last == null:
			continue
		last.queue_free()
		return

# func handle_legacy_elite_skins():
# 	if 'induction_barrel' in upgrades:
# 		sprite.texture = load(red_skin_path)
# 	elif "soldering_fingers" in upgrades:
# 		sprite.texture = load(blue_skin_path)
# 		#TODO Maybe pick a better upgrade?
# 	elif "stacked_shells" in upgrades:
# 		sprite.texture = load(yellow_skin_path)

# func handle_skin():
# 	enemy_fx.get_node("CASHParticles").emitting = false
# 	if not upgrades.is_empty():
# 		if 'induction_barrel' in upgrades:
# 			sprite.texture = Util.get_cached_texture(red_skin_path)
# 			return
# 		if "soldering_fingers" in upgrades:
# 			sprite.texture = Util.get_cached_texture(blue_skin_path)
# 			return
# 			#TODO Maybe pick a better upgrade?
# 		if "stacked_shells" in upgrades:
# 			sprite.texture = Util.get_cached_texture(yellow_skin_path)
# 			return
# 	elif is_player:
# 		if GameManager.player_steeltoe_skin_path != "":
# 			sprite.texture = Util.get_cached_texture(GameManager.player_steeltoe_skin_path)
# 			if GameManager.player_steeltoe_skin_path.contains("CASH"):
# 				enemy_fx.get_node("CASHParticles").emitting = true
# 			else:
# 				enemy_fx.get_node("CASHParticles").emitting = false
# 			return
# 	sprite.texture = Util.get_cached_texture(default_skin_path)
# 	super.handle_skin()
	
func finish_spawning():
	super()
	update_aim_indicator_visibility()

# func show_muzzle_flash():
# 	muzzle_flash.rotation = aim_direction.angle();
# 	muzzle_flash.show_behind_parent = muzzle_flash.rotation < deg_to_rad(-30) and muzzle_flash.rotation > deg_to_rad(-150)
# 	muzzle_flash.frame = 0
# 	muzzle_flash.play("Flash")
# 	gun_particles.position.x = -13 if facing_left else 13
# 	gun_particles.rotation = muzzle_flash.rotation
# 	gun_particles.emitting = true
	
func die(attack):
	super(attack)
	aim_indicator.visible = false

func revive():
	super()
	if SaveManager.settings.steeltoe_aiming_reticle and is_player:
		aim_indicator.visible = true

func update_look_direction(dir):
	super.update_look_direction(dir)
	chargeSprite.position.x = -charge_sprite_offset if facing_left else charge_sprite_offset

	
func update_aim_indicators():
	# aim_indicator.set_spread(deg_to_rad(bullet_spread*loaded_shells))
	aim_indicator.set_direction(aim_direction)

func fire_lightning(lightningParams):
	
	var lightningBolt = TeslaBot.lightning_scene.instantiate()

	Util.set_object_elevation(lightningBolt, Util.elevation_from_z_index(lightningParams.source.z_index))
	GameManager.call_deferred('add_entity_to_scene_tree',  lightningBolt, lightningParams.source.get_parent() , Vector2.ZERO)

	lightningBolt._fire(lightningParams)

func create_lightningboltparams():
	return LightningBoltParams.new()


class ChargeLightning extends "res://mods-unpacked/TheTimesweeper-SillyBots/Scripts/SkillState.gd":
	var selfEnemy
	var charge

	func _onEnter():
		selfEnemy.play_animation("Charge_Loop")
		selfEnemy.apply_effect(EffectType.SPEED_OVERRIDE, selfEnemy, selfEnemy.lightning_walk_speed)
		selfEnemy.attacking = true
		selfEnemy.chargeSprite.visible = true
		selfEnemy.chargeSprite.frame = 0
		selfEnemy.chargeSprite.play("default")

	func _onUpdate(delta):
		super._onUpdate(delta)

		if !selfEnemy.holding_primary:
			release()
		if !selfEnemy.was_recently_player() && age > selfEnemy.charged_lightning_charge_time:
			release() 

	func release():
		var newState = FireLightning.new()
		newState.selfEnemy = selfEnemy
		var clampedAge = clamp(age, 0, selfEnemy.charged_lightning_charge_time)
		newState.damage = lerp(selfEnemy.charged_lightning_min_damage, selfEnemy.charged_lightning_max_damage, clampedAge/selfEnemy.charged_lightning_charge_time)

		outer.setState(newState)
	func _onExit():
		selfEnemy.cancel_effect(EffectType.SPEED_OVERRIDE, selfEnemy)
		selfEnemy.chargeSprite.visible = false

class FireLightning extends "res://mods-unpacked/TheTimesweeper-SillyBots/Scripts/SkillState.gd":
	var selfEnemy : TeslaBot = null

	var interval = 0.12
	var shots = 5
	var baseDuration = 0.9

	var timer = 0
	var shotsFired = 0

	var scanCollision : CollisionShape2D
	var excluded
	var mask
	var space_state
	var query
	var damage

	func _onEnter():
		selfEnemy.attacking = true
		selfEnemy.play_animation("Shoot")
		selfEnemy.apply_effect(EffectType.SPEED_OVERRIDE, selfEnemy, selfEnemy.lightning_walk_speed)

		scanCollision = selfEnemy.lightningScanCollision
		scanCollision.shape.height = selfEnemy.lightning_max_range
		scanCollision.shape.radius = selfEnemy.lightning_scan_radius

		excluded = selfEnemy.get_node('Hitbox')
		mask = 4 | Util.bullet_collision_layers[selfEnemy.elevation]
		
		space_state = selfEnemy.get_world_2d().direct_space_state
		query = PhysicsShapeQueryParameters2D.new()
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.collision_mask = mask
		query.exclude = [excluded]

		if !damage:
			damage = selfEnemy.lightning_damage

		if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and selfEnemy.is_player:
			Input.start_joy_vibration(0, 1, 0.2, baseDuration)
			
		if Input.is_key_pressed(KEY_G):
			shots = 1
			selfEnemy.lightning_travelTime = 1
		else:
			selfEnemy.lightning_travelTime = 0.1

	# attack speed?
	func _onUpdate(delta):
		super._onUpdate(delta)

		if age > baseDuration:
			outer.setState(null)
			return;

		timer -= delta
		while timer <= 0 && shotsFired < shots:
			shotsFired += 1
			shoot_lightning()
			timer += interval

	func _onExit():
		selfEnemy.attacking = false
		selfEnemy.cancel_effect(EffectType.SPEED_OVERRIDE, selfEnemy)
	
	func shoot_lightning():
		
		# selfEnemy.shootAudio2.play()

		var toPosition = selfEnemy.global_position + (selfEnemy.aim_direction.normalized() * selfEnemy.lightning_max_range)

		var resultPosition = toPosition

		scanCollision.global_position = selfEnemy.global_position + (toPosition - selfEnemy.global_position)/2
		scanCollision.global_rotation = selfEnemy.aim_direction.angle() + PI*0.5
		query.set_shape(scanCollision.shape)
		query.transform = scanCollision.global_transform
		var results = space_state.intersect_shape(query, 512)

		var targetCastResult = find_best_result(results)

		var entity = null
		if targetCastResult:
			entity = targetCastResult
			resultPosition = entity.global_position
		
		var startpos = selfEnemy.facing_offset_position
		var params = LightningBoltParams.new()
		params.source = selfEnemy
		params.damage = damage * (selfEnemy.lightning_damage_final_mult if shotsFired == shots else 1) 
		params.travelTime = selfEnemy.lightning_travelTime
		params.startPosition = startpos
		params.destination = resultPosition
		params.target = entity
		params.remainingBounces = 1
		params.finalBolt = (shotsFired == shots)
		params.widthMult = damage / selfEnemy.lightning_damage

		selfEnemy.fire_lightning(params)

	func find_best_result(results):
		var testAttack = Attack.new(selfEnemy)
		testAttack.add_tag(Attack.Tag.ELECTRIC)

		var closestAngle = 10
		var closestPosition = 1000
		# var closestPositionTarget

		var bestTargetResult

		var aimVector : Vector2 = selfEnemy.aim_direction.normalized()

		for result in results:
			var checkResult = result.collider
			if checkResult.is_in_group('hitbox'):
				checkResult = checkResult.get_parent()
			if !checkResult.has_method('can_be_hit') || !checkResult.can_be_hit(testAttack):
				continue
			var angle = aimVector.angle_to(checkResult.global_position - selfEnemy.global_position)
			var position = checkResult.global_position.distance_squared_to(selfEnemy.global_position)
			var found
			if(angle < closestAngle + 0.2):
				if(angle < closestAngle):
					closestAngle = angle
					found = true
				if(position < closestPosition):
					found = true
				if(found):
					bestTargetResult = checkResult

		return bestTargetResult
			


#lightningbolt params was in its own class_name file
class LightningBoltParams:
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
	var widthMult = 1

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
		dup.widthMult = widthMult
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
