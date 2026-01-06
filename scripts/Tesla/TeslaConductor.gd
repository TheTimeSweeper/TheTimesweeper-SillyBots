class_name TeslaConductor
extends PhysicsProjectile

@export var friendlyColor : Color
@export var evilColor : Color

@onready var sprite = $AnimatedSprite2D
@onready var rangeSprite = $RangeSprite

#not used anymroe cause class_name does not work in mods. maybe in the future conductors are global and you can use enemy conductors and stuff that'd be cool
static var instances_list = []

const GRAVITY = 280
const DEFAULT_INIT_FALLING_VEL = Vector2(0, -50)

var init_air_time = 0.5
var init_height = 10
var init_falling_vel = DEFAULT_INIT_FALLING_VEL
var init_lifetime = 12

var deployable_owner

# assigned when spawning
var destination

var was_player_appearance = null

var remainingHits = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	instances_list.append(self)
	was_player_appearance = !causality.caused_by_player
	update_appearance(causality.caused_by_player)
	sprite.play()
	deflectable = true
	rotate_to_direction = false
	lifetime = init_lifetime

	velocity = (destination - global_position)/init_air_time
	
	angular_velocity = 2*PI/init_air_time * (1 if velocity.x > 0 else -1)
	
	simulate_gravity = true
	# z_vel = init_falling_vel
	gravity_accel = GRAVITY
	ground_decel = ground_decel
	launch_in_arc(init_air_time, init_height)

func disable_conductor():
	rangeSprite.visible = false
	causality.source.remove_conductor(self)

func _exit_tree():
	instances_list.erase(self)
	
func take_hit():
	remainingHits -=1
	if remainingHits <= 0:
		queue_free()
# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	pass

func on_hit_terrain(_body):
	pass

func hit_ground():
	super.hit_ground()
	angular_velocity = 0
	rotation = 0

func update_appearance(player):
	if was_player_appearance == null:
		return
	if was_player_appearance == player:
		return
	was_player_appearance = player

	if player:
		rangeSprite.modulate = friendlyColor
		sprite.animation = "Conductor"
	else:
		rangeSprite.modulate = evilColor
		sprite.animation = "Evil"
