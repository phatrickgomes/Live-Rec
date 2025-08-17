extends RigidBody3D

var player  
@onready var food_ingredient_carrot_2 = $"food_ingredient_carrot2_food_ingredient_carrot#MeshInstance3D"
@onready var outlineMesh = $"food_ingredient_carrot2_food_ingredient_carrot#MeshInstance3D/MeshInstance3D"
var selected = false
var outlineWidth = 0.05

func _ready():
	player = get_tree().get_first_node_in_group("player")
	get_tree().get_first_node_in_group("player").interact_object.connect(_set_selected)
	outlineMesh.visible = false
	
func _input(event: InputEvent) -> void:
		var raycast = player.raycast
		if raycast.is_colliding() and raycast.get_collider() == self:
			pass

func _set_selected (object):
	selected = self == object

func _physics_process(delta: float) -> void:
	outlineMesh.visible = selected
	if selected:
		food_ingredient_carrot_2.position.y = outlineWidth
		
	else: 
		food_ingredient_carrot_2.position.y = 0
