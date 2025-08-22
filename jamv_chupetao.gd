extends Node2D
@onready var audiod = $audiod

func _ready():
	audiod.play()
