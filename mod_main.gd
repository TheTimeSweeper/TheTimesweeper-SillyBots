extends Node
class_name SillyBotsMain

# ! Comments prefixed with "!" mean they are extra info. Comments without them
# ! should be kept because they give your mod structure and make it easier to
# ! read by other modders
# ! Comments with "?" should be replaced by you with the appropriate information

# ! This template file is statically typed. You don't have to do that, but it can help avoid bugs
# ! You can learn more about static typing in the docs
# ! https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/static_typing.html

# ? Brief overview of what your mod does...

const MOD_DIR := "TheTimesweeper-SillyBots" # Name of the directory that this file is in
const LOG_NAME := "TheTimesweeper-SillyBots:Main" # Full ID of the mod (AuthorName-ModName)

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

const tesla_bot_path = "res://mods-unpacked/TheTimesweeper-SillyBots/Tesla/TeslaBot.tscn"
const default_skin_path = "res://mods-unpacked/TheTimesweeper-SillyBots/Tesla/sTesla.png"

static var teslabot : CustomEnemyDef

# ! your _ready func.
func _init() -> void:
	return
	ModLoaderLog.error("Init this beeitch", "SillyBots")
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)

	ModLoaderLog.error("Init this beeitch", LOG_NAME)
	# script_hooks_path = mod_dir_path.path_join("extensions/Scripts")
	# Add extensions
	install_script_extensions()
	# install_script_hook_files()

	ContentContainer.instance.initialize.connect(add_enemy)
	
	# Add translations
	# add_translations()

func add_enemy():
	teslabot = CustomEnemyDef.new()
	teslabot.name = "TeslaTrooper"
	teslabot.scene_path = tesla_bot_path
	teslabot.default_skin_path = default_skin_path

	ContentContainer.add_enemydef(teslabot)

func install_script_extensions() -> void:
	# ! any script extensions should go in this directory, and should follow the same directory structure as vanilla
	extensions_dir_path = mod_dir_path.path_join("extensions")

	# ? Brief description/reason behind this edit of vanilla code...
	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("ext_GameManager.gd"))
	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("ext_SummonButton.gd"))
	# ModLoaderMod.install_script_extension(extensions_dir_path.path_join("ext_Enemy.gd"))
	#ModLoaderMod.install_script_extension(ext_dir + "entities/units/player/player.gd") # ! Note that this file does not exist in this example mod

	# ! Add extensions (longform version of the above)
	#ModLoaderMod.install_script_extension("res://mods-unpacked/AuthorName-ModName/extensions/main.gd")
	#ModLoaderMod.install_script_extension("res://mods-unpacked/AuthorName-ModName/extensions/entities/units/player/player.gd")


#func install_script_hook_files() -> void:
	#extensions_dir_path = mod_dir_path.path_join("extensions")
	#ModLoaderMod.install_script_hooks("res://main.gd", extensions_dir_path.path_join("main.gd"))



