extends Area3D

func _on_body_entered(body):
	if body.is_in_group("player_jamv"):
		print("arvore spawnada")
		Global.Lurdes_vida = 0
