extends "res://Globals/GameManager.gd"

var spawn_available = true
var funnykeypressbool

var teslabotIndex

func _ready():
	super._ready()
	teslabotIndex = get_node("/root/ModLoader/TheTimesweeper-SillyBots/SillyBusiness").teslabot.index

func spawn_enemy(type: Enemy.EnemyType):
	type = teslabotIndex if spawn_available else type
	spawn_available = false
	return super.spawn_enemy(type)

func _physics_process(delta):
	super._physics_process(delta)
	
	if Input.is_key_pressed(KEY_B):
		if !funnykeypressbool:
			spawn_available = !spawn_available

			ModLoaderLog.error("Next spawn will be " + str(spawn_available), "SillyBots")
		funnykeypressbool = true
		
	if Input.is_key_pressed(KEY_Y):
		if !funnykeypressbool:
			start_normal_run()
		funnykeypressbool = true

	if !Input.is_key_pressed(KEY_Y) && !Input.is_key_pressed(KEY_B):
		funnykeypressbool = false
