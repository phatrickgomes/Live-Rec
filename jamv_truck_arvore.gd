extends Node3D

@export var tree_scene: PackedScene      
@export var arvore_centro: PackedScene   
@export var min_spawn_rate := 0.5         
@export var max_spawn_rate := 0.6         
@export var road_width := 57.5
@export var distance_from_road := -6
@export var chance_centro := 0.28         

var timer := 0.0
var next_side := 1

func _ready() -> void:
	randomize()
	next_side = 1 if (randi() % 2 == 0) else -1

func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		spawn_tree()
		timer = randf_range(min_spawn_rate, max_spawn_rate)

func spawn_tree() -> void:
	if tree_scene == null:
		return
	if arvore_centro != null and randf() < chance_centro:
		spawn_center()
		if randi() % 2 == 0:
			spawn_side(1)
		else:
			spawn_side(-1)
	else:

		spawn_side(next_side)
		next_side *= -1

func spawn_side(side: int) -> void:
	var tree = tree_scene.instantiate()
	var x = side * (road_width / 2.0 + distance_from_road)
	tree.position = Vector3(x, 4.5, -500)

	if side == -1:
		tree.scale.x *= -1
	
	add_child(tree)

func spawn_center() -> void:
	var centro = arvore_centro.instantiate()
	centro.position = Vector3(0, 0, -500)
	add_child(centro)
	


func _on_area_3d_body_entered(body):
	pass # Replace with function body.
