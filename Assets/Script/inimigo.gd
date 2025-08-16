extends CharacterBody3D

var speed = 7.0
var current_index = 0
var waypoints: Array = []

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@export var caminho_waypoints: NodePath

func _ready():
	var node_waypoints = get_node(caminho_waypoints)
	for child in node_waypoints.get_children():
		waypoints.append(child.global_transform.origin)

	if waypoints.size() > 0:
		nav.set_target_position(waypoints[0]) 

func _physics_process(delta):
	if nav.is_navigation_finished():

		current_index = (current_index + 1) % waypoints.size()
		nav.set_target_position(waypoints[current_index])


	var destino = nav.get_next_path_position()
	var direcao = (destino - global_position).normalized()
	velocity = direcao * speed
	move_and_slide()
