extends Node3D

@onready var crow_sound = $corvo
@onready var timer = $corvo/Timer

func _ready():
	start_timer()

func start_timer():
	timer.wait_time = randf_range(15, 30.0)
	timer.start()

func _on_timer_timeout():
	crow_sound.play()
	start_timer()
