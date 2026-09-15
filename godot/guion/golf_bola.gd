## Simulación determinista de la bola del golf de pasillo (#158).
##
## Usa coordenadas locales 2D sobre el suelo del hoyo. No depende de nodos de
## física: la escena 3D solo necesita proyectar `posicion` a X/Z y dibujar la
## bola. El paso fijo, el rozamiento y el límite de pasos garantizan que un tiro
## termina incluso si la presentación pierde frames.
class_name GolfBola
extends RefCounted

const RADIO_BOLA := 0.02135
const PASO_FIJO := 1.0 / 120.0
const ROZAMIENTO := 0.9
const VELOCIDAD_MINIMA := 0.30
const VELOCIDAD_MAXIMA := 2.40
const VELOCIDAD_REPOSO := 0.025
const REBOTE_PARED := 0.68
const MAX_PASOS := 2400
const LIMITES_POR_DEFECTO := Rect2(-1.4, -2.4, 2.8, 4.8)


static func nueva(
	posicion: Vector2 = Vector2.ZERO,
	limites: Rect2 = LIMITES_POR_DEFECTO,
) -> Dictionary:
	if not _limites_validos(limites):
		limites = LIMITES_POR_DEFECTO
	return {
		"posicion": _encajar(posicion, limites),
		"velocidad": Vector2.ZERO,
		"limites": limites,
		"acumulador": 0.0,
		"pasos": 0,
		"detenida": true,
	}


## Inicia un tiro solo cuando la bola está quieta. `potencia` se expresa de 0 a
## 1 y se convierte a una velocidad acotada para que el controlador de entrada
## no pueda inyectar energía arbitraria.
static func golpear(estado: Dictionary, direccion: Vector2, potencia: float) -> Dictionary:
	if not detenida(estado):
		return estado
	if potencia <= 0.0 or direccion.length_squared() <= 0.000001:
		return estado

	var fuerza := clampf(potencia, 0.0, 1.0)
	var rapidez := lerpf(VELOCIDAD_MINIMA, VELOCIDAD_MAXIMA, fuerza)
	estado["velocidad"] = direccion.normalized() * rapidez
	estado["acumulador"] = 0.0
	estado["pasos"] = 0
	estado["detenida"] = false
	return estado


## Avanza usando un acumulador de paso fijo. Deliberadamente limita un delta
## individual grande: si la ventana queda bloqueada, la bola no atraviesa todo
## el hoyo en una sola iteración.
static func avanzar(estado: Dictionary, delta: float) -> Dictionary:
	if detenida(estado):
		return estado
	var acumulado := float(estado.get("acumulador", 0.0)) + clampf(delta, 0.0, 0.25)
	while acumulado >= PASO_FIJO and not detenida(estado):
		_paso_fijo(estado)
		acumulado -= PASO_FIJO
	estado["acumulador"] = acumulado
	return estado


## Útil para IA, pruebas y recuperación: ejecuta el mismo integrador que la
## escena hasta que el tiro termina. Nunca excede MAX_PASOS.
static func simular_hasta_detener(estado: Dictionary) -> Dictionary:
	while not detenida(estado) and int(estado.get("pasos", 0)) < MAX_PASOS:
		_paso_fijo(estado)
	if not detenida(estado):
		_forzar_reposo(estado)
	return estado


static func detenida(estado: Dictionary) -> bool:
	return bool(estado.get("detenida", true))


static func _paso_fijo(estado: Dictionary) -> void:
	var limites: Rect2 = estado.get("limites", LIMITES_POR_DEFECTO)
	if not _limites_validos(limites):
		limites = LIMITES_POR_DEFECTO
		estado["limites"] = limites

	var posicion: Vector2 = estado.get("posicion", Vector2.ZERO)
	var velocidad: Vector2 = estado.get("velocidad", Vector2.ZERO)
	posicion += velocidad * PASO_FIJO

	var min_x := limites.position.x + RADIO_BOLA
	var max_x := limites.end.x - RADIO_BOLA
	var min_y := limites.position.y + RADIO_BOLA
	var max_y := limites.end.y - RADIO_BOLA

	if posicion.x < min_x:
		posicion.x = min_x
		velocidad.x = absf(velocidad.x) * REBOTE_PARED
	elif posicion.x > max_x:
		posicion.x = max_x
		velocidad.x = -absf(velocidad.x) * REBOTE_PARED

	if posicion.y < min_y:
		posicion.y = min_y
		velocidad.y = absf(velocidad.y) * REBOTE_PARED
	elif posicion.y > max_y:
		posicion.y = max_y
		velocidad.y = -absf(velocidad.y) * REBOTE_PARED

	var rapidez := velocidad.length()
	var rapidez_nueva := maxf(rapidez - ROZAMIENTO * PASO_FIJO, 0.0)
	if rapidez_nueva <= VELOCIDAD_REPOSO:
		velocidad = Vector2.ZERO
	else:
		velocidad = velocidad.normalized() * rapidez_nueva

	estado["posicion"] = posicion
	estado["velocidad"] = velocidad
	estado["pasos"] = int(estado.get("pasos", 0)) + 1

	if velocidad == Vector2.ZERO or int(estado["pasos"]) >= MAX_PASOS:
		_forzar_reposo(estado)


static func _forzar_reposo(estado: Dictionary) -> void:
	estado["velocidad"] = Vector2.ZERO
	estado["acumulador"] = 0.0
	estado["detenida"] = true


static func _encajar(posicion: Vector2, limites: Rect2) -> Vector2:
	return Vector2(
		clampf(posicion.x, limites.position.x + RADIO_BOLA, limites.end.x - RADIO_BOLA),
		clampf(posicion.y, limites.position.y + RADIO_BOLA, limites.end.y - RADIO_BOLA),
	)


static func _limites_validos(limites: Rect2) -> bool:
	var diametro := RADIO_BOLA * 2.0
	return limites.size.x > diametro and limites.size.y > diametro
