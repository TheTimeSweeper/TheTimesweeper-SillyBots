extends Enemy

#@onready var aim_indicator = $AimIndicator
@onready var meleeRoot = $MeleeCollider
@onready var wideAttack = $MeleeCollider/WideAttack
@onready var longAttack = $MeleeCollider/LongAttack
@onready var areaAttack = $MeleeCollider/AreaAttack
@onready var melee_sprite_wide = $MeleeCollider/WideSwipeSprite
@onready var melee_sprite_long = $MeleeCollider/LongSwipeSprite
@onready var melee_sprite_area = $MeleeCollider/AreaSwipeSprite

var default_skin_path = "res://mods-unpacked/TheTimesweeper-SillyBots/Tesla/sTesla.png"

var lastCombo = 0;
var lastlastCombo = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	
	enemy_type = GameManager.comboBotIndex
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
		
	aim_melee()

func aim_melee():
	meleeRoot.rotation = aim_direction.angle()

func shoot_primary():
	perform_combo(1)

func shoot_special():
	perform_combo(2)

func perform_combo(currentCombo):

	var finalCombo = null

	if(lastCombo > 0 && lastCombo == currentCombo):
		if(lastlastCombo == lastCombo):
			if(currentCombo == 1):
				finalCombo = combo111
				currentCombo = 0;
				resetCombo()
			if(currentCombo == 2):
				finalCombo = combo222
				currentCombo = 0;
				resetCombo()
		else:
			if(currentCombo == 1):
				finalCombo = combo11
			if(currentCombo == 2):
				finalCombo = combo22
	else:
		if(currentCombo == 1):
			finalCombo = combo1
		if(currentCombo == 2):
			finalCombo = combo2

	lastlastCombo = lastCombo;
	lastCombo = currentCombo;

	if(finalCombo):
		finalCombo.call()

func resetCombo():
	lastCombo = 0
	lastlastCombo = 0


func combo1():
	melee(0, 1, 200, 1, 150)

func combo11():
	melee(2, 1, 200, 1, 150)
	
func combo111():
	melee(2, 3, 1000, 2, 0)

func combo2():
	melee(0, 1, 100, 1, 300)
func combo22():
	melee(1, 1, 200, 1, 150)
func combo222():
	melee(1, 3, 200, 1, 0)

func melee(attackType, melee_damage, impulse = 50, melee_stun = 1, body_shift = 250, deflect = false):
	if is_player:
		GameManager.camera.set_trauma(0.2)
	velocity = body_shift*aim_direction
	var melee_attack = Attack.new(self, melee_damage)
	melee_attack.stun = melee_stun
	melee_attack.impulse = impulse
	if (deflect):
		melee_attack.deflect_type = Attack.DeflectType.TARGET_SOURCE
		melee_attack.deflect_speed_mult = 3.0
		melee_attack.deflect_damage_mult = 2.0
		melee_attack.deflect_added_stun = melee_stun
	melee_attack.tags.append(Attack.Tag.MELEE)
	melee_attack.bonuses.append(Fitness.Bonus.MELEE)
	var shape
	var melee_sprite
	match attackType:
		0:
			shape = wideAttack
			melee_sprite = melee_sprite_wide
		1: 
			shape = longAttack
			melee_sprite = melee_sprite_long
		2: 
			shape = areaAttack
			melee_sprite = melee_sprite_area

	melee_sprite.frame = 0
	melee_sprite.play()

	Violence.melee_attack(shape, melee_attack)

	
func _on_animation_finished(anim_name):
	super(anim_name)
	if anim_name == "Special":
		attacking = false
