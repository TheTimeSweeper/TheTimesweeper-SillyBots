extends "res://Globals/GameManager.gd"

static var tesla_bot = preload("res://mods-unpacked/TheTimesweeper-SillyBots/Tesla/TeslaBot.tscn")
var spawned
func spawn_enemy(type: Enemy.EnemyType):
	type = 12 if not spawned else type
	spawned = true
	return super.spawn_enemy(type)

func _ready():

	super._ready()

	GameManager.enemy_scenes[12] = tesla_bot
	ModLoaderLog.error("Mutiny", "TheTimesweeper-SillyBots:Main")

func get_player_skin_paths_for_enemy_type(enemy_type):
	
	match enemy_type:
		12: return TeslaBot.default_skin_path

	return super.get_player_skin_paths_for_enemy_type(enemy_type)
