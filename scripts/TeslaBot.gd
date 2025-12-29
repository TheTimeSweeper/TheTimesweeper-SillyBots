class_name TeslaBot
extends Enemy

@onready var muzzle_flash = $MuzzleFlash
@onready var spawn_audio = $SpawnAudio
@onready var melee_collider_shape = $MeleeCollider/CollisionShape2D
@onready var aim_indicator = $AimIndicator
@onready var shootAudio1 = $ShootAudio
@onready var shootAudio2 = $ShootAudio2

var default_skin_path = "res://mods-unpacked/TheTimesweeper-SillyBots/Tesla/sTesla.png"
var red_skin_path = "res://Art/Characters/ShotgunnerRAM/Red 63x113.png"
var blue_skin_path = "res://Art/Characters/ShotgunnerRAM/blue 63x113.png"
var yellow_skin_path = "res://Art/Characters/ShotgunnerRAM/yellow 63x113.png"

var max_range = 150
var ai_can_shoot = false
var ai_move_timer = 0
var ai_shoot_timer = 0
var ai_target_point = Vector2.ZERO 

var self_parry_damage_due = false

var charging_melee := false
var melee_charge_duration = 0.3
var melee_charge_timer := 0.0

var reload_audio_preempt_interval = 0.25
var reload_audio_has_played = false

const lightning_scene = preload("res://mods-unpacked/TheTimesweeper-SillyBots/Tesla/LightningBolt.tscn")
const conductor_scene = preload("res://mods-unpacked/TheTimesweeper-SillyBots/Tesla/TeslaConductor.tscn")

var shoot_offset = 13
var facing_offset:
	get: return -shoot_offset if facing_left else shoot_offset
var facing_offset_position:
	get: return global_position + Vector2(facing_offset, 0)

var primaryStateMachine

var lightning_damage = 6
var lightning_damage_final = 12
var lightning_travelTime = 0.1

var secondary_base_cooldown = 0.5

var condcutor_throw_distance = 69

var allowed_conductors = 3
var thrown_conductors = []
# Called when the node enters the scene tree for the first time.
func _ready():
	
	primaryStateMachine = SkillStateMachine.new()
	enemy_type = GameManager.teslabotIndex
	if not is_previous_floor_host: max_health = 75
	accel = 10
	max_speed = 160
	bullet_spawn_offset = 10
	vertical_bullet_spawn_offset = -3
	flip_offset = 0
	max_special_cooldown = 1.5
	attack_cooldown_audio_preempt = 0.2
	aim_indicator.visible = false
	default_skin = default_skin_path
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

func player_action():
	if Input.is_action_pressed("attack1"):
		shoot()
		
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0:
		throw_conductor()
		
	update_aim_indicators()

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

func kill_conductor():
	var size = thrown_conductors.size()
	for i in size:
		var last = thrown_conductors.pop_front()
		if last == null:
			continue
		last.queue_free()
		return

func handle_legacy_elite_skins():
	if 'induction_barrel' in upgrades:
		sprite.texture = load(red_skin_path)
	elif "soldering_fingers" in upgrades:
		sprite.texture = load(blue_skin_path)
		#TODO Maybe pick a better upgrade?
	elif "stacked_shells" in upgrades:
		sprite.texture = load(yellow_skin_path)

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

func show_muzzle_flash():
	muzzle_flash.rotation = aim_direction.angle();
	muzzle_flash.show_behind_parent = muzzle_flash.rotation < deg_to_rad(-30) and muzzle_flash.rotation > deg_to_rad(-150)
	muzzle_flash.frame = 0
	muzzle_flash.play("Flash")
	gun_particles.position.x = -13 if facing_left else 13
	gun_particles.rotation = muzzle_flash.rotation
	gun_particles.emitting = true
	
func die(attack):
	super(attack)
	aim_indicator.visible = false

func revive():
	super()
	if SaveManager.settings.steeltoe_aiming_reticle and is_player:
		aim_indicator.visible = true

	
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

class FireLightning extends SkillState:
	var selfEnemy = null

	var interval = 0.12
	var shots = 5
	var baseDuration = 0.9
	var maxRange = 300

	var timer = 0
	var shotsFired = 0

	var shapeCast2D : ShapeCast2D
	var excluded
	var mask

	func _onEnter():
		selfEnemy.attacking = true
		selfEnemy.play_animation("Shoot")
		shapeCast2D = selfEnemy.get_node("ShapeCast2D")
		excluded = selfEnemy.get_node('Hitbox')
		mask = 4 | Util.bullet_collision_layers[selfEnemy.elevation]

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
	
	func shoot_lightning():
		
		# selfEnemy.shootAudio2.play()

		var toPosition = selfEnemy.global_position + (selfEnemy.aim_direction.normalized() * maxRange)

		var resultCollider
		var resultPosition = toPosition
		
		# raycast first, for most accurate aim
		var space_state = selfEnemy.get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.new()
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.collision_mask = mask
		query.exclude = [excluded]
		query.from = selfEnemy.global_position
		query.to = toPosition

		var result = space_state.intersect_ray(query)
		if result: 
			resultCollider = result.collider
			resultPosition = result.position
		# if raycast misses do a sphere cast for leniency
		else:
			shapeCast2D.collision_mask = mask
			shapeCast2D.add_exception(excluded)
			# guess now that it's a child node I don't need this
			# shapeCast2D.global_position = selfEnemy.global_position
			shapeCast2D.target_position = toPosition
			shapeCast2D.force_shapecast_update()

			if shapeCast2D.is_colliding():
				resultCollider = shapeCast2D.get_collider(0)
				resultPosition = shapeCast2D.get_collision_point(0)

		var startpos = selfEnemy.facing_offset_position

		var entity = null
		if resultCollider:
			if resultCollider.is_in_group('hitbox'):
				entity = resultCollider.get_parent()
				resultPosition = entity.global_position
			# if resultCollider is TeslaConductor:
			# 	entity = resultCollider
			# 	resultPosition = entity.global_position
		var params = LightningBoltParams.new()
		params.source = selfEnemy
		params.damage = selfEnemy.lightning_damage_final if shotsFired == shots else selfEnemy.lightning_damage 
		params.travelTime = selfEnemy.lightning_travelTime
		params.startPosition = startpos
		params.destination = resultPosition
		params.target = entity
		params.remainingBounces = 1
		params.finalBolt = (shotsFired == shots)

		selfEnemy.fire_lightning(params)

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
#skillstate stuff cause I can't have them in different classes
# future me can deal with that

class TimedSkillState:
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
		
class SkillState:

	var outer
	var age = 0
	func _onEnter():
		pass

	func _onUpdate(delta):
		age += delta

	func _onExit():
		pass

class SkillStateMachine: 

	var currentState = SkillState.new()
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
