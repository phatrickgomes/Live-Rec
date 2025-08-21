extends CharacterBody2D

signal atacando

@onready var vida_inimigo = $AnimatedSprite2D/progress_inimigo
@onready var anima = $AnimationPlayer
@onready var anim = $AnimatedSprite2D
@onready var hurt_box = $hurt_box
@onready var aneme = $AnimatedSprite2D2

var max_health = 100
var current_health = max_health
var damage_amount = 5

enum Estado {IDLE, ATAQUE, DANO, ESQUIVA}
var estado_atual = Estado.IDLE

var tempo_resfriamento = 2.0
var intervalo_resfriamento = 2.0
var tempo_ataque = 0.0
var duracao_ataque = 1.2
var tempo_dano = 0.0
var duracao_dano = 1.0

var hits_seguidos = 0
var posicao_original: float = 0.0

func _ready():
	aneme.visible = false
	randomize()
	vida_inimigo.max_value = max_health
	vida_inimigo.value = current_health
	update_health_bar()
	estado_atual = Estado.IDLE

func _physics_process(delta):
	match estado_atual:
		Estado.IDLE:
			aneme.visible = false
			anim.play("idle")
			if tempo_resfriamento > 0.0:
				tempo_resfriamento -= delta
			else:
				if tempo_ataque <= 0.0:
					estado_atual = Estado.ATAQUE
					soco()
					tempo_ataque = duracao_ataque

		Estado.ATAQUE:
			tempo_ataque -= delta
			if tempo_ataque <= 0.0:
				tempo_resfriamento = intervalo_resfriamento
				estado_atual = Estado.IDLE  

		Estado.DANO:
			tempo_dano -= delta
			if tempo_dano <= 0.0:
				estado_atual = Estado.IDLE

		Estado.ESQUIVA:
			# Ocorre dentro do método desviar(), não precisa processar aqui
			pass

func soco():
	aneme.visible = true
	aneme.play("perigo")
	anima.play("soco_inimigo")
	anim.play("soco_2")
	emit_signal("atacando")  # Sinal emitido para o player reagir
	print("attack")


func desviar() -> void:
	var chance = randi_range(0,100)
	if chance > 70:
		estado_atual = Estado.ESQUIVA
		posicao_original = position.x
		anima.play("desvio")
		anim.play("esquiva")
		hurt_box.monitoring = false
		var direcao = 1
		var pos_lateral = position.x + direcao * 20
		var tween = create_tween()
		tween.tween_property(self, "position:x", pos_lateral, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		var tween_volta = create_tween()
		tween_volta.tween_property(self, "position:x", posicao_original, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween_volta.finished
		hurt_box.monitoring = true
		estado_atual = Estado.IDLE
		print("desvio")

func take_damage(damage):
	current_health -= damage
	current_health = max(0, current_health)
	update_health_bar()
	if current_health > 0:
		estado_atual = Estado.DANO
		tempo_dano = duracao_dano
		hits_seguidos += 1
		if hits_seguidos >= 3:
			anim.play("hit_3")
			hits_seguidos = 0
		
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
		vida_inimigo.get("theme_override_styles/fill").bg_color = Color.DARK_ORANGE

func die():
	get_tree().reload_current_scene()

func _on_hurt_box_area_entered(area):
	if area.is_in_group("socao"):
		print("acertou")
		anim.play("hit_2")
		take_damage(damage_amount)
	if area.is_in_group("socao2"):
		print("acertou")
		anim.play("hit")
		take_damage(damage_amount)
