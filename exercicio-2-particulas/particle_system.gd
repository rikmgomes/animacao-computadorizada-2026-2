extends Node2D
class_name ParticleSystem

enum EmitterType { POINT, AREA, RING }                           # 3 formas de nascimento
enum BehaviorType { GRAVITY, EXPLOSION, ORBIT, WAVE, ATTRACTOR } # 5 comportamentos
enum AttributeMode { COLOR_FADE, SIZE_PULSE, SHAPE_MORPH }       # 3 variações de atributos
enum DeathType { LIFETIME, OFFSCREEN }                           # 2 critérios de morte

# Duração (segundos) de um ciclo completo de variação
const ATTRIBUTE_CYCLE_DURATION: float = 2.5

var emitter_type: int = EmitterType.POINT
var behavior_type: int = BehaviorType.GRAVITY
var attribute_mode: int = AttributeMode.COLOR_FADE
var death_type: int = DeathType.LIFETIME

# Classe interna que representa 1 partícula
class Particle:
	var position: Vector2
	var velocity: Vector2
	var color: Color
	var size: float
	var shape: int # 0 = círculo, 1 = quadrado, 2 = triângulo
	var life: float
	var age: float = 0.0
	var angle: float = 0.0
	var angular_velocity: float = 0.0
	var extra: Dictionary = {} # dados específicos de cada comportamento

var particles: Array = []
var spawn_timer: float = 0.0
var spawn_rate: float = 60.0 # partículas nascendo por segundo
var emission_area_size: Vector2 = Vector2(400, 200)
var emission_ring_radius: float = 100.0
var screen_size: Vector2

var total_spawned: int = 0
var total_died: int = 0
var births_per_second: int = 0
var deaths_per_second: int = 0
var _births_this_second: int = 0
var _deaths_this_second: int = 0
var _stats_timer: float = 0.0

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _process(delta: float) -> void:
	spawn_timer += delta
	var spawn_interval := 1.0 / spawn_rate
	while spawn_timer >= spawn_interval:
		spawn_timer -= spawn_interval
		_spawn_particle()
	_update_particles(delta)
	_update_stats(delta)
	queue_redraw()

# Atualiza os contadores de nascimento/morte por segundo
func _update_stats(delta: float) -> void:
	_stats_timer += delta
	if _stats_timer >= 1.0:
		births_per_second = _births_this_second
		deaths_per_second = _deaths_this_second
		_births_this_second = 0
		_deaths_this_second = 0
		_stats_timer = 0.0

func alive_count() -> int:
	return particles.size()

# Onde e como cada partícula nasce
func _spawn_particle() -> void:
	var p := Particle.new()

	match emitter_type:
		EmitterType.POINT:
			# Emissor pontual: tudo nasce exatamente no centro
			p.position = Vector2.ZERO
			p.velocity = Vector2(randf_range(-50, 50), randf_range(-150, -50))

		EmitterType.AREA:
			# Emissor de área: nasce em qualquer ponto dentro de um retângulo
			p.position = Vector2(
				randf_range(-emission_area_size.x / 2, emission_area_size.x / 2),
				randf_range(-emission_area_size.y / 2, emission_area_size.y / 2)
			)
			p.velocity = Vector2(randf_range(-30, 30), randf_range(-80, -20))

		EmitterType.RING:
			# Emissor em anel: nasce sobre um círculo, indo pra fora
			var ang := randf_range(0, TAU)
			p.position = Vector2(cos(ang), sin(ang)) * emission_ring_radius
			p.velocity = Vector2(cos(ang), sin(ang)) * randf_range(50, 120)

	# Critérios de morte
	match death_type:
		DeathType.LIFETIME: # vida curta (2-4s) e fade até sumir
			p.life = randf_range(2.0, 4.0)
		DeathType.OFFSCREEN: # partícula mantém opacidade total e só desaparece ao sair da tela
			p.life = randf_range(15.0, 25.0)

	p.age = 0.0
	p.size = randf_range(4.0, 10.0)
	p.shape = randi() % 3
	p.color = Color(1, 1, 1, 1)
	p.angle = randf_range(0, TAU)
	p.angular_velocity = randf_range(-2.0, 2.0)
	p.extra = {}

	# Dados extras que alguns comportamentos precisam guardar por partícula
	match behavior_type:
		BehaviorType.ORBIT:
			p.extra["center"] = Vector2.ZERO
			var r := p.position.length()
			p.extra["radius"] = r if r > 10.0 else randf_range(50, 150)
			p.extra["angle"] = p.position.angle()
			p.extra["angular_speed"] = randf_range(1.0, 3.0) * (1 if randi() % 2 == 0 else -1)
		BehaviorType.ATTRACTOR:
			p.extra["target"] = Vector2.ZERO
		BehaviorType.WAVE:
			p.extra["base_x"] = p.position.x
			p.extra["wave_speed"] = randf_range(2.0, 4.0)
			p.extra["wave_amplitude"] = randf_range(20, 60)

	particles.append(p)
	total_spawned += 1
	_births_this_second += 1

