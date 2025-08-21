extends CharacterBody3D

@export var initial_speed: float = 3.0
@export var speed_increase: float = 1.0
@export var scale_increase: float = 0.2
@export var disk_rotation_speed: float = 0.5  # Velocidade de rotação do disco

var current_speed: float
var player: Node3D
var timer: Timer
var aura: MeshInstance3D
var accretion_disk: MeshInstance3D

func _ready():
	current_speed = initial_speed
	
	# Configura o timer
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3.0
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	# Tenta encontrar o jogador assim que a cena é carregada
	find_player()
	
	# Cria os efeitos visuais
	create_black_hole_effects()

func _process(delta):
	# Rotaciona o disco de acreção continuamente
	if accretion_disk:
		accretion_disk.rotate_y(disk_rotation_speed * delta)

func create_black_hole_effects():
	# Cria a aura escura do buraco negro
	create_dark_aura()
	
	# Cria o disco de acreção (anel de partículas)
	create_accretion_disk()
	
	# Cria efeito de distorção ao redor
	create_distortion_effect()

func create_dark_aura():
	# Cria uma esfera para a aura escura
	aura = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.7
	sphere_mesh.height = 1.4
	aura.mesh = sphere_mesh
	
	# Material muito escuro com leve emissão
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.05, 0.05, 0.1)  # Azul muito escuro/preto
	material.emission_enabled = true
	material.emission = Color(0.02, 0.02, 0.05)  # Emissão muito fraca
	material.emission_energy = 0.5
	material.metallic = 0.9
	material.roughness = 0.1
	
	aura.material_override = material
	add_child(aura)

func create_accretion_disk():
	# Cria um disco de acreção (torus achatado)
	accretion_disk = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.outer_radius = 1.0
	torus_mesh.inner_radius = 0.6
	torus_mesh.rings = 16
	torus_mesh.ring_segments = 32
	accretion_disk.mesh = torus_mesh
	
	# Material para o disco de acreção (cores quentes)
	var disk_material = StandardMaterial3D.new()
	disk_material.emission_enabled = true
	disk_material.emission = Color(0.8, 0.4, 0.1)  # Laranja avermelhado
	disk_material.emission_energy = 2.0
	disk_material.albedo_color = Color(0.8, 0.3, 0.1)
	disk_material.metallic = 0.7
	disk_material.roughness = 0.3
	disk_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disk_material.alpha_scissor_threshold = 0.1
	
	accretion_disk.material_override = disk_material
	accretion_disk.rotation.x = deg_to_rad(90)  # Rotaciona para ficar horizontal
	add_child(accretion_disk)

func create_distortion_effect():
	# Cria uma esfera maior para o efeito de distorção
	var distortion = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.2
	sphere_mesh.height = 2.4
	distortion.mesh = sphere_mesh
	
	# Material de distorção (preto com bordas esfumaçadas)
	var distortion_material = StandardMaterial3D.new()
	distortion_material.flags_transparent = true
	distortion_material.albedo_color = Color(0.1, 0.1, 0.2, 0.3)
	distortion_material.emission_enabled = true
	distortion_material.emission = Color(0.05, 0.05, 0.1, 0.2)
	distortion_material.vertex_color_use_as_albedo = true
	distortion_material.metallic = 0.8
	distortion_material.roughness = 0.2
	
	distortion.material_override = distortion_material
	add_child(distortion)

func find_player():
	# Primeiro tenta encontrar por grupo
	player = get_tree().get_first_node_in_group("Spark")
	
	# Se não encontrar por grupo, tenta encontrar pelo nome
	if not player:
		player = get_node_or_null("/root/SparkyGloryPlay")
	
	# Se ainda não encontrou, imprime um aviso
	if not player:
		print("Jogador não encontrado! Verifique o nome ou grupo.")

func _physics_process(delta):
	# Se não tem referência ao jogador, tenta encontrar novamente
	if not player:
		find_player()
		return
	
	# Move em direção ao jogador em TODAS as direções (incluindo altura)
	var target_position = player.global_position
	var current_position = global_position
	
	var direction = (target_position - current_position).normalized()
	velocity = direction * current_speed
	
	move_and_slide()

func _on_timer_timeout():
	# Aumenta tamanho e velocidade
	current_speed += speed_increase
	scale += Vector3(scale_increase, scale_increase, scale_increase)
	
	# Ajusta o tamanho da aura e do disco de acreção
	if aura:
		var aura_mesh = aura.mesh as SphereMesh
		aura_mesh.radius += scale_increase * 0.5
		aura_mesh.height += scale_increase
	
	if accretion_disk:
		var disk_mesh = accretion_disk.mesh as TorusMesh
		disk_mesh.outer_radius += scale_increase * 0.8
		disk_mesh.inner_radius += scale_increase * 0.5
		
		# Aumenta gradualmente a velocidade de rotação também
		disk_rotation_speed += 0.1
	
	# Efeito visual de pulsação
	var original_scale = scale
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 1.1, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.1)
	
	# Efeito de brilho mais intenso no disco de acreção quando cresce
	if accretion_disk:
		var disk_material = accretion_disk.material_override as StandardMaterial3D
		var original_emission = disk_material.emission
		var tween_disk = create_tween()
		tween_disk.tween_property(disk_material, "emission", Color(1.0, 0.6, 0.2), 0.1)
		tween_disk.tween_property(disk_material, "emission", original_emission, 0.3)
