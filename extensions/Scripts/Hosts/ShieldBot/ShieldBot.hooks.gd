extends Object

func capture_projectile(chain: ModLoaderHookChain, proj, is_duplicate = false):

	print("CAPTURING")
	if proj.has_method("disable_conductor"):
		proj.update_appearance(chain.reference_object.is_player)
		print("CONDUCTOR")
		proj.disable_conductor()

	chain.execute_next([proj, is_duplicate])

func shoot_captured_projectile(chain: ModLoaderHookChain, proj_index, target_point, repeat = 0):

	var orig = chain.reference_object
	
	var p = orig.captured_projectiles[proj_index]
	if not is_instance_valid(p): return
	var dir = p.global_position.direction_to(target_point)
	
	if repeat > 0:
		dir = dir.rotated((randf() - 0.5)*0.05*PI*repeat)

	var beam_attack = Attack.new(orig, 30*orig.retaliation_damage_mult*pow(0.75, repeat), 100*orig.retaliation_kb_mult)
	orig.shoot_projectile_beam(p.global_position, dir, beam_attack)	
	orig.velocity -= dir*beam_attack.damage*3

	chain.execute_next([proj_index, target_point, repeat])
	
	p.despawn()
