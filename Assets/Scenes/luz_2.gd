extends SpotLight3D

var flicker_time = 0.0

func _process(delta):
	flicker_time -= delta
	if flicker_time <= 0.0:
		light_energy = randf() * 7
		flicker_time = randf() * 0.5  
