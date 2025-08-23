extends Label

@export var duration := 0.5  # tempo de cada piscada
@export var blink_times := 3

func _ready():
	text = "ERROR"
	modulate.a = 0  # começa invisível
	blink()

func blink() -> void:
	var visible := true
	for i in blink_times:
		modulate.a = 1 if visible else 0
		visible = !visible
		await get_tree().create_timer(duration).timeout
	queue_free()  # remove depois de piscar
