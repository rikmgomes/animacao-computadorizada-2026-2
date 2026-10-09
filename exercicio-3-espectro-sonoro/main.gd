extends Node2D

const BUS_NAME := "EspectroMusica" # Nome da bus de áudio usada para analisar a música

# Física e configurações principais do jogo
const CUBE := 40.0 # Tamanho do cubo do jogador
const GRAVITY := 2600.0 # Força da gravidade aplicada ao jogador
const JUMP_SPEED := 860.0 # Velocidade inicial do pulo
const AIR_TIME := 2.0 * JUMP_SPEED / GRAVITY # Tempo aproximado que o jogador permanece no ar
const BASE_SPEED := 380.0 # Velocidade base de rolagem do mundo
const MID_BONUS := 220.0 # Velocidade extra máxima obtida dos médios
const RAMP_MAX := 100.0 # Aumento máximo de dificuldade ao longo do tempo
const MAX_SPEED := BASE_SPEED + MID_BONUS + RAMP_MAX # Velocidade máxima possível
const FLOATER_LANE := 62.0 # Altura do centro do floater em relação ao chão
const MAX_PARTICLES := 700 # Quantidade máxima de partículas simultâneas

# Configurações do parallax dos prédios
const LAYER_SPEED := [0.12, 0.25, 0.45] # Fração da velocidade do mundo de cada camada
const LAYER_W := [Vector2(70.0, 120.0), Vector2(90.0, 150.0), Vector2(110.0, 180.0)] # Largura mínima e máxima dos prédios
const LAYER_H := [Vector2(0.28, 0.52), Vector2(0.20, 0.42), Vector2(0.12, 0.32)] # Altura mínima e máxima como fração da tela
const LAYER_CELL := [Vector2(12.0, 16.0), Vector2(16.0, 22.0), Vector2(20.0, 28.0)] # Tamanho das células das janelas

# Tipos possíveis de obstáculos
enum Kind { BLOCK, SPIKE, HOLE, FLOATER }

# Classe que representa um obstáculo
class Obstacle extends RefCounted:
	var kind: int = 0 # Tipo do obstáculo
	var x: float = 0.0 # Posição horizontal do obstáculo
	var w: float = 40.0 # Largura do obstáculo
	var h: float = 40.0 # Altura do obstáculo
	var hue: float = 0.0 # Matiz da cor do obstáculo
	var pulse: float = 0.0 # Intensidade do pulso causado pela batida
	var bob_from: float = 0.0 # Posição inicial da trajetória vertical do floater
	var bob_to: float = 0.0 # Posição final da trajetória vertical do floater
	var bob_t: float = 1.0 # Progresso da animação vertical
	var bob_sign: float = 1.0 # Direção atual da oscilação vertical

# Classe que representa uma partícula
class Particle extends RefCounted:
	var pos: Vector2 = Vector2.ZERO # Posição da partícula
	var vel: Vector2 = Vector2.ZERO # Velocidade da partícula
	var life: float = 1.0 # Tempo de vida restante
	var max_life: float = 1.0 # Tempo de vida máximo
	var size: float = 4.0 # Tamanho da partícula
	var color: Color = Color.WHITE # Cor da partícula
	var gravity: float = 0.0 # Gravidade aplicada à partícula

# Classe que representa um prédio do cenário
class Building extends RefCounted:
	var layer: int = 0 # Camada de parallax do prédio
	var x: float = 0.0 # Posição horizontal
	var w: float = 100.0 # Largura do prédio
	var h: float = 200.0 # Altura do prédio
	var uid: int = 0 # Identificador único do prédio
	var cols: int = 4 # Quantidade de colunas de janelas
	var rows: int = 8 # Quantidade de linhas de janelas
	var hue_off: float = 0.0 # Deslocamento de matiz do prédio
	var glow := PackedFloat32Array() # Brilho atual de cada janela
	var th := PackedFloat32Array() # Limiar que determina quando cada janela acende
	var win_hue := PackedFloat32Array() # Deslocamento de cor de cada janela

var spectrum: Spectrum # Referência ao analisador de espectro
var music: AudioStreamPlayer # Reprodutor da música
var track_index := 0 # Índice da música atual
var grid_last_idx := -999999 # Índice da última batida processada pela grade de BPM

# Lista de músicas
var tracks: Array[Dictionary] = [
	{"path": "res://music1.wav", "bpm": 168.0, "offset": 0.0},
	{"path": "res://music2.wav", "bpm": 100.0, "offset": 0.0},
	{"path": "res://music3.wav", "bpm": 120.0, "offset": 0.0},
]

var buildings: Array[Building] = [] # Lista dos prédios existentes
var win_hi := PackedFloat32Array([0.6, 0.6, 0.6]) # Teto recente de intensidade de cada faixa
var win_lo := PackedFloat32Array([0.0, 0.0, 0.0]) # Piso recente de intensidade de cada faixa
var win_norm := PackedFloat32Array([0.0, 0.0, 0.0]) # Intensidade normalizada de cada faixa

var view := Vector2(1280, 720) # Tamanho inicial da área visível
var ground_y := 560.0 # Posição vertical do chão
var px := 256.0 # Posição horizontal fixa do jogador

var foot_y := 560.0 # Posição vertical dos pés do jogador
var vy := 0.0 # Velocidade vertical do jogador
var spin := 0.0 # Rotação atual do jogador
var on_ground := true # Indica se o jogador está no chão
var alive := true # Indica se o jogador ainda está vivo
var dead_timer := 0.0 # Tempo restante antes de reiniciar após morrer

var obstacles: Array[Obstacle] = [] # Lista dos obstáculos ativos
var particles: Array[Particle] = [] # Lista das partículas ativas
var rings: Array[float] = [] # Progresso dos anéis de onda de choque
var trail: Array[Vector2] = [] # Posições usadas para desenhar o rastro do jogador
var trail_timer := 0.0 # Temporizador para criar novos pontos do rastro
var spark_accum := 0.0 # Acumulador para emissão de faíscas

var scroll_speed := BASE_SPEED # Velocidade atual de rolagem do mundo
var world_x := 0.0 # Posição acumulada do mundo
var time_alive := 0.0 # Tempo que o jogador permanece vivo
var score := 0.0 # Pontuação atual
var best := 0 # Maior pontuação registrada
var since_spawn := 0.0 # Tempo desde o último obstáculo gerado
var beat_count := 0 # Quantidade de batidas processadas

var hue_base := 0.6 # Matiz base das cores do cenário
var beat_flash := 0.0 # Intensidade do flash causado por uma batida
var show_debug := false # Define se as informações de debug são exibidas

# Inicialização
func _ready() -> void:
	randomize() # Inicializa o gerador de números aleatórios
	_setup_audio() # Configura o sistema de áudio e análise do espectro
	_update_layout() # Atualiza as posições de acordo com o tamanho da tela
	_init_buildings() # Cria os prédios iniciais
	_reset_game() # Inicializa ou reinicia o estado do jogo

