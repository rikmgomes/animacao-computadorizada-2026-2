extends Node2D

@export var arrow_length: float = 40.0
@export var arrow_thickness: float = 10.0
@export var head_length: float = 15.0
@export var head_width: float = 10.0 # Distância do centro até a ponta lateral da cabeça
@export var arrow_color: Color = Color(0.691, 0.17, 1.0, 1.0)

func _ready() -> void:
	_build_arrow()

func _build_arrow() -> void:
	var polygon := Polygon2D.new()
	
	var half_len: float = arrow_length * 0.5
	var half_thick: float = arrow_thickness * 0.5
	var neck_x: float = half_len - head_length
	
	# Desenhando a flecha apontando para a direita (Eixo X positivo)
	# O centro da flecha fica em (0, 0)
	polygon.polygon = PackedVector2Array([
		Vector2(-half_len, -half_thick), # Traseira superior
		Vector2(neck_x, -half_thick),    # Pescoço superior
		Vector2(neck_x, -head_width),    # Base superior da cabeça
		Vector2(half_len, 0),            # Ponta da flecha (frente)
		Vector2(neck_x, head_width),     # Base inferior da cabeça
		Vector2(neck_x, half_thick),     # Pescoço inferior
		Vector2(-half_len, half_thick)   # Traseira inferior
	])
	
	polygon.color = arrow_color
	add_child(polygon)
