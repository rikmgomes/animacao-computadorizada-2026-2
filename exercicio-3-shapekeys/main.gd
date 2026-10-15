extends Node3D

@onready var modelo: Node3D = $Modelo
@onready var label: Label = $CanvasLayer/Label

var malha: MeshInstance3D
var player: AnimationPlayer
var anim_nome := ""

var nomes: Array[String] = []
var pesos: Array[float] = []
var ativo := 0
var modo_animacao := true

func _ready() -> void:
	malha = modelo.find_children("*", "MeshInstance3D", true, false)[0]
	player = modelo.find_children("*", "AnimationPlayer", true, false)[0]

	# lê os shape keys (blend shapes) da malha
	for i in malha.mesh.get_blend_shape_count():
		nomes.append(str(malha.mesh.get_blend_shape_name(i)))
		pesos.append(0.0)
	print("Blend shapes: ", nomes)
	print("Animações: ", player.get_animation_list())

	# pega a primeira animação que não seja a RESET
	for a in player.get_animation_list():
		if a != "RESET":
			anim_nome = a
			break

	player.get_animation(anim_nome).loop_mode = Animation.LOOP_LINEAR
	player.play(anim_nome)

func _process(delta: float) -> void:
	if modo_animacao:
		# acompanha os pesos que a animação está aplicando
		for i in nomes.size():
			pesos[i] = malha.get_blend_shape_value(i)
	else:
		# setas ↑/↓ ajustam o peso ativo
		if Input.is_key_pressed(KEY_UP):
			_mudar_peso(delta * 0.8)
		if Input.is_key_pressed(KEY_DOWN):
			_mudar_peso(-delta * 0.8)
	_atualizar_label()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_alternar_modo()
			KEY_1:
				ativo = 0
			KEY_2:
				ativo = min(1, nomes.size() - 1)
			KEY_3:
				ativo = min(2, nomes.size() - 1)
			KEY_R:
				if not modo_animacao:
					for i in nomes.size():
						pesos[i] = 0.0
						malha.set_blend_shape_value(i, 0.0)

	# roda do mouse
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_mudar_peso(0.05)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_mudar_peso(-0.05)

	# arrastar com botão esquerdo para os lados
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_mudar_peso(event.relative.x * 0.005)

func _alternar_modo() -> void:
	modo_animacao = not modo_animacao
	if modo_animacao:
		player.play(anim_nome) # retoma de onde parou
	else:
		player.pause() # congela a pose atual; agora os pesos são manuais

func _mudar_peso(delta: float) -> void:
	if modo_animacao or nomes.is_empty():
		return
	pesos[ativo] = clampf(pesos[ativo] + delta, 0.0, 1.0)
	malha.set_blend_shape_value(ativo, pesos[ativo])

func _atualizar_label() -> void:
	var t := "Modo: %s  (ESPAÇO alterna)\n" % ("ANIMAÇÃO" if modo_animacao else "MANUAL")
	t += "1/2/3: escolhe shape key | ↑/↓, roda do mouse ou arrastar horizontalmente com botão esquerdo pressionado: muda peso | R: zera\n\n"
	for i in nomes.size():
		var marca := ">" if i == ativo else " "
		t += "%s %s: %.2f\n" % [marca, nomes[i], pesos[i]]
	label.text = t