func _setup_audio() -> void:
	# Cria uma bus exclusiva para a música e conecta o analisador de espectro
	AudioServer.add_bus() # Adiciona uma nova bus de áudio
	var idx := AudioServer.bus_count - 1 # Obtém o índice da nova bus
	AudioServer.set_bus_name(idx, BUS_NAME) # Define o nome da bus
	AudioServer.set_bus_send(idx, "Master") # Envia o áudio da bus para a saída principal

	spectrum = Spectrum.new() # Cria o analisador de espectro
	add_child(spectrum) # Adiciona o analisador à árvore de cena
	spectrum.setup(BUS_NAME) # Configura o analisador para a bus da música
	spectrum.beat.connect(_on_beat) # Conecta o sinal de batida ao método correspondente

	music = AudioStreamPlayer.new() # Cria o reprodutor de áudio
	music.bus = BUS_NAME # Envia a música para a bus analisada
	music.finished.connect(music.play) # Repete a música quando ela termina
	add_child(music) # Adiciona o reprodutor à árvore de cena
	_play_track(0) # Inicia a primeira música

# Toca a música de índice informado e mantém o jogo funcionando
func _play_track(index: int) -> void:
	track_index = posmod(index, tracks.size()) # Garante que o índice permaneça dentro da lista
	var path: String = tracks[track_index]["path"] # Obtém o caminho da música
	if not ResourceLoader.exists(path): # Verifica se o arquivo da música existe
		push_error("Música não encontrada: " + path + " (ajuste a lista tracks em main.gd)") # Exibe um erro caso não exista
		return # Interrompe a execução
	music.stream = load(path) # Carrega a música
	music.play() # Inicia a reprodução

	# Define o método de detecção de batidas de acordo com o BPM da música
	var bpm: float = tracks[track_index]["bpm"] # Obtém o BPM configurado
	spectrum.beat_mode = 2 if bpm > 0.0 else 1 # Usa grade de BPM quando existe BPM e fluxo quando não existe
	grid_last_idx = -999999 # Reinicia o índice da grade

# Calcula a posição da música considerando a latência do áudio
func _grid_time() -> float:
	return music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() # Retorna a posição corrigida da música

func _update_grid_beats() -> void:
	if spectrum.beat_mode != 2 or music == null or not music.playing: # Verifica se a grade de BPM está ativa e a música está tocando
		return # Interrompe caso a grade não esteja disponível
	var bpm: float = tracks[track_index]["bpm"] # Obtém o BPM da música atual
	if bpm <= 0.0: # Verifica se existe um BPM válido
		return # Interrompe caso não exista
	var period := 60.0 / bpm # Calcula o intervalo entre batidas
	var offset: float = tracks[track_index]["offset"] # Obtém o deslocamento configurado
	var idx := floori((_grid_time() - offset) / period) # Calcula o índice da batida atual
	if grid_last_idx == -999999: # Verifica se é a primeira atualização
		grid_last_idx = idx # Inicializa o índice atual
		return # Aguarda a próxima batida
	if idx < grid_last_idx: # Detecta se a música voltou ao início
		grid_last_idx = idx - 1 # Ajusta o índice para o loop
	if idx > grid_last_idx: # Verifica se uma nova batida ocorreu
		grid_last_idx = idx # Atualiza o índice da última batida
		# Usa a energia dos graves naquele momento para definir a força da batida
		var level := maxf(spectrum.bass_raw, spectrum.bass) # Obtém a intensidade dos graves
		_on_beat(lerpf(0.3, 1.0, level)) # Envia a batida com intensidade proporcional aos graves

# Sincroniza a grade com a batida atual da música
func _sync_grid() -> void:
	var bpm: float = tracks[track_index]["bpm"] # Obtém o BPM da música atual
	if bpm <= 0.0: # Verifica se existe um BPM válido
		return # Interrompe caso não exista
	tracks[track_index]["offset"] = fposmod(_grid_time(), 60.0 / bpm) # Calcula e salva o novo offset
	grid_last_idx = -999999 # Reinicia o índice da grade
	print("offset da música %d = %.3f  (copie para a lista tracks)" % [track_index + 1, tracks[track_index]["offset"]]) # Exibe o novo offset

# Ajusta manualmente o alinhamento da grade
func _nudge_grid(dt: float) -> void:
	var bpm: float = tracks[track_index]["bpm"] # Obtém o BPM da música atual
	if bpm <= 0.0: # Verifica se existe um BPM válido
		return # Interrompe caso não exista
	var offset: float = tracks[track_index]["offset"] # Obtém o offset atual
	tracks[track_index]["offset"] = offset + dt # Adiciona o ajuste ao offset
	grid_last_idx = -999999 # Reinicia o índice da grade
	print("offset da música %d = %.3f  (copie para a lista tracks)" % [track_index + 1, tracks[track_index]["offset"]]) # Exibe o novo offset

func _update_layout() -> void:
	view = get_viewport_rect().size # Obtém o tamanho atual da janela
	ground_y = view.y * 0.78 # Define o chão como uma porcentagem da altura da tela
	px = view.x * 0.2 # Mantém o jogador em uma posição fixa horizontal

func _reset_game() -> void:
	obstacles.clear() # Remove todos os obstáculos
	particles.clear() # Remove todas as partículas
	rings.clear() # Remove todos os anéis
	trail.clear() # Remove o rastro do jogador
	foot_y = ground_y # Coloca o jogador no chão
	vy = 0.0 # Zera a velocidade vertical
	spin = 0.0 # Zera a rotação
	on_ground = true # Define o jogador como estando no chão
	alive = true # Define o jogador como vivo
	time_alive = 0.0 # Reinicia o tempo de sobrevivência
	score = 0.0 # Reinicia a pontuação
	scroll_speed = BASE_SPEED # Restaura a velocidade inicial
	since_spawn = 0.0 # Reinicia o temporizador de geração

