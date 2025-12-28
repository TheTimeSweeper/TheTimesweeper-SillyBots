class_name SillyViolence
#extends Node

static func fire_lightning(lightningParams : LightningBoltParams):
	
	var lightningBolt = TeslaBot.lightning_scene.instantiate()

	Util.set_object_elevation(lightningBolt, Util.elevation_from_z_index(lightningParams.source.z_index))
	GameManager.call_deferred('add_entity_to_scene_tree',  lightningBolt, lightningParams.source.get_parent() , Vector2.ZERO)

	lightningBolt._fire(lightningParams)
