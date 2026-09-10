extends Node2D

# Configurações de movimento exportadas para o Inspector
@export var speed: float = 160.0
@export var loop: bool = true
@export var rotate_towards_movement: bool = true
@export var speed_curve: Curve # Permite variar a velocidade ao longo do trajeto (easing)

# Variáveis internas para o cálculo da distância real da curva
var baked_points: PackedVector2Array = []
var cumulative_distances: PackedFloat32Array = []
var total_length: float = 0.0
var distance_traveled: float = 0.0

func set_path(points: PackedVector2Array) -> void:
	# Recebe os novos pontos calculados, zera a distância e recalcula o percurso
	baked_points = points
	distance_traveled = 0.0
	_bake_distances()
	if baked_points.size() > 0:
		global_position = baked_points[0]

func _bake_distances() -> void:
	# Pré-calcula a distância acumulada de cada ponto em relação ao início da curva.
	# Isso é vital para mover o objeto a uma velocidade constante e independente
	# de quão próximos ou distantes os pontos da curva estão entre si.
	cumulative_distances.clear()
	total_length = 0.0
	if baked_points.is_empty():
		return
	cumulative_distances.append(0.0)
	for i in range(1, baked_points.size()):
		total_length += baked_points[i].distance_to(baked_points[i - 1])
		cumulative_distances.append(total_length)

func _physics_process(delta: float) -> void:
	# Interrompe o processo se o caminho não for válido
	if baked_points.size() < 2 or total_length <= 0.0:
		return

	# Ajusta a velocidade usando uma curva do painel Inspector (ex: acelerar/desacelerar nas pontas)
	var speed_factor := 1.0
	if speed_curve:
		var progress = distance_traveled / total_length
		speed_factor = speed_curve.sample(clamp(progress, 0.0, 1.0))

	# Avança a distância total percorrida no tempo atual (delta)
	distance_traveled += speed * speed_factor * delta

	# Comportamento ao chegar no fim do percurso
	if distance_traveled >= total_length:
		if loop:
			# Retorna ao zero, mantendo qualquer "sobra" de movimento
			distance_traveled = fmod(distance_traveled, total_length)
		else:
			# Para no final exato
			distance_traveled = total_length

	# Obtém a posição e o vetor de direção exatos no ponto em que estamos
	var sample = _sample_position(distance_traveled)
	global_position = sample.position
	
	# Rotaciona a nossa flecha apontando-a na direção do vetor tangente
	if rotate_towards_movement and sample.direction.length() > 0.001:
		rotation = sample.direction.angle()

func _sample_position(dist: float) -> Dictionary:
	# Descobre em qual "segmento de reta" entre dois pontos nós estamos no momento
	var index := 0
	for i in range(cumulative_distances.size() - 1):
		index = i
		if dist <= cumulative_distances[i + 1]:
			break

	# Calcula um 't' de 0 a 1 representando a nossa posição APENAS dentro desse pequeno segmento
	var seg_start = cumulative_distances[index]
	var seg_end = cumulative_distances[min(index + 1, cumulative_distances.size() - 1)]
	var seg_length = max(seg_end - seg_start, 0.0001)
	var local_t = clamp((dist - seg_start) / seg_length, 0.0, 1.0)

	# Pega os dois pontos que formam esse segmento
	var p0 = baked_points[index]
	var p1 = baked_points[min(index + 1, baked_points.size() - 1)]

	# Retorna a posição exata (interpolação) e o vetor para a rotação (p1 - p0)
	return {
		"position": p0.lerp(p1, local_t),
		"direction": p1 - p0,
	}
