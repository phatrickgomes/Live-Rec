extends CharacterBody2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	pass

func _input(event):
	if event.is_action_pressed("tiro"):
		anim.play("direto")
		

func _input2(event):
	if event.is_action_pressed("socojab"):
		anim.play("jab")
	
	move_and_slide()
