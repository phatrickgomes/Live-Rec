extends Node3D

@onready var crow_sound = $corvo
@onready var timer = $corvo/Timer

func _ready():
	start_timer()

func start_timer():
	# Escolhe um tempo aleatório entre 5 e 15 segundos
	timer.wait_time = randf_range(60.0, 120.0)
	timer.start()

func _on_timer_timeout():
	crow_sound.play()
	start_timer()
