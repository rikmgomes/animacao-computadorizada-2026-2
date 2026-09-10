extends Node2D

# Define os estados possíveis para as curvas do projeto
enum CurveType { LINEAR, CATMULL_ROM, BEZIER }

# Referências aos nós da cena e configuração de resolução das curvas
@export var points_per_segment: int = 24
@onready var control_points_node: Node2D = $ControlPoints
@onready var linear_line: Line2D = $LinearLine
@onready var catmull_line: Line2D = $CatmullRomLine
@onready var bezier_line: Line2D = $BezierLine
@onready var mouse: Node2D = $Mouse
@onready var ui_label: Label = $UILabel

# Variáveis para armazenar as posições base e saber qual curva está ativa
var control_points: PackedVector2Array = []
var current_curve: CurveType = CurveType.LINEAR

func _ready() -> void:
	# Fluxo inicial de preparação da cena
	_collect_control_points()
	_generate_all_curves()
	_set_curve_mode(CurveType.LINEAR) # Define a Linear como padrão inicial
	queue_redraw() # Aciona a função _draw() para renderizar gráficos na tela

func _draw() -> void:
	# Desenha os círculos de marcação em cima de cada ponto de controle
	for p in control_points:
		draw_circle(p, 6.0, Color(1, 1, 1, 0.9))
		draw_arc(p, 6.0, 0, TAU, 24, Color.BLACK, 1.5)

	# Desenha os vetores de tangente visuais apenas se a Catmull-Rom estiver selecionada
	if current_curve == CurveType.CATMULL_ROM:
		_draw_catmull_tangents()

func _draw_catmull_tangents() -> void:
	var n = control_points.size()
	for i in range(1, n - 1):
		# Calcula o vetor de direção da tangente com base nos pontos adjacentes
		# fórmula do slide 40: tangente = (P[i+1] - P[i-1]) / 2
		var tangent = (control_points[i + 1] - control_points[i - 1]) * 0.5
		
		# Desenha as linhas guias laranjas saindo do ponto
		draw_line(control_points[i], control_points[i] + tangent, Color.ORANGE, 2.0)
		draw_line(control_points[i], control_points[i] - tangent, Color.ORANGE, 2.0)

func _collect_control_points() -> void:
	# Lê as posições globais dos nós filhos e as armazena no array
	control_points.clear()
	for child in control_points_node.get_children():
		control_points.append(child.position)

func _generate_all_curves() -> void:
	# Calcula matematicamente os traçados das três curvas e salva nas Line2Ds
	linear_line.points = CurveUtils.generate_linear(control_points, points_per_segment)
	catmull_line.points = CurveUtils.generate_catmull_rom(control_points, points_per_segment)
	bezier_line.points = CurveUtils.generate_bezier(control_points, points_per_segment)

func _unhandled_input(event: InputEvent) -> void:
	# Escuta as teclas configuradas no Input Map para trocar a curva exibida
	if event.is_action_pressed("curve_linear"):
		_set_curve_mode(CurveType.LINEAR)
	elif event.is_action_pressed("curve_catmull_rom"):
		_set_curve_mode(CurveType.CATMULL_ROM)
	elif event.is_action_pressed("curve_bezier"):
		_set_curve_mode(CurveType.BEZIER)

func _set_curve_mode(mode: CurveType) -> void:
	current_curve = mode

	# Liga apenas a visibilidade da curva selecionada no momento
	linear_line.visible = (mode == CurveType.LINEAR)
	catmull_line.visible = (mode == CurveType.CATMULL_ROM)
	bezier_line.visible = (mode == CurveType.BEZIER)

	var baked_points: PackedVector2Array
	
	# Associa os pontos processados correspondentes e atualiza o texto na UI
	match mode:
		CurveType.LINEAR:
			baked_points = linear_line.points
			ui_label.text = "Curva Atual (1/3): Interpolação Linear ----- Pressione: 2 = Catmull-Rom | 3 = Bézier"
		CurveType.CATMULL_ROM:
			baked_points = catmull_line.points
			ui_label.text = "Curva Atual (2/3): Catmull-Rom (interpolação) ----- Pressione: 1 = Linear | 3 = Bézier"
		CurveType.BEZIER:
			baked_points = bezier_line.points
			ui_label.text = "Curva Atual (3/3): Bézier cúbica (aproximação) ----- Pressione: 1 = Linear | 2 = Catmull-Rom"
			
	# Envia os pontos finais calculados para o script do ratinho/flecha se guiar
	mouse.set_path(baked_points)
	queue_redraw() # Solicita uma atualização visual