# Entrada do jogador
func _unhandled_input(event: InputEvent) -> void:
	var jump := event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_up") # Verifica se o jogador pressionou o comando de pulo
	if event is InputEventMouseButton and event.is_pressed(): # Verifica se um botão do mouse foi pressionado
		var mb := event as InputEventMouseButton # Converte o evento para botão do mouse
		if mb.button_index == MOUSE_BUTTON_LEFT: # Verifica o botão esquerdo
			jump = true # Define que o jogador deve pular
		elif mb.button_index == MOUSE_BUTTON_RIGHT: # Verifica o botão direito
			_play_track(track_index + 1) # Avança para a próxima música
	if jump: # Verifica se o pulo foi solicitado
		_jump() # Executa o pulo
	if event is InputEventKey and event.is_pressed() and not event.is_echo(): # Verifica uma tecla pressionada sem repetição automática
		var key := (event as InputEventKey).keycode # Obtém o código da tecla
		if key == KEY_F1: # Verifica a tecla F1
			show_debug = not show_debug # Alterna a exibição das informações de debug
		elif key == KEY_M: # Verifica a tecla M
			_play_track(track_index + 1) # Avança para a próxima música
		elif key == KEY_B: # Verifica a tecla B
			# Alterna entre os três métodos de detecção
			var bpm_now: float = tracks[track_index]["bpm"] # Obtém o BPM da música atual
			spectrum.beat_mode = (spectrum.beat_mode + 1) % 3 # Passa para o próximo modo
			if spectrum.beat_mode == 2 and bpm_now <= 0.0: # Verifica se a grade foi selecionada sem BPM disponível
				spectrum.beat_mode = 0 # Volta para o detector por nível
			grid_last_idx = -999999 # Reinicia o índice da grade
		elif key == KEY_T: # Verifica a tecla T
			_sync_grid() # Sincroniza a grade com a batida atual
		elif key == KEY_COMMA: # Verifica a tecla de vírgula
			_nudge_grid(-0.02) # Adianta a grade em 0,02 segundos
		elif key == KEY_PERIOD: # Verifica a tecla de ponto
			_nudge_grid(0.02) # Atrasa a grade em 0,02 segundos

func _jump() -> void:
	if alive and on_ground: # Permite o pulo somente se o jogador estiver vivo e no chão
		vy = -JUMP_SPEED # Aplica a velocidade vertical inicial
		on_ground = false # Define que o jogador saiu do chão
		_burst(Vector2(px, ground_y), 10, Color.WHITE, 160.0, 0.4, 500.0) # Cria partículas no início do pulo

# Loop principal
func _process(delta: float) -> void:
	_update_layout() # Atualiza o layout conforme o tamanho da janela
	beat_flash = maxf(0.0, beat_flash - delta * 3.5) # Reduz gradualmente o flash da última batida
	# AGUDOS controlam a velocidade de mudança do matiz do mundo
	hue_base = fmod(hue_base + delta * (0.02 + 0.12 * spectrum.high), 1.0) # Atualiza continuamente o matiz

	if alive: # Verifica se o jogador está vivo
		_update_game(delta) # Atualiza a lógica principal do jogo
	else: # Caso o jogador esteja morto
		dead_timer -= delta # Reduz o tempo restante antes do reinício
		if dead_timer <= 0.0: # Verifica se o tempo acabou
			_reset_game() # Reinicia o jogo

	_update_grid_beats() # Atualiza a grade de batidas
	_update_windows(delta) # Atualiza as janelas dos prédios
	_update_effects(delta) # Atualiza partículas, rastros e efeitos
	queue_redraw() # Solicita que a cena seja redesenhada

func _update_game(delta: float) -> void:
	time_alive += delta # Aumenta o tempo de sobrevivência
	since_spawn += delta # Aumenta o tempo desde o último obstáculo

	# MÉDIOS controlam a velocidade de rolagem do mundo
	var target := BASE_SPEED + MID_BONUS * spectrum.mid + minf(time_alive * 4.0, RAMP_MAX) # Calcula a velocidade desejada
	scroll_speed = lerpf(scroll_speed, target, 1.0 - exp(-1.5 * delta)) # Suaviza a mudança de velocidade
	world_x += scroll_speed * delta # Atualiza a posição acumulada do mundo
	score += scroll_speed * delta * 0.05 # Aumenta a pontuação conforme o jogador avança
	_update_buildings(delta) # Move e atualiza os prédios

	# Gera um obstáculo de segurança caso a música fique muito tempo sem batidas
	if since_spawn > 1.8: # Verifica se passou tempo demais sem gerar obstáculo
		_try_spawn(0.5) # Tenta gerar um obstáculo com intensidade média

	_update_obstacles(delta) # Atualiza a posição dos obstáculos
	_update_player(delta) # Atualiza a física do jogador
	_check_collisions() # Verifica colisões

# Batida da música gera obstáculos e efeitos
func _on_beat(strength: float) -> void:
	beat_flash = 1.0 # Ativa o flash visual da batida
	rings.append(0.0) # Cria um novo anel de onda de choque
	_beat_windows(strength) # Faz algumas janelas reagirem à batida
	if not alive: # Verifica se o jogador está morto
		return # Não gera obstáculos se o jogador estiver morto
	beat_count += 1 # Incrementa o contador de batidas

	for o in obstacles: # Percorre todos os obstáculos
		o.pulse = 1.0 # Ativa o pulso visual do obstáculo
		# A cada duas batidas o floater inverte sua direção vertical
		if o.kind == Kind.FLOATER and beat_count % 2 == 0: # Verifica se é um floater e se é uma batida par
			_flip_bob(o) # Inverte a direção da oscilação
		# Cada obstáculo gera partículas quando ocorre uma batida
		_burst(_obstacle_center(o), 3 + int(6.0 * strength), # Define a quantidade de partículas
			Color.from_hsv(o.hue, 0.7, 1.0), 200.0, 0.5, 300.0) # Define cor, velocidade, duração e gravidade

	# GRAVES controlam a criação de um novo obstáculo
	_try_spawn(strength) # Tenta gerar um obstáculo usando a força da batida

func _try_spawn(strength: float) -> bool:
	var kind: int = _pick_kind() # Escolhe aleatoriamente o tipo de obstáculo
	var gap := MAX_SPEED * 0.55 # Define a distância mínima entre obstáculos
	if kind == Kind.FLOATER: # Verifica se o obstáculo é um floater
		gap *= 1.3 # Aumenta o espaço necessário para floaters
	var spawn_x := view.x + 60.0 # Define a posição inicial fora da tela
	if not obstacles.is_empty(): # Verifica se já existem obstáculos
		var last: Obstacle = obstacles[obstacles.size() - 1] # Obtém o último obstáculo
		if last.x + last.w + gap > spawn_x: # Verifica se existe espaço suficiente
			return false # Impede a criação do novo obstáculo

	var o := Obstacle.new() # Cria um novo obstáculo
	o.kind = kind # Define o tipo do obstáculo
	o.x = spawn_x # Define a posição horizontal
	o.hue = fmod(hue_base + randf_range(0.0, 0.2), 1.0) # Define uma cor próxima ao matiz atual
	match kind: # Configura o obstáculo de acordo com seu tipo
		Kind.BLOCK: # Configura um bloco
			o.w = randf_range(34.0, 60.0) # Define uma largura aleatória
			o.h = lerpf(36.0, 84.0, strength) # Define a altura de acordo com a força da batida
		Kind.SPIKE: # Configura um espinho
			o.w = randf_range(36.0, 52.0) # Define uma largura aleatória
			o.h = lerpf(36.0, 60.0, strength) # Define a altura de acordo com a força da batida
		Kind.HOLE: # Configura um buraco
			o.w = lerpf(110.0, 180.0, strength) # Define a largura de acordo com a força da batida
			o.h = 0.0 # Buracos não possuem altura
		Kind.FLOATER: # Configura um floater
			o.w = 34.0 # Define a largura
			o.h = 34.0 # Define a altura
			o.bob_sign = 1.0 if randf() < 0.5 else -1.0 # Escolhe aleatoriamente a direção inicial
			o.bob_to = o.bob_sign * (8.0 + 24.0 * spectrum.mid) # Define a amplitude com base nos médios
			o.bob_from = o.bob_to # Define a posição inicial igual à posição final
			o.bob_t = 1.0 # Define a animação como concluída
	obstacles.append(o) # Adiciona o obstáculo à lista
	since_spawn = 0.0 # Reinicia o temporizador de geração
	return true # Informa que o obstáculo foi criado

