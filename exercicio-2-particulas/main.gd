extends Node2D

@onready var particle_system: ParticleSystem = $ParticleSystem
@onready var label: RichTextLabel = $UI/Label
@onready var stats_label: Label = $UI/StatsLabel

const SELECTED_COLOR := "#ff6961"   # vermelho claro - opção atual
const UNSELECTED_COLOR := "#ffffff" # branco - demais opções

var emitter_names := ["Ponto (Point)", "Área (Area)", "Anel (Ring)"]
var behavior_names := ["Gravidade / Queda", "Explosão", "Órbita", "Onda (Wave)", "Atrator (Vórtice)"]
var attribute_names := ["Cor (gradiente HSV)", "Tamanho (pulso)", "Forma (morph)"]
var death_names := ["Tempo de vida (lifetime)", "Sair da tela (offscreen)"]

func _ready() -> void:
	particle_system.position = get_viewport_rect().size / 2.0 # centraliza o sistema de partículas na tela
	label.bbcode_enabled = true # garante que a label interprete BBCode mesmo se não marcado no editor
	_update_label()

func _process(_delta: float) -> void:
	_update_stats_label()

func _update_stats_label() -> void:
	stats_label.text = (
		"Vivas agora: %d\n" % particle_system.alive_count() +
		"Nascendo: %d/s\n" % particle_system.births_per_second +
		"Morrendo: %d/s\n" % particle_system.deaths_per_second +
		"Total nascidas: %d\n" % particle_system.total_spawned +
		"Total mortas: %d" % particle_system.total_died
	)

# Controle de inputs (0,1,2,3)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_0:
				particle_system.attribute_mode = (particle_system.attribute_mode + 1) % 3
				particle_system.reset()
			KEY_1:
				particle_system.emitter_type = (particle_system.emitter_type + 1) % 3
				particle_system.reset()
			KEY_2:
				particle_system.behavior_type = (particle_system.behavior_type + 1) % 5
				particle_system.reset()
			KEY_3:
				particle_system.death_type = (particle_system.death_type + 1) % 2
				particle_system.reset()
			_:
				return
		_update_label()

# Controle de labels
func _update_label() -> void:
	var text := ""
	text += _build_category("[0] Atributo", attribute_names, particle_system.attribute_mode)
	text += "\n"
	text += _build_category("[1] Emissor", emitter_names, particle_system.emitter_type)
	text += "\n"
	text += _build_category("[2] Comportamento", behavior_names, particle_system.behavior_type)
	text += "\n"
	text += _build_category("[3] Morte", death_names, particle_system.death_type)
	label.text = text

# Montagem + destaque da opção atual em uma mesma categoria
func _build_category(title: String, options: Array, selected: int) -> String:
	var s := "[b]%s[/b]\n" % title
	for i in range(options.size()):
		var color := SELECTED_COLOR if i == selected else UNSELECTED_COLOR
		s += "  [color=%s]%s[/color]\n" % [color, options[i]]
	return s
