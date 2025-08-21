extends CharacterBody2D

@onready var vida_inimigo = $progress_inimigo
@onready var anima = $AnimationPlayer
@onready var anim = $AnimatedSprite2D

var max_health = 100
var current_health = max_health
var damage_amount = 5  ## dano que cada soco causa

## maquina de estados
enum Estado {IDLE, ATAQUE, DANO}
var estado_atual = Estado.IDLE

var tempo_resfriamento = 0.0
var intervalo_resfriamento = 2.3 
var tempo_ataque = 0.0
var duracao_ataque = 1.2 
var tempo_dano = 0.0
var duracao_dano = 1 

func _ready():
	randomize()
	vida_inimigo.max_value = max_health
	vida_inimigo.value = current_health
	update_health_bar()
	tempo_resfriamento = 2.0  
	estado_atual = Estado.IDLE

func _physics_process(delta):
	match estado_atual:
		Estado.IDLE:
			anim.play("idle")
			##espera cooldown
			if tempo_resfriamento > 0.0:
				tempo_resfriamento -= delta
			else:
				var escolha = randi_range(0, 30)
				if escolha < 2:
					estado_atual = Estado.ATAQUE
					soco()
					tempo_ataque = duracao_ataque

		Estado.ATAQUE:
			##espera a animação acabar
			tempo_ataque -= delta
			if tempo_ataque <= 0.0:
				tempo_resfriamento = intervalo_resfriamento
				estado_atual = Estado.IDLE  

		Estado.DANO:
			##espera animação de dano acabar
			tempo_dano -= delta
			if tempo_dano <= 0.0:
				estado_atual = Estado.IDLE

func soco():
	anima.play("soco_inimigo") 
	var random = randi_range(1,2) 
	if random == 1:
		anim.play("soco_1")              
	else:
		anim.play("soco_2")             
	print("attack")

func desviar():
	var chance = randi_range(0,100)
	if chance > 70: 
		anima.play("desvio")
		print("desvio")

func take_damage(damage):
	current_health -= damage
	current_health = max(0, current_health) 
	update_health_bar()

	##entra no estado de dano 
	if current_health > 0:
		estado_atual = Estado.DANO
		tempo_dano = duracao_dano
		anim.play("hit")
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