func _pick_kind() -> int:
	var r := randf() # Gera um número aleatório entre 0 e 1
	if r < 0.30: # Primeiros 30% são blocos
		return Kind.BLOCK # Retorna o tipo bloco
	if r < 0.55: # Próximos 25% são espinhos
		return Kind.SPIKE # Retorna o tipo espinho
	if r < 0.80: # Próximos 25% são buracos
		return Kind.HOLE # Retorna o tipo buraco
	return Kind.FLOATER # Os 20% restantes são floaters

# Atualiza os obstáculos
func _update_obstacles(delta: float) -> void:
	for i in range(obstacles.size() - 1, -1, -1): # Percorre a lista de trás para frente
		var o: Obstacle = obstacles[i] # Obtém o obstáculo atual
		o.pulse = maxf(0.0, o.pulse - delta * 4.0) # Reduz gradualmente o pulso
		var v := scroll_speed # Define a velocidade atual
		if o.kind == Kind.FLOATER: # Verifica se o obstáculo é um floater
			# Aplica uma aceleração gradual conforme o floater se aproxima do jogador
			var prog := clampf(1.0 - (o.x - px) / (view.x - px), 0.0, 1.0) # Calcula o progresso da aproximação
			v *= 1.0 + 0.3 * ease_in_cubic(prog) # Aumenta a velocidade usando easing
			o.bob_t = minf(1.0, o.bob_t + delta / 0.35) # Atualiza o progresso da oscilação
		o.x -= v * delta # Move o obstáculo para a esquerda
		if o.x + o.w < -100.0: # Verifica se saiu da tela
			obstacles.remove_at(i) # Remove o obstáculo da lista

func _flip_bob(o: Obstacle) -> void:
	var amp := 8.0 + 24.0 * spectrum.mid # MÉDIOS controlam a amplitude da oscilação
	o.bob_from = _bob_offset(o) # Guarda a posição atual da oscilação
	o.bob_sign = -o.bob_sign # Inverte a direção vertical
	o.bob_to = o.bob_sign * amp # Define o novo destino
	o.bob_t = 0.0 # Reinicia o progresso da animação

# Calcula a posição vertical do floater usando easing
func _bob_offset(o: Obstacle) -> float:
	return lerpf(o.bob_from, o.bob_to, ease_out_back(o.bob_t)) # Interpola entre a posição inicial e final

func _obstacle_center(o: Obstacle) -> Vector2:
	match o.kind: # Verifica o tipo do obstáculo
		Kind.BLOCK, Kind.SPIKE: # Blocos e espinhos ficam apoiados no chão
			return Vector2(o.x + o.w * 0.5, ground_y - o.h * 0.5) # Retorna o centro do obstáculo
		Kind.FLOATER: # Floaters ficam acima do chão
			return Vector2(o.x + o.w * 0.5, ground_y - FLOATER_LANE + _bob_offset(o)) # Retorna o centro considerando a oscilação
	return Vector2(o.x + o.w * 0.5, ground_y) # Retorna uma posição padrão

func _hitbox(o: Obstacle) -> Rect2:
	match o.kind: # Verifica o tipo do obstáculo
		Kind.BLOCK: # Define a hitbox do bloco
			return Rect2(o.x + 5.0, ground_y - o.h + 5.0, o.w - 10.0, o.h - 5.0) # Retorna um retângulo reduzido
		Kind.SPIKE: # Define a hitbox do espinho
			return Rect2(o.x + o.w * 0.25, ground_y - o.h * 0.75, o.w * 0.5, o.h * 0.75) # Retorna uma área menor que o desenho
		Kind.FLOATER: # Define a hitbox do floater
			var cy := ground_y - FLOATER_LANE + _bob_offset(o) # Calcula o centro vertical
			return Rect2(o.x + 4.0, cy - o.h * 0.5 + 4.0, o.w - 8.0, o.h - 8.0) # Retorna uma hitbox reduzida
	return Rect2() # Retorna um retângulo vazio para casos não tratados

# Atualiza o jogador
func _update_player(delta: float) -> void:
	if on_ground: # Verifica se o jogador está no chão
		foot_y = ground_y # Mantém os pés na altura do chão
		if not _has_ground_under(): # Verifica se existe chão abaixo do jogador
			on_ground = false # Começa a queda ao passar da borda

	if not on_ground: # Verifica se o jogador está no ar
		spin += delta * TAU / AIR_TIME # Faz uma rotação completa durante o pulo
		vy += GRAVITY * delta # Aplica a gravidade
		var next_y := foot_y + vy * delta # Calcula a próxima posição vertical
		var can_land := vy >= 0.0 and foot_y <= ground_y + 2.0 and next_y >= ground_y and _has_ground_under() # Verifica se pode pousar
		if can_land: # Verifica se o jogador chegou ao chão
			foot_y = ground_y # Coloca os pés no chão
			vy = 0.0 # Zera a velocidade vertical
			spin = 0.0 # Zera a rotação
			on_ground = true # Marca o jogador como estando no chão
			_burst(Vector2(px, ground_y), 8, Color.WHITE, 150.0, 0.35, 500.0) # Cria partículas ao pousar
		else: # Caso ainda esteja no ar
			foot_y = next_y # Atualiza a posição vertical

# Verifica se o centro do cubo está completamente sobre uma área de chão
func _has_ground_under() -> bool:
	var left := px - CUBE * 0.5 + 8.0 # Define o limite esquerdo da área de apoio
	var right := px + CUBE * 0.5 - 8.0 # Define o limite direito da área de apoio
	for o in obstacles: # Percorre os obstáculos
		if o.kind == Kind.HOLE and o.x <= left and o.x + o.w >= right: # Verifica se o jogador está totalmente sobre um buraco
			return false # Informa que não existe chão
	return true # Informa que existe chão

