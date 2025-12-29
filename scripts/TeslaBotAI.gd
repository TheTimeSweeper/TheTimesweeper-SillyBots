class_name TeslaBotAI
extends EnemyAI

enum States {
	REPOSITION,
	SHOOT,
	CONDUCTOR,
	NAVIGATE_WITHIN_GUN_RANGE,
	
	RUN_AND_GUN,
}

const INITIAL_STATES = [States.REPOSITION, States.CONDUCTOR]

const MAX_FIRING_RANGE = 300
const IDEAL_FIRING_RANGE = 150

var reposition_point = Vector2.ZERO

func initialize(body_, starting_conditions = null):
	if not body_ is Enemy or body_.enemy_type != GameManager.teslabotIndex:
		print("ERROR: Tesla AI is not compatible with node: ", body_)
		return
		
	super(body_, starting_conditions)
	
	states[States.REPOSITION] = {
		ENTER: func():
			reposition_point = find_reposition_point()
			if reposition_point == null:
				navigate_within_LOS_then_resume()
				return
				
			state_timer = 2.0
			navigation.set_navigation_target(reposition_point),
			
		PROCESS: func():
			follow_nav_path()
			
			if navigation.at_destination() or state_timer < 0:
				#Melee will be disabled unil we have a better way to telegraph the attack
				if false: #dist_to_foe < 50 and randf() < 0.5:
					set_state(States.CONDUCTOR)
				else:
					set_state(States.SHOOT)
	}
	
	states[States.SHOOT] = {
		ENTER: func():
			state_timer = 0.5 - 0.2*AI_level,
		
		PROCESS: func():
			if state_timer < 0:
				if can_shoot():
					body.shoot()
					exit_behaviour(COMPLETED, max(0.0, 0.5 - 0.25*AI_level))
				else:
					exit_behaviour(ABORTED) 
	}
	
	states[States.RUN_AND_GUN] = {
		ENTER: func():
			body.velocity *= -1
			state_timer = randf()*2.0 + 1.0,
			
		PROCESS: func():
			var circle_dir = sign(body.velocity.cross(to_foe))
			move_toward_point(foe_pos + (-to_foe).limit_length(IDEAL_FIRING_RANGE).rotated(0.01*circle_dir))
			
			if can_shoot():
					
				body.aim_direction = body.global_position.direction_to(foe.global_position)
				body.shoot()
				
			if state_timer < 0.0:
				exit_behaviour(COMPLETED)
			
	}
	
	states[States.CONDUCTOR] = {
		ENTER: func():
			body.throw_conductor(),
		
		PROCESS: func():
			exit_behaviour(COMPLETED, 0.5)		
	}
	
	states[States.NAVIGATE_WITHIN_GUN_RANGE] = {
		ENTER: func():
			if not foe_reachable():
				exit_behaviour(ABORTED)
				return
			
			state_timer = PATHFINDING_UPDATE_INTERVAL
			navigation.set_navigation_target(foe, foe.elevation),
			
		PROCESS: func():
			follow_nav_path()
			
			if on_screen(30):
				set_state(States.SHOOT)
			elif state_timer < 0 or navigation.at_destination():
				set_state(States.NAVIGATE_WITHIN_GUN_RANGE)
	}
	
func get_weighted_behaviour_options():
	if AI_level >= 3:
		return get_weighted_behaviour_options_for_golem()
	
	var behaviours = []
	if tactic == Tactic.CAMP:
		behaviours.append([States.SHOOT, 1.0])
	
	else:
		if not on_screen():
			behaviours.append([States.NAVIGATE_WITHIN_GUN_RANGE, 1.0])
		
		behaviours.append([States.REPOSITION, 1.0])
		if dist_to_foe > 100:
			behaviours.append([States.SHOOT, 0.33])

	return behaviours
	
func get_weighted_behaviour_options_for_golem():
	var behaviours = []
	if not on_screen():
		behaviours.append([States.NAVIGATE_WITHIN_GUN_RANGE, 1.0])
		
	behaviours.append([States.REPOSITION, 0.5])
	behaviours.append([States.RUN_AND_GUN, 0.5])
	behaviours.append([States.CONDUCTOR, 0.5])
		
	return behaviours
	
func can_shoot():
	return on_screen()
	
func find_reposition_point():
	var move_towards_foe = dist_to_foe > IDEAL_FIRING_RANGE
	
	for i in range(10):
		var dist = 50 + 80*randf()
		#pick from 180 degree semicitcle facing towards foe to close gap, or facing away from foe to increase gap
		var angle = randf()*PI - PI/2 + (0 if move_towards_foe else PI)
		var point = body.foot_position + (dir_to_foe*dist).rotated(angle)
		
		if not point_has_LOS_to_entity(point, foe): continue
		if point_reachable(point):
			return point
			
	return null
