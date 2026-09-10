class_name CurveUtils

# ---------- LINEAR ----------
# Equação: P(t) = P0 + (P1 - P0) * t

static func generate_linear(points: PackedVector2Array, steps: int) -> PackedVector2Array:
	var result: PackedVector2Array = []
	if points.size() < 2:
		return points
	for i in range(points.size() - 1):
		var p0 = points[i]
		var p1 = points[i + 1]
		for s in range(steps):
			var t = float(s) / float(steps)
			result.append(p0.lerp(p1, t))
	result.append(points[points.size() - 1])
	return result

# ---------- CATMULL-ROM ----------
# Forma matricial do slide 40. A curva "bruta" (sem padding) só passa
# pelos pontos do MEIO da janela de 4 pontos que desliza pela lista,
# ou seja, ela pula o primeiro e o último ponto reais, porque eles só
# aparecem como apoio de tangente (P0/P3) e nunca como P1/P2. Para a 
# curva passar por TODOS os pontos do editor, são adicionados 2 pontos
# "fantasmas" (um antes do primeiro e um depois do último) só para servirem
# de apoio de tangente nas pontas.

static func generate_catmull_rom(points: PackedVector2Array, steps: int) -> PackedVector2Array:
	var result: PackedVector2Array = []
	var n = points.size()
	if n < 2:
		return points
	var padded = _pad_endpoints(points)
	var m = padded.size()
	for i in range(m - 3):
		var p0 = padded[i]
		var p1 = padded[i + 1]
		var p2 = padded[i + 2]
		var p3 = padded[i + 3]
		for s in range(steps):
			var t = float(s) / float(steps)
			result.append(_catmull_rom_point(p0, p1, p2, p3, t))
	result.append(padded[m - 2])  # == points[n - 1], o último ponto REAL
	return result

# Extrapola um ponto antes do primeiro e depois do último,
# espelhando a direção do segmento vizinho.

static func _pad_endpoints(points: PackedVector2Array) -> PackedVector2Array:
	var padded: PackedVector2Array = []
	var n = points.size()

	var first_extra: Vector2
	var last_extra: Vector2

	if n >= 2:
		first_extra = points[0] + (points[0] - points[1])
		last_extra = points[n - 1] + (points[n - 1] - points[n - 2])
	else:
		first_extra = points[0]
		last_extra = points[0]

	padded.append(first_extra)
	for p in points:
		padded.append(p)
	padded.append(last_extra)
	return padded

static func _catmull_rom_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 = t * t
	var t3 = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)

# ---------- BÉZIER (De Casteljau) ----------
# Igual ao print do slide 32: para cada t, faz interpolações
# lineares sucessivas entre pontos vizinhos até sobrar 1 ponto só.
# Com N pontos de controle, isso gera UMA curva de grau N-1 que passa
# exatamente pelo primeiro e pelo último ponto. Todos os pontos do
# meio são só aproximados, nunca tocados.

static func generate_bezier(points: PackedVector2Array, steps: int) -> PackedVector2Array:
	var result: PackedVector2Array = []
	var n = points.size()
	if n < 2:
		return points
	for s in range(steps + 1):
		var t = float(s) / float(steps)
		result.append(_de_casteljau(points, t))
	return result

static func _de_casteljau(points: PackedVector2Array, t: float) -> Vector2:
	var temp: PackedVector2Array = points.duplicate()
	while temp.size() > 1:
		var next_level: PackedVector2Array = []
		for i in range(temp.size() - 1):
			next_level.append(temp[i].lerp(temp[i + 1], t))
		temp = next_level
	return temp[0]