func _check_collisions() -> void:
	var body := Rect2(px - CUBE * 0.5 + 4.0, foot_y - CUBE + 4.0, CUBE - 8.0, CUBE - 8.0) # Cria a hitbox do jogador
	for o in obstacles: # Percorre os obstáculos
		if o.kind == Kind.HOLE: # Ignora buracos nesta verificação
			continue # Passa para o próximo obstáculo
		if body.intersects(_hitbox(o)): # Verifica se o jogador colidiu
			_die() # Mata o jogador
			return # Interrompe a verificação
	if foot_y > ground_y + 90.0: # Verifica se o jogador caiu muito abaixo do chão
		_die() # Mata o jogador

func _die() -> void:
	if not alive: # Verifica se o jogador já está morto
		return # Evita executar a morte novamente
	alive = false # Marca o jogador como morto
	dead_timer = 0.9 # Define o tempo até reiniciar
	best = maxi(best, int(score)) # Atualiza o recorde se necessário
	beat_flash = 1.0 # Ativa o flash de morte
	var c := Vector2(px, foot_y - CUBE * 0.5) # Define o centro da explosão
	_burst(c, 60, Color.WHITE, 520.0, 0.9, 900.0) # Cria uma explosão de partículas brancas
	_burst(c, 40, Color.from_hsv(hue_base, 0.8, 1.0), 380.0, 1.1, 900.0) # Cria uma segunda explosão colorida

# Partículas, rastro e anéis
func _burst(center: Vector2, count: int, color: Color, speed: float, life: float, gravity: float) -> void:
	for i in count: # Cria a quantidade solicitada de partículas
		if particles.size() >= MAX_PARTICLES: # Verifica se atingiu o limite
			return # Interrompe a criação de partículas
		var p := Particle.new() # Cria uma nova partícula
		var ang := randf() * TAU # Gera uma direção aleatória
		p.pos = center # Define a posição inicial
		p.vel = Vector2(cos(ang), sin(ang)) * speed * randf_range(0.3, 1.0) # Define a velocidade e direção
		p.life = life * randf_range(0.6, 1.0) # Define uma duração aleatória
		p.max_life = p.life # Guarda a duração máxima
		p.size = randf_range(3.0, 7.0) # Define um tamanho aleatório
		p.color = color # Define a cor
		p.gravity = gravity # Define a gravidade
		particles.append(p) # Adiciona a partícula à lista

func _update_effects(delta: float) -> void:
	# Atualiza as partículas
	for i in range(particles.size() - 1, -1, -1): # Percorre as partículas de trás para frente
		var p: Particle = particles[i] # Obtém a partícula atual
		p.life -= delta # Reduz o tempo de vida
		if p.life <= 0.0: # Verifica se a partícula acabou
			particles.remove_at(i) # Remove a partícula
			continue # Passa para a próxima
		p.vel.y += p.gravity * delta # Aplica a gravidade
		p.pos += p.vel * delta # Atualiza a posição
		if alive: # Verifica se o jogador ainda está vivo
			p.pos.x -= scroll_speed * delta * 0.6 # Faz a partícula ficar para trás com o cenário

	# Atualiza os anéis de onda de choque
	for i in range(rings.size() - 1, -1, -1): # Percorre os anéis de trás para frente
		rings[i] += delta / 0.6 # Aumenta o progresso do anel
		if rings[i] >= 1.0: # Verifica se o anel terminou
			rings.remove_at(i) # Remove o anel

	if not alive: # Verifica se o jogador está morto
		return # Não cria novos efeitos

	# AGUDOS controlam a quantidade de faíscas atrás do cubo
	spark_accum += (10.0 + 120.0 * spectrum.high) * delta # Acumula a quantidade de faíscas a gerar
	while spark_accum >= 1.0: # Verifica se existe uma nova faísca para gerar
		spark_accum -= 1.0 # Remove uma unidade do acumulador
		_spawn_spark() # Cria uma nova faísca

	# RASTRO tem comprimento baseado na energia total da música
	for i in trail.size(): # Percorre os pontos do rastro
		var t := trail[i] # Obtém o ponto atual
		t.x -= scroll_speed * delta # Move o ponto para a esquerda
		trail[i] = t # Salva a nova posição
	trail_timer += delta # Atualiza o temporizador do rastro
	if trail_timer >= 0.02: # Verifica se é hora de adicionar um novo ponto
		trail_timer = 0.0 # Reinicia o temporizador
		trail.append(Vector2(px, foot_y)) # Adiciona a posição atual do jogador
	var max_len := int(8.0 + 28.0 * spectrum.total) # Calcula o comprimento máximo do rastro
	while trail.size() > max_len: # Verifica se o rastro ficou grande demais
		trail.pop_front() # Remove o ponto mais antigo

func _spawn_spark() -> void:
	if particles.size() >= MAX_PARTICLES: # Verifica se atingiu o limite de partículas
		return # Interrompe a criação
	var p := Particle.new() # Cria uma nova partícula
	p.pos = Vector2(px - CUBE * 0.5, foot_y - randf() * CUBE) # Define uma posição atrás do jogador
	p.vel = Vector2(-randf_range(60.0, 220.0), randf_range(-140.0, 40.0)) # Define a velocidade da faísca
	p.life = randf_range(0.3, 0.6) # Define o tempo de vida
	p.max_life = p.life # Guarda o tempo de vida máximo
	p.size = randf_range(2.0, 5.0) # Define o tamanho
	p.color = Color.from_hsv(fmod(hue_base + 0.5, 1.0), 0.7, 1.0) # Define a cor com base no matiz atual
	p.gravity = 200.0 # Define a gravidade
	particles.append(p) # Adiciona a partícula à lista

# Parallax dos prédios com janelas que reagem à música
func _init_buildings() -> void:
	buildings.clear() # Remove todos os prédios existentes
	for layer in 3: # Percorre as três camadas de parallax
		_fill_layer(layer) # Preenche cada camada com prédios

# Garante prédios suficientes à direita da tela em cada camada
func _fill_layer(layer: int) -> void:
	var right := -50.0 # Define a posição inicial do limite direito
	for b in buildings: # Percorre os prédios existentes
		if b.layer == layer: # Verifica se pertence à camada atual
			right = maxf(right, b.x + b.w) # Atualiza a posição do último prédio
	while right < view.x + 150.0: # Continua criando prédios até preencher a tela
		_spawn_building(layer, right + randf_range(4.0, 30.0)) # Cria um novo prédio
		var last: Building = buildings[buildings.size() - 1] # Obtém o prédio criado
		right = last.x + last.w # Atualiza o limite direito

