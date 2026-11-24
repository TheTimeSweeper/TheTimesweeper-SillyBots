extends "res://Scripts/GameObjects/SummonButton.gd"

# Called when the node enters the scene tree for the first time.
func _physics_process(delta):
	var orig_enemy = enemy
	if Input.is_action_pressed('attack2'):
		enemy = get_node("/root/ModLoader/TheTimesweeper-SillyBots/SillyBusiness").teslabot.index

	super._physics_process(delta)
	enemy = orig_enemy

