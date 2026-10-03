## Simulación acotada del arcade: una pelota, una pala y paquetes propios.
class_name RebotePostal
extends RefCounted

const TAMANO := Vector2(960, 600)
const RADIO := 8.0
const ANCHO_PALA := 140.0
const Y_PALA := 540.0
const PASO := 1.0 / 120.0
const MAPAS := [
	["111111", "111111", "111111"],
	["110011", "111111", "011110", "111111"],
	["101101", "111111", "110011", "111111", "011110"],
]

var paquetes: Array[Rect2] = []
var pelota := Vector2.ZERO
var velocidad := Vector2.ZERO
var pala := 480.0
var nivel := 1
var vidas := 3
var puntos := 0
var fase := "listo"
var tranquilo := false
var _acumulado := 0.0


func nueva() -> void:
	nivel = 1
	vidas = 3
	puntos = 0
	_preparar_nivel()


func mover(eje: float, delta: float) -> void:
	if fase not in ["listo", "jugando"]:
		return
	pala = clampf(
		pala + clampf(eje, -1.0, 1.0) * 650.0 * delta, ANCHO_PALA / 2, TAMANO.x - ANCHO_PALA / 2
	)
	if fase == "listo":
		pelota.x = pala


func sacar() -> bool:
	if fase != "listo":
		return false
	velocidad = Vector2(0.42, -1).normalized() * rapidez()
	fase = "jugando"
	return true


func pausar() -> void:
	if fase == "jugando":
		fase = "pausa"
	elif fase == "pausa":
		fase = "jugando"
	_acumulado = 0.0


func rapidez() -> float:
	return (330.0 + 60.0 * (nivel - 1)) * (0.75 if tranquilo else 1.0)


func avanzar(delta: float, eje: float = 0.0) -> Array[String]:
	var eventos: Array[String] = []
	if fase not in ["listo", "jugando"]:
		return eventos
	# Paso pequeño y velocidad máxima 450: menos de cuatro píxeles por tick.
	# El radio/alto de los colliders impiden atravesar bloques entre muestras.
	_acumulado += clampf(delta, 0.0, 0.1)
	while _acumulado >= PASO and fase in ["listo", "jugando"]:
		_acumulado -= PASO
		mover(eje, PASO)
		if fase == "jugando":
			var evento := _tick()
			if not evento.is_empty():
				eventos.append(evento)
	return eventos


func siguiente() -> bool:
	if fase != "nivel_completo":
		return false
	nivel += 1
	_preparar_nivel()
	return true


func _preparar_nivel() -> void:
	paquetes.clear()
	var mapa: Array = MAPAS[nivel - 1]
	for y in range(mapa.size()):
		for x in range(6):
			if mapa[y][x] == "1":
				paquetes.append(Rect2(70 + x * 140, 65 + y * 42, 120, 28))
	pala = TAMANO.x / 2
	_listo()


func _listo() -> void:
	fase = "listo"
	_acumulado = 0.0
	velocidad = Vector2.ZERO
	pelota = Vector2(pala, Y_PALA - RADIO - 8)


func _tick() -> String:
	var anterior := pelota
	pelota += velocidad * PASO
	if pelota.x < RADIO:
		pelota.x = RADIO
		velocidad.x = absf(velocidad.x)
	elif pelota.x > TAMANO.x - RADIO:
		pelota.x = TAMANO.x - RADIO
		velocidad.x = -absf(velocidad.x)
	if pelota.y < RADIO:
		pelota.y = RADIO
		velocidad.y = absf(velocidad.y)
	if pelota.y > TAMANO.y + RADIO:
		vidas -= 1
		if vidas == 0:
			fase = "derrota"
			_acumulado = 0.0
		else:
			_listo()
		return "perdida"
	if velocidad.y > 0 and anterior.y <= Y_PALA - RADIO and pelota.y >= Y_PALA - RADIO:
		if absf(pelota.x - pala) <= ANCHO_PALA / 2 + RADIO:
			pelota.y = Y_PALA - RADIO
			var desvio := clampf((pelota.x - pala) / (ANCHO_PALA / 2), -1.0, 1.0)
			# Un impacto centrado conserva salida lateral: nunca queda vertical para siempre.
			if absf(desvio) < 0.12:
				desvio = 0.12 if velocidad.x >= 0 else -0.12
			velocidad = Vector2(desvio * 0.85, -1).normalized() * rapidez()
			return "pala"
	for i in range(paquetes.size()):
		var superficie := paquetes[i].grow(RADIO)
		if not superficie.has_point(pelota):
			continue
		_rebotar(superficie, anterior)
		paquetes.remove_at(i)
		puntos += 100
		if paquetes.is_empty():
			fase = "victoria" if nivel == MAPAS.size() else "nivel_completo"
			_acumulado = 0.0
			return "nivel"
		return "paquete"
	return ""


func _rebotar(superficie: Rect2, anterior: Vector2) -> void:
	if anterior.y <= superficie.position.y:
		pelota.y = superficie.position.y
		velocidad.y = -absf(velocidad.y)
	elif anterior.y >= superficie.end.y:
		pelota.y = superficie.end.y
		velocidad.y = absf(velocidad.y)
	elif anterior.x <= superficie.position.x:
		pelota.x = superficie.position.x
		velocidad.x = -absf(velocidad.x)
	else:
		pelota.x = superficie.end.x
		velocidad.x = absf(velocidad.x)
