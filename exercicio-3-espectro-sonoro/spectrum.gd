class_name Spectrum
extends Node

## Lê o espectro de uma bus de áudio e entrega valores normalizados (0..1):
## graves, médios, agudos, energia total, 32 barras e um sinal de batida (beat).

signal beat(strength: float) # Sinal emitido quando uma batida é detectada

const MIN_DB := 60.0 # Piso de -60 dB; sons abaixo disso viram 0
const BAR_COUNT := 32 # Quantidade de barras do equalizador
const BAR_FREQ_MIN := 40.0 # Frequência mínima das barras, em Hz
const BAR_FREQ_MAX := 12000.0 # Frequência máxima das barras, em Hz

# Faixas de frequência utilizadas pelo jogo
const BASS_RANGE := Vector2(20.0, 150.0) # Faixa dos graves, em Hz
const MID_RANGE := Vector2(150.0, 2000.0) # Faixa dos médios, em Hz
const HIGH_RANGE := Vector2(2000.0, 10000.0) # Faixa dos agudos, em Hz

# Ganho aplicado a cada faixa para compensar diferenças naturais de intensidade
const BASS_GAIN := 1.0 # Ganho dos graves
const MID_GAIN := 1.3 # Ganho dos médios
const HIGH_GAIN := 2.0 # Ganho dos agudos

# Sub-faixas utilizadas para detectar ataques nos graves
const FLUX_BANDS := [
	Vector2(30.0, 55.0), 
	Vector2(55.0, 80.0),
	Vector2(80.0, 110.0),
	Vector2(110.0, 150.0),
	Vector2(150.0, 220.0)
]

# Configurações do detector de batidas
var beat_sensitivity := 1.8 # Multiplicador da média para definir o limiar
var beat_peak_ratio := 0.45 # Fração mínima do maior ataque recente
var beat_min_flux := 0.5 # Fluxo mínimo absoluto para detectar uma batida
var beat_cooldown := 0.25 # Tempo mínimo entre batidas, em segundos
var fill_missed_beats := false # Gera batidas artificiais quando uma é perdida

# Define o método de detecção: 0 = nível, 1 = fluxo espectral, 2 = grade de BPM
var beat_mode := 1 # Método de detecção atualmente utilizado
var level_threshold := 0.07 # Diferença mínima entre grave e média no modo 0
var level_min := 0.25 # Nível mínimo dos graves no modo 0
var level_cooldown := 0.22 # Tempo mínimo entre batidas no modo 0

# Valores utilizados para debug
var flux := 0.0 # Fluxo espectral atual
var flux_hold := 0.0 # Fluxo mantido temporariamente para facilitar o debug
var beat_threshold_now := 0.0 # Limiar atual necessário para detectar uma batida
var bpm_est := 0.0 # BPM estimado a partir dos intervalos entre batidas

# Valores suavizados utilizados nas animações
var bass := 0.0 # Intensidade dos graves
var mid := 0.0 # Intensidade dos médios
var high := 0.0 # Intensidade dos agudos
var total := 0.0 # Energia total ponderada
var bars := PackedFloat32Array() # Valores das 32 barras do equalizador

# Valores crus, sem suavização, utilizados principalmente no debug
var bass_raw := 0.0 # Intensidade dos graves
var mid_raw := 0.0 # Intensidade dos médios
var high_raw := 0.0 # Intensidade dos agudos

var _analyzer: AudioEffectSpectrumAnalyzerInstance # Instância usada para ler o espectro
var _prev_bands := PackedFloat32Array() # Energia anterior de cada sub-faixa
var _bass_avg := 0.0 # Média recente da intensidade dos graves
var _prev_bass := 0.0 # Intensidade dos graves no frame anterior
var _flux_avg := 0.0 # Média recente do fluxo espectral
var _flux_peak := 0.0 # Maior fluxo espectral recente
var _time := 0.0 # Tempo acumulado desde o início da análise
var _last_beat_time := -10.0 # Momento da última batida detectada
var _intervals: Array[float] = [] # Intervalos recentes entre batidas
var _period := 0.0 # Intervalo típico entre batidas, calculado pela mediana
var _synthetic_streak := 0 # Quantidade de batidas artificiais consecutivas

