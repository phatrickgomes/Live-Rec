
extends Area3D

@onready var sprite3d: Sprite3D = $CollisionShape3D/Sprite3D
@onready var viewport: SubViewport = $CollisionShape3D/Sprite3D/SubViewport
@onready var controle: PackedScene = preload("res://Assets/Scenes/control.tscn")

var ativo := false

func _unhandled_input(event) -> void:
	if not ativo:
		return
	viewport.push_input(event)

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not ativo:
		return
	var local_pos = sprite3d.get_global_transform().affine_inverse() * event_position
	var texture_position = Vector2(local_pos.x, -local_pos.y) / sprite3d.pixel_size - sprite3d.get_item_rect().position
	if event is InputEventMouse and Global.Ta_no_jogo:
		var e = event.duplicate()
		e.set_position(texture_position)
		e.set_global_position(texture_position)
		viewport.push_input(e)
func reset_jogo() -> void:
	if viewport.get_child_count() > 0:
		viewport.get_child(0).queue_free()
	var tela_inst = controle.instantiate()
	viewport.add_child(tela_inst)
	if tela_inst is Control:
		tela_inst.mouse_filter = Control.MOUSE_FILTER_STOP
	Global.Ta_no_jogo = false
func _input(event) -> void:
	if event.is_action_pressed("retornar") and Global.Ta_no_jogo:
		reset_jogo()
func _physics_process(delta: float) -> void:
	if Global.Lurdes_vida <= 0 or Global.Vida_jamv <= 0:
		reset_jogo()
