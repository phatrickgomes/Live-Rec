extends CharacterBody2D

@onready var vida_inimigo = $progress_inimigo
@onready var anima = $AnimationPlayer
@onready var anim = $AnimatedSprite2D

var max_health = 100
var current_health = max_health
var damage_amount = 5  ## dano que cada soco causa

## maquina de estados
enum Estado {RECUPERADO, ATAQUE, RESFRIANDO}
var estado_atual = Estado.RECUPERADO
var tempo_resfriamento = 3.0
var intervalo_resfriamento = 4.0  ##tempo de cooldown entre ataques

func _ready():
	randomize()
	vida_inimigo.max_value = max_health
	vida_inimigo.value = current_health
	update_health_bar()


func _physics_process(delta):
	match estado_atual:
		Estado.RECUPERADO:
			var escolha = randi_range(0,1) 
			if escolha == 1:
				soco()
				estado_atual = Estado.RESFRIANDO
				tempo_resfriamento = 0.0
			elif escolha == 2:
				desviar()
				estado_atual = Estado.RESFRIANDO
				tempo_resfriamento = 0.0

		Estado.RESFRIANDO:
			tempo_resfriamento += delta
			if tempo_resfriamento >= intervalo_resfriamento:
				estado_atual = Estado.RECUPERADO

		Estado.ATAQUE:
			pass

func soco():
	anima.play("soco_inimigo")     
	anim.play("soco_1")             
	await anim.animation_finished     
	anim.play("soco_2")             
	await anim.animation_finished    
	print("attack")


func desviar():
	var chance = randi_range(0,100)
	if chance > 70: 
		$AnimationPlayer.play("desvio")
		print("desvio")

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
	## colocar animaçao de morte depois
	get_tree().reload_current_scene()

func _on_hurt_box_area_entered(area):
	if area.is_in_group("socao"):  
		print("acertou")
		take_damage(damage_amount)