func _init() -> void:
	bars.resize(BAR_COUNT) # Reserva espaço para as 32 barras
	_prev_bands.resize(FLUX_BANDS.size()) # Reserva espaço para cada sub-faixa

## Adiciona o SpectrumAnalyzer à bus informada e guarda sua instância
func setup(bus_name: String) -> void:
	var bus := AudioServer.get_bus_index(bus_name) # Obtém o índice da bus pelo nome
	var fx := AudioEffectSpectrumAnalyzer.new() # Cria um novo analisador de espectro
	fx.buffer_length = 0.1 # Define o tamanho do buffer de análise
	fx.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048 # Define o tamanho da FFT
	AudioServer.add_bus_effect(bus, fx) # Adiciona o analisador à bus
	var fx_index := AudioServer.get_bus_effect_count(bus) - 1 # Obtém o índice do efeito adicionado
	_analyzer = AudioServer.get_bus_effect_instance(bus, fx_index) as AudioEffectSpectrumAnalyzerInstance # Obtém a instância do analisador

func _process(delta: float) -> void:
	if _analyzer == null: # Verifica se o analisador foi configurado
		return

	# 1) Obtém a energia das três principais faixas de frequência
	bass_raw = clampf(_energy(BASS_RANGE.x, BASS_RANGE.y) * BASS_GAIN, 0.0, 1.0)
	mid_raw = clampf(_energy(MID_RANGE.x, MID_RANGE.y) * MID_GAIN, 0.0, 1.0)
	high_raw = clampf(_energy(HIGH_RANGE.x, HIGH_RANGE.y) * HIGH_GAIN, 0.0, 1.0)

	# 2) Suaviza os valores para as animações
	bass = _smooth(bass, bass_raw, delta) 
	mid = _smooth(mid, mid_raw, delta)
	high = _smooth(high, high_raw, delta)
	total = bass * 0.5 + mid * 0.3 + high * 0.2 # Calcula a energia total dando mais peso aos graves

	# 3) Atualiza as 32 barras do equalizador usando espaçamento logarítmico
	var ratio := BAR_FREQ_MAX / BAR_FREQ_MIN # Calcula a proporção entre as frequências mínima e máxima

	for i in BAR_COUNT:
		var t0 := float(i) / BAR_COUNT # Calcula a posição inicial da barra
		var t1 := float(i + 1) / BAR_COUNT # Calcula a posição final da barra
		var f0 := BAR_FREQ_MIN * pow(ratio, t0) # Calcula a frequência inicial da barra
		var f1 := maxf(BAR_FREQ_MIN * pow(ratio, t1), f0 + 30.0) # Calcula a frequência final da barra
		var tilt := lerpf(1.0, 1.7, t0) # Aumenta o ganho das frequências mais altas
		var raw := clampf(_energy(f0, f1) * tilt, 0.0, 1.0) # Obtém e limita a energia da barra
		bars[i] = _smooth(bars[i], raw, delta) # Suaviza o movimento da barra

	# 4) Executa a detecção de batidas
	_detect_beat(delta) # Analisa o áudio para identificar uma nova batida

## Obtém a energia entre duas frequências e converte o resultado para 0..1
func _energy(f_from: float, f_to: float) -> float:
	var m: Vector2 = _analyzer.get_magnitude_for_frequency_range( # Obtém a magnitude da faixa de frequência
		f_from, # Frequência inicial
		f_to, # Frequência final
		AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX # Utiliza a magnitude máxima encontrada
	)
	var mag := (m.x + m.y) * 0.5 # Calcula a magnitude média dos dois canais
	return clampf((MIN_DB + linear_to_db(mag)) / MIN_DB, 0.0, 1.0) # Converte de dB para uma escala de 0 a 1

# Suaviza os valores, fazendo-os subir rapidamente e descer mais lentamente
func _smooth(current: float, target: float, delta: float) -> float:
	var k := 28.0 if target > current else 7.0 # Usa uma velocidade maior ao subir do que ao descer
	return lerpf(current, target, 1.0 - exp(-k * delta)) # Interpola suavemente até o valor desejado

