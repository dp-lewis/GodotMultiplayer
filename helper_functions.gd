extends Node

class_name HelperFunctions

static func ClientInterpolate(global_position:Vector2, target_position:Vector2, delta:float, lerp_sync_speed:float = 25) -> Vector2:
	if target_position == Vector2.INF:
		return global_position
		
	if (global_position - target_position).length_squared() > 100 * 100: # using squared here is a optimisation
		return target_position
	
	return lerp(
		global_position,
		target_position,
		pow(0.5, delta * lerp_sync_speed))
