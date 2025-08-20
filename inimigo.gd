extends CharacterBody2D
@onready var vida_inimigo = $progress_inimigo
@onready var anima = $AnimationPlayer


	#maqui de estado#
#estado ataque
#resfriando
#recuperado

#var escolher soco = randi_range(0,2)

func desviar():
	var chance = randi_range(0,100)
	if chance > 70: $AnimationPlayer.play("desvio")
	

var max_health = 100
var current_health = max_health
var damage_amount = 5  ##dano que cada soco causa

func _ready():
	##como começa a barra de vida
	vida_inimigo.max_value = max_health
	vida_inimigo.value = current_health
	update_health_bar()
func soco():
	$AnimationPlayer.play("soco_inimigo")
	
	pass
func take_damage(damage):
	current_health -= damage
	current_health = max(0, current_health) 
	update_health_bar()
	if current_health <= 0:
		die()

func update_health_bar():
	vida_inimigo.value = current_health
	update_health_bar_color()

func update_health_bar_color():
	var health_percentage = float(current_health) / float(max_health)
	if health_percentage > 0.6:
		vida_inimigo.get("theme_override_styles/fill").bg_color = Color.GREEN
	elif health_percentage > 0.3:
		vida_inimigo.get("theme_override_styles/fill").bg_color = Color.YELLOW
	else:
		vida_inimigo.get("theme_override_styles/fill").bg_color = Color.RED

func die():
	##colocar animaçao de morte depois
	get_tree().reload_current_scene()

func _on_hurt_box_area_entered(area):
	if area.is_in_group("socao"):  
		print("acertou")
		take_damage(damage_amount)
