extends RigidBody3D
var player  
@onready var fita = $fita
@onready var fita_outlinemesh = $fita/fita_outlinemesh
var selecionado = false


func _ready():
	player = get_tree().get_first_node_in_group("player")
	#get_tree().get_first_node_in_group("player").interact_object.connect(_set_selected)
	fita_outlinemesh.visible = false
	
func _input(event: InputEvent) -> void:
		##mexe depois
		#var raycast = player.raycast
		#if raycast.is_colliding() and raycast.get_collider() == self:
			pass

func _set_selected (object):
	selecionado = self == object

func _physics_process(delta: float) -> void:
	fita_outlinemesh.visible = selecionado
	if selecionado:
		fita.position.y = fita_outlinemesh
		
	else: 
		fita.position.y = 0