# Variação de Comportamentos + Atributos
func _update_particles(delta: float) -> void:
	var alive: Array = []
	for p in particles:
		p.age += delta
		var t_life: float = clamp(p.age / p.life, 0.0, 1.0)
		var t_attr: float = fmod(p.age, ATTRIBUTE_CYCLE_DURATION) / ATTRIBUTE_CYCLE_DURATION # t_attr: controla a animação dos atributos em um ciclo contínuo
		match behavior_type:
			BehaviorType.GRAVITY: # puxa a partícula para baixo com o tempo
				p.velocity.y += 200.0 * delta
				p.position += p.velocity * delta

			BehaviorType.EXPLOSION: # explosão radial que desacelera (atrito)
				p.velocity *= (1.0 - 1.5 * delta)
				p.position += p.velocity * delta

			BehaviorType.ORBIT: # órbita circular ao redor de um centro
				p.extra["angle"] += p.extra["angular_speed"] * delta
				var r: float = p.extra["radius"]
				p.position = p.extra["center"] + Vector2(cos(p.extra["angle"]), sin(p.extra["angle"])) * r

			BehaviorType.WAVE: # sobe enquanto oscila em senoide (tipo fumaça)
				p.position.y -= 60.0 * delta
				p.position.x = p.extra["base_x"] + sin(p.age * p.extra["wave_speed"]) * p.extra["wave_amplitude"]

			BehaviorType.ATTRACTOR: # espiralando pra um ponto (vórtice)
				var dir: Vector2 = p.extra["target"] - p.position
				var dist: float = max(dir.length(), 1.0)
				p.velocity += dir.normalized() * (3000.0 / dist) * delta
				p.position += p.velocity * delta

		p.angle += p.angular_velocity * delta

		match attribute_mode:
			AttributeMode.COLOR_FADE: # cor percorre o círculo de matizes (HSV), sem afetar transparência
				var hue_color := Color.from_hsv(t_attr, 1.0, 1.0, 1.0)
				p.color.r = hue_color.r
				p.color.g = hue_color.g
				p.color.b = hue_color.b
			AttributeMode.SIZE_PULSE: # tamanho cresce e depois encolhe e repete
				p.size = lerp(4.0, 16.0, sin(t_attr * PI))
			AttributeMode.SHAPE_MORPH: # forma alterna repetidamente: círculo > quadrado > triângulo > ...
				p.shape = int(t_attr * 3.0) % 3

		match death_type:
			DeathType.LIFETIME:
				p.color.a = 1.0 - t_life
			DeathType.OFFSCREEN:
				p.color.a = 1.0

		var dead := false
		match death_type:
			DeathType.LIFETIME:
				dead = p.age >= p.life
			DeathType.OFFSCREEN:
				var half: Vector2 = screen_size / 2.0
				dead = abs(p.position.x) > half.x + 50.0 or abs(p.position.y) > half.y + 50.0

		if not dead:
			alive.append(p)
		else:
			total_died += 1
			_deaths_this_second += 1

	particles = alive

func _draw() -> void:
	for p in particles:
		match p.shape:
			0:
				draw_circle(p.position, p.size, p.color)
			1:
				var rect := Rect2(p.position - Vector2(p.size, p.size), Vector2(p.size, p.size) * 2.0)
				draw_rect(rect, p.color)
			2:
				_draw_triangle(p.position, p.size, p.angle, p.color)

func _draw_triangle(pos: Vector2, size: float, angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(3):
		var a: float = angle + i * TAU / 3.0 - PI / 2.0
		points.append(pos + Vector2(cos(a), sin(a)) * size)
	draw_colored_polygon(points, color)

# Limpa as partículas atuais (só pra deixar a tela mais limpa)
func reset() -> void:
	particles.clear()
