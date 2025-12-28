class_name TeslaConductor
extends PhysicsProjectile


@onready var sprite = $AnimatedSprite2D

static var instances_list = []

const GRAVITY = 280
const DEFAULT_INIT_FALLING_VEL = Vector2(0, -50)

var init_air_time = 0.5
var init_height = 10
var init_falling_vel = DEFAULT_INIT_FALLING_VEL
var init_lifetime = 20

# bit unintuitively used when spawning
static var distance = 69

var deployable_owner

# assigned when spawning
var destination

var remainingHits = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	instances_list.append(self)
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


func _exit_tree():
	instances_list.erase(self)
	
func take_hit():
	remainingHits -=1
	if remainingHits <= 0:
		queue_free()
# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	pass

func hit_ground():
	super.hit_ground()
	angular_velocity = 0
	rotation = 0

func update_appearance(owned_by_player):
	if owned_by_player:
		sprite.animation = "Conductor"
	else:
		sprite.animation = "Evil"