func _spawn_building(layer: int, x: float) -> void:
	var rw: Vector2 = LAYER_W[layer] # Obtém os limites de largura da camada
	var rh: Vector2 = LAYER_H[layer] # Obtém os limites de altura da camada
	var cell: Vector2 = LAYER_CELL[layer] # Obtém o tamanho das células de janela
	var b := Building.new() # Cria um novo prédio
	b.layer = layer # Define a camada
	b.x = x # Define a posição horizontal
	b.w = randf_range(rw.x, rw.y) # Gera uma largura aleatória
	b.h = randf_range(rh.x, rh.y) * view.y # Gera uma altura proporcional à tela
	b.uid = randi() % 100000 # Gera um identificador aleatório
	b.hue_off = randf_range(-0.08, 0.08) # Define uma pequena variação de cor
	b.cols = maxi(1, int((b.w - 14.0) / cell.x)) # Calcula a quantidade de colunas de janelas
	b.rows = maxi(1, int((b.h - 14.0) / cell.y)) # Calcula a quantidade de linhas de janelas
	var n := b.cols * b.rows # Calcula o total de janelas
	b.glow.resize(n) # Reserva espaço para o brilho das janelas
	b.th.resize(n) # Reserva espaço para os limiares
	b.win_hue.resize(n) # Reserva espaço para as cores
	for i in n: # Percorre todas as janelas
		b.th[i] = randf() # Define um limiar aleatório para a janela
		b.win_hue[i] = randf() * 0.5 # Define uma cor aleatória para a janela
	buildings.append(b) # Adiciona o prédio à lista

func _update_buildings(delta: float) -> void:
	for i in range(buildings.size() - 1, -1, -1): # Percorre os prédios de trás para frente
		var b: Building = buildings[i] # Obtém o prédio atual
		var f: float = LAYER_SPEED[b.layer] # Obtém a velocidade da camada
		b.x -= scroll_speed * f * delta # Move o prédio conforme o parallax
		if b.x + b.w < -20.0: # Verifica se saiu da tela
			buildings.remove_at(i) # Remove o prédio
	for layer in 3: # Percorre as três camadas
		_fill_layer(layer) # Garante que cada camada continue preenchida

# Normaliza cada faixa usando seu piso e teto recentes e atualiza o brilho das janelas
func _update_windows(delta: float) -> void:
	var raw := [spectrum.high, spectrum.mid, spectrum.bass] # Obtém os valores de agudos, médios e graves
	var follow := 1.0 - exp(-0.3 * delta) # Define a velocidade de acompanhamento dos limites
	for l in 3: # Percorre as três faixas
		var v: float = raw[l] # Obtém o valor atual da faixa
		win_hi[l] = maxf(v, lerpf(win_hi[l], v, follow)) # Atualiza o teto recente
		win_lo[l] = minf(v, lerpf(win_lo[l], v, follow)) # Atualiza o piso recente
		var span := maxf(win_hi[l] - win_lo[l], 0.15) # Calcula a amplitude entre piso e teto
		win_norm[l] = clampf((v - win_lo[l]) / span, 0.0, 1.0) # Normaliza o valor entre 0 e 1

	var a_up := 1.0 - exp(-30.0 * delta) # Define a velocidade para acender
	var a_down := 1.0 - exp(-5.0 * delta) # Define a velocidade para apagar
	for b in buildings: # Percorre os prédios
		var norm: float = win_norm[b.layer] # Obtém a intensidade normalizada da camada
		for i in b.glow.size(): # Percorre as janelas
			var target := clampf((norm - b.th[i]) * 6.0, 0.0, 1.0) # Calcula o brilho desejado
			var g: float = b.glow[i] # Obtém o brilho atual
			b.glow[i] = lerpf(g, target, a_up if target > g else a_down) # Suaviza a mudança do brilho

# Faz algumas janelas acenderem e mudarem de cor durante uma batida
func _beat_windows(strength: float) -> void:
	var chance := 0.15 + 0.3 * strength # Calcula a chance de uma janela reagir
	for b in buildings: # Percorre os prédios
		var layer_factor := 0.5 + 0.25 * b.layer # Define um fator baseado na camada
		for i in b.glow.size(): # Percorre as janelas
			if randf() < chance * layer_factor: # Verifica se a janela deve reagir
				b.glow[i] = 1.0 # Acende a janela
				b.win_hue[i] = randf() * 0.5 # Define uma nova cor

func _draw_buildings() -> void:
	# Cada camada reage a uma faixa diferente do espectro
	for layer in 3: # Percorre as três camadas
		var cell: Vector2 = LAYER_CELL[layer] # Obtém o tamanho das células
		var body := Color.from_hsv(fmod(hue_base + 0.05 * layer, 1.0), 0.55, 0.11 - 0.035 * layer + 0.03 * beat_flash) # Define a cor dos prédios
		var unlit := body.lightened(0.15) # Define a cor das janelas apagadas
		for b in buildings: # Percorre todos os prédios
			if b.layer != layer: # Verifica se o prédio pertence à camada
				continue # Ignora prédios de outras camadas
			var top := ground_y - b.h # Calcula o topo do prédio
			draw_rect(Rect2(b.x, top, b.w, b.h + 2.0), body) # Desenha o corpo do prédio
			var ox := b.x + (b.w - b.cols * cell.x) * 0.5 # Calcula a posição inicial das janelas
			var oy := top + 10.0 # Define a posição vertical inicial das janelas
			for r in b.rows: # Percorre as linhas de janelas
				for c in b.cols: # Percorre as colunas de janelas
					var idx := r * b.cols + c # Calcula o índice da janela
					var g: float = b.glow[idx] # Obtém o brilho da janela
					var win := Rect2(ox + c * cell.x + cell.x * 0.2, oy + r * cell.y + cell.y * 0.2, # Define a posição da janela
						cell.x * 0.6, cell.y * 0.55) # Define o tamanho da janela
					if g < 0.03: # Verifica se a janela está praticamente apagada
						draw_rect(win, unlit) # Desenha a janela apagada
					else: # Caso esteja acesa
						var lit := Color.from_hsv(fmod(hue_base + b.win_hue[idx], 1.0), 0.5, 1.0) # Calcula a cor da janela
						draw_rect(win, unlit.lerp(lit, g)) # Desenha a janela misturando as cores

# Funções de easing
func ease_in_cubic(t: float) -> float:
	return t * t * t # Aplica uma curva cúbica de aceleração

func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0) # Aplica uma curva cúbica de desaceleração

func ease_out_back(t: float) -> float:
	var c1 := 1.70158 # Define o primeiro parâmetro da curva
	var c3 := c1 + 1.0 # Calcula o segundo parâmetro da curva
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0) # Calcula o valor da curva

# Desenho
func _draw() -> void:
	_draw_background() # Desenha o fundo
	_draw_buildings() # Desenha os prédios
	_draw_rings() # Desenha os anéis
	_draw_ground() # Desenha o chão
	_draw_obstacles() # Desenha os obstáculos
	_draw_trail() # Desenha o rastro
	_draw_particles() # Desenha as partículas
	if alive: # Verifica se o jogador está vivo
		_draw_player() # Desenha o jogador

	_draw_bars() # Desenha as barras do equalizador
	_draw_hud() # Desenha a interface

