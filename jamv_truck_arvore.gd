extends Node3D

@export var tree_scene: PackedScene  # Árvores laterais
@export var arvore_centro: PackedScene  # Árvore central
@export var min_spawn_rate := 0.5  # Tempo entre 1.0s e 2.0s
@export var max_spawn_rate := 2.0
@export var road_width := 20.0
@export var distance_from_road := 2.0
@export var chance_centro := 0.1  # 30% de chance para centro

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
		printerr("⚠️ Árvore normal não atribuída!")
		return
	
	# Decidir se vai spawnar centro ou laterais
	if arvore_centro != null and randf() < chance_centro:
		spawn_center()
		# Quando spawna centro, escolhe UM lado livre (não spawna os dois)
		if randi() % 2 == 0:
			spawn_side(1)  # Direita
		else:
			spawn_side(-1)  # Esquerda
	else:
		# Padrão normal: alterna entre lados
		spawn_side(next_side)
		next_side *= -1

func spawn_side(side: int) -> void:
	var tree = tree_scene.instantiate()
	var x = side * (road_width / 2.0 + distance_from_road)
	tree.position = Vector3(x, 0, -80)
	add_child(tree)

func spawn_center() -> void:
	var centro = arvore_centro.instantiate()
	centro.position = Vector3(-11, 1, -100)
	add_child(centro)
	print("seilaa")
