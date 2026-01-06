extends Enemy

#@onready var aim_indicator = $AimIndicator

var default_skin_path = "res://mods-unpacked/TheTimesweeper-SillyBots/Tesla/sTesla.png"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# enemy_type = GameManager.baseBotIndex
	if not is_previous_floor_host: max_health = 75
	accel = 10
	max_speed = 120
	#bullet_spawn_offset = 13
	#vertical_bullet_spawn_offset = -3
	flip_offset = -4#teslabot sprite
	max_special_cooldown = 1.5
	#attack_cooldown_audio_preempt = 0.2
	#aim_indicator.visible = false
	default_skin = default_skin_path
	super._ready()

# As far as I can tell here state is really is_player?
func toggle_enhancement(state):
	var level = 1 if is_player else 0
	super.toggle_enhancement(state)
	
func misc_update(delta):
	super.misc_update(delta)
	
func _physics_process(delta):
	super._physics_process(delta)
	
func player_action():

	if Input.is_action_just_pressed("attack1"):
		shoot_primary()
		
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0:
		shoot_special()
		
	#update_aim_indicators()

func shoot_primary():
	pass

func shoot_special():
	pass

	
func _on_animation_finished(anim_name):
	super(anim_name)
	if anim_name == "Special":
		attacking = false