## Detecta batidas através de aumentos repentinos na energia dos graves
## O fluxo espectral soma os aumentos de energia das sub-faixas entre frames
func _detect_beat(delta: float) -> void:
	_time += delta # Atualiza o tempo acumulado

	# 1) Calcula o fluxo espectral dos graves
	flux = 0.0 # Reinicia o fluxo do frame atual

	for i in FLUX_BANDS.size():
		var r: Vector2 = FLUX_BANDS[i] # Obtém a faixa de frequência atual
		var e := _energy(r.x, r.y) # Obtém a energia atual da sub-faixa
		flux += maxf(0.0, e - _prev_bands[i]) # Soma somente os aumentos de energia
		_prev_bands[i] = e # Guarda a energia atual para o próximo frame

	# 2) Calcula um limiar adaptativo para a detecção
	_flux_peak = maxf(flux, _flux_peak * exp(-0.5 * delta)) # Mantém o maior ataque recente com decaimento
	flux_hold = maxf(flux, flux_hold * exp(-3.0 * delta)) # Mantém temporariamente o fluxo para debug
	beat_threshold_now = maxf(maxf(_flux_avg * beat_sensitivity, _flux_peak * beat_peak_ratio), beat_min_flux) # Define o limiar atual
	_flux_avg = lerpf(_flux_avg, flux, 1.0 - exp(-2.0 * delta)) # Atualiza a média recente do fluxo

	if beat_mode == 2:
		return # No modo 2, o main controla as batidas pela posição da música

	if beat_mode == 0:
		_detect_by_level(delta) # Executa o detector baseado no nível dos graves
		return # Encerra este método após utilizar o detector alternativo

	if _time < 0.5:
		return # Ignora os primeiros 0,5 segundos para criar um histórico

	# 3) Verifica se uma nova batida foi detectada
	var since := _time - _last_beat_time # Calcula o tempo desde a última batida

	if flux > beat_threshold_now and since >= beat_cooldown: # Verifica se o fluxo passou o limiar e respeitou o cooldown
		_synthetic_streak = 0 # Reinicia a contagem de batidas artificiais
		_register_beat(clampf(0.25 + (flux / beat_threshold_now - 1.0) * 0.5, 0.0, 1.0), false) # Registra a batida com intensidade proporcional ao ataque

	elif fill_missed_beats and _period > 0.0 and _synthetic_streak < 3 \
			and since > _period * 1.2 and since < 3.0 and bass > 0.3: # Verifica se uma batida esperada foi perdida
		_synthetic_streak += 1 # Aumenta a contagem de batidas artificiais
		_register_beat(0.4, true) # Registra uma batida artificial com intensidade fixa

## Detector alternativo: identifica um grave subindo acima da média recente
func _detect_by_level(delta: float) -> void:
	_bass_avg = lerpf(_bass_avg, bass_raw, 1.0 - exp(-1.5 * delta)) # Atualiza a média recente dos graves
	var rising := bass_raw >= _prev_bass # Verifica se o grave está aumentando
	_prev_bass = bass_raw # Guarda o grave atual para o próximo frame
	var since := _time - _last_beat_time # Calcula o tempo desde a última batida

	if since >= level_cooldown and rising and bass_raw > level_min and bass_raw - _bass_avg > level_threshold: # Verifica todas as condições da batida
		_register_beat(clampf((bass_raw - _bass_avg) * 3.0, 0.0, 1.0), false) # Registra a batida proporcionalmente ao aumento do grave

# Registra uma batida, atualiza o BPM e emite o sinal para outros sistemas
func _register_beat(strength: float, synthetic: bool) -> void:
	var interval := _time - _last_beat_time # Calcula o intervalo desde a última batida

	if not synthetic and interval > 0.25 and interval < 1.2: # Considera apenas batidas reais com intervalos plausíveis
		_intervals.append(interval) # Adiciona o intervalo ao histórico

		if _intervals.size() > 8:
			_intervals.pop_front() # Remove o intervalo mais antigo quando há mais de 8

		var sorted: Array = _intervals.duplicate() # Cria uma cópia dos intervalos
		sorted.sort() # Ordena os intervalos do menor para o maior
		_period = float(sorted[sorted.size() >> 1]) # Obtém a mediana dos intervalos
		bpm_est = 60.0 / _period # Converte o período entre batidas para BPM

	_last_beat_time = _time # Atualiza o momento da última batida
	beat.emit(strength) # Emite o sinal informando a intensidade da batida
