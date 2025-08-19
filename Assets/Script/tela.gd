extends Area3D

@onready var sprite3d: Sprite3D = $CollisionShape3D/Sprite3D
@onready var viewport: SubViewport = $CollisionShape3D/Sprite3D/SubViewport
@onready var control: Control = $CollisionShape3D/Sprite3D/SubViewport/Control
var controle = preload("res://Assets/Scenes/control.tscn")

var ativo := false

func _unhandled_input(event) -> void:
	if not ativo:
		return
	viewport.push_input(event)
func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not ativo:
		return
	var texture_3d_position = sprite3d.get_global_transform().affine_inverse() * event_position
	var texture_position: Vector2 = Vector2(texture_3d_position.x, -texture_3d_position.y) / sprite3d.pixel_size - sprite3d.get_item_rect().position
	var e: InputEvent = event.duplicate()
	
	if e is InputEventMouse and Global.Ta_no_jogo:
		e.set_position(texture_position)
		e.set_global_position(texture_position)
		viewport.push_input(e)

func _input(event) -> void:
	if event.is_action_pressed("retornar") and Global.Ta_no_jogo == true:
		$CollisionShape3D/Sprite3D/SubViewport.get_child(0).queue_free()
		var tela_inst = controle.instantiate()
		$CollisionShape3D/Sprite3D/SubViewport.add_child(tela_inst)
		Global.Ta_no_jogo = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
