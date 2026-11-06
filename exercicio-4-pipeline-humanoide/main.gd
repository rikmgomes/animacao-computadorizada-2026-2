extends Node3D

const TEMPO_TRANSICAO := 0.35
const ANIMACOES := ["Idle", "Acenar", "Dancar"]

@onready var personagem: Node = $Personagem

var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var label: Label

func _ready() -> void:
	anim_player = personagem.find_child("AnimationPlayer", true, false)
	if anim_player == null:
		push_error("AnimationPlayer não encontrado dentro de Personagem.")
		return
	print("Animações encontradas: ", anim_player.get_animation_list())

	# Faz as 3 animações repetirem em loop
	for nome in ANIMACOES:
		if anim_player.has_animation(nome):
			anim_player.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
		else:
			push_warning("Animação ausente: " + nome)

	# Máquina de estados: um estado por animação
	var maquina := AnimationNodeStateMachine.new()
	for nome in ANIMACOES:
		var no := AnimationNodeAnimation.new()
		no.animation = nome
		maquina.add_node(nome, no)

	# Transições entre todos os pares, com cross-fade (mistura suave)
	for de in ANIMACOES:
		for para in ANIMACOES:
			if de != para:
				var t := AnimationNodeStateMachineTransition.new()
				t.xfade_time = TEMPO_TRANSICAO
				maquina.add_transition(de, para, t)

	# O AnimationTree fica ao lado do AnimationPlayer
	anim_tree = AnimationTree.new()
	anim_player.get_parent().add_child(anim_tree)
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)
	anim_tree.tree_root = maquina
	anim_tree.active = true

	await get_tree().process_frame
	playback = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	playback.start("Idle")

	_criar_interface()
	_atualizar_label("Idle")

func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	label = Label.new()
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 22)
	camada.add_child(label)

func _atualizar_label(atual: String) -> void:
	label.text = "1 = Idle   2 = Acenar   3 = Dançar\nAnimação atual: " + atual

func _tocar(nome: String) -> void:
	if playback == null:
		return
	playback.travel(nome)
	_atualizar_label(nome)

func _unhandled_input(event: InputEvent) -> void:
	var tecla := event as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	match tecla.keycode:
		KEY_1:
			_tocar("Idle")
		KEY_2:
			_tocar("Acenar")
		KEY_3:
			_tocar("Dancar")
