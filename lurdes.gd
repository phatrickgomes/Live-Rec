extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
func _ready():
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	pass
	move_and_slide()

func _input(event):
	if event.is_action_pressed("tiro") and anim.animation != "direto":
		anim.play("direto")
	elif event.is_action_pressed("socojab") and anim.animation != "jab":
		anim.play("jab")

func _on_animation_finished():
	if anim.animation == "direto" or anim.animation == "jab":
		anim.play("idle") 