func _draw_background() -> void:
	# A cor do fundo reage aos agudos e à energia total
	var h := fmod(hue_base + 0.25 * spectrum.high, 1.0) # Calcula o matiz do fundo
	var v := 0.10 + 0.12 * spectrum.total + 0.12 * beat_flash # Calcula o brilho do fundo
	draw_rect(Rect2(-40.0, -40.0, view.x + 80.0, view.y + 80.0), Color.from_hsv(h, 0.65, v)) # Desenha o fundo

	# O sol reage principalmente aos graves
	var sun_c := Vector2(view.x * 0.62, ground_y - 90.0) # Define a posição do sol
	var r := 120.0 + 160.0 * spectrum.bass # Define o raio com base nos graves
	var sun_h := fmod(h + 0.12, 1.0) # Define uma variação do matiz
	draw_circle(sun_c, r, Color.from_hsv(sun_h, 0.6, 0.9, 0.12 + 0.10 * spectrum.bass)) # Desenha o brilho externo
	draw_circle(sun_c, r * 0.6, Color.from_hsv(sun_h, 0.5, 1.0, 0.15)) # Desenha o núcleo do sol

func _draw_rings() -> void:
	var center := Vector2(px, foot_y - CUBE * 0.5) # Define o centro dos anéis
	for t in rings: # Percorre todos os anéis
		var e := ease_out_cubic(t) # Calcula o progresso com easing
		var col := Color.from_hsv(fmod(hue_base + 0.1, 1.0), 0.5, 1.0, 0.5 * (1.0 - t)) # Define a cor e transparência
		draw_arc(center, 40.0 + 520.0 * e, 0.0, TAU, 64, col, 1.0 + 4.0 * (1.0 - t), true) # Desenha o anel expandindo

func _draw_ground() -> void:
	# O brilho do chão reage aos graves
	var col := Color.from_hsv(fmod(hue_base + 0.5, 1.0), 0.5, 0.30 + 0.45 * spectrum.bass) # Define a cor do chão
	var line_col := col.lightened(0.5) # Define a cor da borda do chão

	var holes: Array[Obstacle] = [] # Cria uma lista apenas com os buracos
	for o in obstacles: # Percorre os obstáculos
		if o.kind == Kind.HOLE: # Verifica se é um buraco
			holes.append(o) # Adiciona o buraco à lista
	holes.sort_custom(func(a, b): return a.x < b.x) # Ordena os buracos pela posição horizontal

	var cursor := -40.0 # Define o início do primeiro segmento
	for hole in holes: # Percorre os buracos ordenados
		_ground_segment(cursor, hole.x, col, line_col) # Desenha o chão antes do buraco
		cursor = maxf(cursor, hole.x + hole.w) # Move o cursor para depois do buraco
	_ground_segment(cursor, view.x + 40.0, col, line_col) # Desenha o último segmento do chão

	# Cria marcas no chão para reforçar a sensação de velocidade
	var tick := 90.0 # Define a distância entre as marcas
	var x := -fposmod(world_x, tick) # Calcula a posição inicial considerando a rolagem
	while x < view.x + tick: # Continua enquanto houver espaço na tela
		if not _x_in_hole(x): # Verifica se a marca não está sobre um buraco
			draw_line(Vector2(x, ground_y + 10.0), Vector2(x, view.y), col.lightened(0.2), 2.0) # Desenha a marca
		x += tick # Avança para a próxima marca

func _ground_segment(x0: float, x1: float, col: Color, line_col: Color) -> void:
	if x1 <= x0: # Verifica se o segmento possui largura válida
		return # Interrompe caso não possua
	draw_rect(Rect2(x0, ground_y, x1 - x0, view.y - ground_y + 40.0), col) # Desenha o segmento do chão
	draw_rect(Rect2(x0, ground_y, x1 - x0, 5.0), line_col) # Desenha a borda superior

func _x_in_hole(x: float) -> bool:
	for o in obstacles: # Percorre os obstáculos
		if o.kind == Kind.HOLE and x >= o.x and x <= o.x + o.w: # Verifica se a posição está dentro de um buraco
			return true # Informa que está sobre um buraco
	return false # Informa que não está sobre um buraco

func _draw_obstacles() -> void:
	for o in obstacles: # Percorre os obstáculos
		# Agudos controlam o matiz, médios a transparência e graves o tamanho
		var col := Color.from_hsv(fmod(o.hue + 0.25 * spectrum.high, 1.0), 0.85, 0.75 + 0.25 * o.pulse) # Calcula a cor
		col.a = 0.6 + 0.4 * spectrum.mid # Define a transparência
		var outline := col.lightened(0.5) # Define a cor do contorno
		var sc := 1.0 + 0.22 * o.pulse + 0.10 * spectrum.bass # Define o fator de escala

		match o.kind:
			Kind.BLOCK: # Desenha um bloco
				var bw := o.w * (1.0 + 0.08 * o.pulse) # Calcula a largura considerando o pulso
				var bh := o.h * sc # Calcula a altura considerando a escala
				var rect := Rect2(o.x - (bw - o.w) * 0.5, ground_y - bh, bw, bh) # Define o retângulo
				draw_rect(rect, col) # Desenha o bloco
				draw_rect(rect, outline, false, 2.0) # Desenha o contorno
			Kind.SPIKE: # Desenha um espinho
				var sh := o.h * sc # Calcula a altura do espinho
				var pts := PackedVector2Array([ # Cria os pontos do triângulo
					Vector2(o.x, ground_y), # Ponto esquerdo
					Vector2(o.x + o.w * 0.5, ground_y - sh), # Ponto superior
					Vector2(o.x + o.w, ground_y)]) # Ponto direito
				draw_colored_polygon(pts, col) # Preenche o espinho
				draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), outline, 2.0) # Desenha o contorno
			Kind.HOLE: # Desenha um buraco
				# O brilho interno e as bordas reagem à batida
				draw_rect(Rect2(o.x, ground_y, o.w, view.y - ground_y + 40.0), # Define a área interna
					Color(col, 0.10 + 0.25 * o.pulse)) # Define a transparência
				draw_line(Vector2(o.x, ground_y), Vector2(o.x, view.y), col, 3.0) # Desenha a borda esquerda
				draw_line(Vector2(o.x + o.w, ground_y), Vector2(o.x + o.w, view.y), col, 3.0) # Desenha a borda direita
			Kind.FLOATER: # Desenha um floater
				var c := _obstacle_center(o) # Obtém o centro do floater
				var r := o.w * 0.55 * sc # Calcula o tamanho do diamante
				var diamond := PackedVector2Array([ # Cria os quatro pontos do diamante
					c + Vector2(0.0, -r), c + Vector2(r, 0.0), # Pontos superior e direito
					c + Vector2(0.0, r), c + Vector2(-r, 0.0)]) # Pontos inferior e esquerdo
				draw_colored_polygon(diamond, col) # Preenche o diamante
				draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline, 2.0) # Desenha o contorno

