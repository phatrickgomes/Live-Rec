extends RigidBody3D

var player  
@onready var fita = $fita

var selecionado = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("pegavel") 
	
func _set_selected(object):
	selecionado = self == object
