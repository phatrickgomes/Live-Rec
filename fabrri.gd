extends CharacterBody3D

@onready var sprite = $Sprite3D
@export var frames: Array[Texture2D] = []  
@export var frame_time := 0.2             

var current_frame := 0
var timer := 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer >= frame_time and frames.size() > 0:
		timer = 0.0
		current_frame = (current_frame + 1) % frames.size()
		sprite.texture = frames[current_frame]
		