func _draw_trail() -> void:
	var n := trail.size() # Obtém a quantidade de pontos do rastro
	for i in n: # Percorre todos os pontos
		var t := float(i + 1) / n # Calcula o progresso do ponto no rastro
		var col := Color.from_hsv(fmod(hue_base + 0.15 + 0.3 * (1.0 - t), 1.0), 0.6, 1.0, t * 0.5) # Define a cor e transparência
		var s := CUBE * (0.25 + 0.65 * t) # Define o tamanho do ponto
		draw_rect(Rect2(trail[i].x - s * 0.5, trail[i].y - CUBE * 0.5 - s * 0.5, s, s), col) # Desenha o ponto

func _draw_particles() -> void:
	for p in particles: # Percorre todas as partículas
		var col := p.color # Obtém a cor da partícula
		col.a = p.life / p.max_life # Calcula a transparência com base na vida restante
		draw_rect(Rect2(p.pos - Vector2.ONE * p.size * 0.5, Vector2.ONE * p.size), col) # Desenha a partícula

func _draw_player() -> void:
	var center := Vector2(px, foot_y - CUBE * 0.5) # Calcula o centro do jogador
	var s := CUBE * (1.0 + 0.12 * beat_flash) # Faz o cubo aumentar durante a batida
	# O halo reage à energia total da música
	draw_circle(center, CUBE * (0.9 + 0.8 * spectrum.total), Color(1, 1, 1, 0.06 + 0.10 * spectrum.total)) # Desenha o halo

	draw_set_transform(center, spin, Vector2.ONE) # Aplica a posição e rotação do jogador
	draw_rect(Rect2(-s * 0.5, -s * 0.5, s, s), Color.WHITE) # Desenha o corpo branco
	draw_rect(Rect2(-s * 0.5, -s * 0.5, s, s), Color.from_hsv(hue_base, 0.8, 1.0), false, 4.0) # Desenha o contorno colorido
	draw_rect(Rect2(s * 0.12, -s * 0.25, s * 0.18, s * 0.18), Color.BLACK) # Desenha o olho
	draw_set_transform(Vector2.ZERO) # Restaura a transformação padrão

func _draw_bars() -> void:
	var n := Spectrum.BAR_COUNT # Obtém a quantidade de barras
	var gap := 4.0 # Define o espaço entre as barras
	var bw := (view.x - gap * (n + 1)) / n # Calcula a largura de cada barra
	var max_h := 90.0 # Define a altura máxima das barras
	for i in n: # Percorre todas as barras
		var v := spectrum.bars[i] # Obtém o valor da barra atual
		var bar_h := maxf(3.0, v * max_h) # Calcula a altura da barra
		var col := Color.from_hsv(fmod(hue_base + 0.6 * float(i) / n, 1.0), 0.7, 1.0, 0.9) # Define a cor da barra
		draw_rect(Rect2(gap + i * (bw + gap), 8.0, bw, bar_h), col) # Desenha a barra

func _draw_hud() -> void:
	var font := ThemeDB.fallback_font # Obtém a fonte padrão da interface
	var shown_best := maxi(best, int(score)) # Obtém o maior valor entre recorde e pontuação atual
	draw_string(font, Vector2(24.0, 140.0), "PONTOS  %d" % int(score), # Exibe a pontuação atual
		HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE) # Define alinhamento, tamanho e cor
	draw_string(font, Vector2(0.0, 140.0), "RECORDE  %d" % shown_best, # Exibe o recorde
		HORIZONTAL_ALIGNMENT_RIGHT, view.x - 24.0, 32, Color.WHITE) # Define alinhamento, tamanho e cor
	var track_name: String = String(tracks[track_index]["path"]).get_file() # Obtém apenas o nome do arquivo da música
	draw_string(font, Vector2(24.0, 170.0), "Música: " + track_name, # Exibe o nome da música
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.8)) # Define alinhamento, tamanho e transparência
	draw_string(font, Vector2(0.0, view.y - 18.0), # Define a posição da mensagem de controles
		"ESPAÇO / SETA PRA CIMA / CLIQUE ESQUERDO = pular      M / CLIQUE DIREITO = trocar música      F1 = debug", # Define o texto dos controles
		HORIZONTAL_ALIGNMENT_CENTER, view.x, 18, Color(1, 1, 1, 0.7)) # Centraliza o texto

	if not alive: # Verifica se o jogador está morto
		draw_string(font, Vector2(0.0, view.y * 0.38), "BATEU!", # Exibe a mensagem de derrota
			HORIZONTAL_ALIGNMENT_CENTER, view.x, 72, Color.WHITE) # Centraliza e define o tamanho

	if show_debug: # Verifica se o modo debug está ativo
		var lines := [ # Cria as linhas de informações de debug
			"graves %.2f (cru %.2f)" % [spectrum.bass, spectrum.bass_raw], # Exibe os valores dos graves
			"médios %.2f (cru %.2f)" % [spectrum.mid, spectrum.mid_raw], # Exibe os valores dos médios
			"agudos %.2f (cru %.2f)" % [spectrum.high, spectrum.high_raw], # Exibe os valores dos agudos
			"detector (B troca): %s" % ["NÍVEL", "FLUXO", "GRADE BPM"][spectrum.beat_mode], # Exibe o método de detecção atual
			"BPM %.0f offset %.3fs (T sincroniza, , e . ajustam)" % [float(tracks[track_index]["bpm"]), float(tracks[track_index]["offset"])], # Exibe BPM e offset
			"fluxo graves %.2f limiar  %.2f" % [spectrum.flux_hold, spectrum.beat_threshold_now], # Exibe fluxo e limiar
			"tempo estimado %.0f BPM" % spectrum.bpm_est, # Exibe o BPM estimado pelo detector
			"velocidade %.0f px/s" % scroll_speed, # Exibe a velocidade atual
			"obstáculos %d partículas %d" % [obstacles.size(), particles.size()], # Exibe a quantidade de obstáculos e partículas
		]
		for i in lines.size(): # Percorre todas as linhas de debug
			draw_string(font, Vector2(24.0, 190.0 + 26.0 * i), lines[i], # Desenha a linha atual
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 0.6)) # Define alinhamento, tamanho e cor
		if beat_flash > 0.6: # Verifica se ocorreu uma batida recentemente
			draw_string(font, Vector2(24.0, 190.0 + 26.0 * lines.size()), "BEAT!", # Exibe o indicador de batida
				HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.4, 0.4)) # Define alinhamento, tamanho e cor
