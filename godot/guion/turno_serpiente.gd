## Reglas deterministas del arcade. No conoce campaña, UI ni disco.
class_name TurnoSerpiente
extends RefCounted

const TAMANO := Vector2i(20, 14)
const META := 6
const NIVELES := 3

var cuerpo: Array[Vector2i] = []
var paredes: Array[Vector2i] = []
var direccion := Vector2i.RIGHT
var pendiente := Vector2i.RIGHT
var sello := Vector2i.ZERO
var nivel := 1
var recogidos := 0
var puntos := 0
var fase := "preparado"
var _semilla := 98
var _giro_pendiente := false


func nueva(semilla: int = 98) -> void:
	_semilla = posmod(semilla, 65536)
	nivel = 1
	puntos = 0
	_preparar_nivel()


func iniciar() -> void:
	if fase == "preparado":
		fase = "jugando"


func girar(valor: Vector2i) -> bool:
	# Solo un giro por tick: dos eventos rápidos nunca invierten la cabeza.
	if fase != "jugando" or _giro_pendiente or absi(valor.x) + absi(valor.y) != 1:
		return false
	if valor == -direccion or valor == direccion:
		return false
	pendiente = valor
	_giro_pendiente = true
	return true


func pausar() -> void:
	if fase == "jugando":
		fase = "pausa"
	elif fase == "pausa":
		fase = "jugando"


func avanzar() -> String:
	if fase != "jugando":
		return "quieto"
	direccion = pendiente
	_giro_pendiente = false
	var cabeza := cuerpo[0] + direccion
	var come := cabeza == sello
	var ocupado := cuerpo.duplicate()
	if not come:
		ocupado.pop_back()
	if not Rect2i(Vector2i.ZERO, TAMANO).has_point(cabeza):
		fase = "derrota"
		return "choque"
	if paredes.has(cabeza) or ocupado.has(cabeza):
		fase = "derrota"
		return "choque"
	cuerpo.push_front(cabeza)
	if not come:
		cuerpo.pop_back()
		return "paso"
	recogidos += 1
	puntos += 100 * nivel
	if recogidos >= META:
		fase = "victoria" if nivel == NIVELES else "nivel_completo"
		return "nivel"
	_colocar_sello()
	return "sello"


func siguiente() -> bool:
	if fase != "nivel_completo":
		return false
	nivel += 1
	_preparar_nivel()
	return true


func intervalo(lento: bool = false) -> float:
	return (0.25 - 0.035 * (nivel - 1)) * (1.45 if lento else 1.0)


func _preparar_nivel() -> void:
	cuerpo.assign([Vector2i(5, 7), Vector2i(4, 7), Vector2i(3, 7)])
	direccion = Vector2i.RIGHT
	pendiente = direccion
	_giro_pendiente = false
	recogidos = 0
	paredes.clear()
	if nivel >= 2:
		for y in [3, 4, 9, 10]:
			paredes.append(Vector2i(10, y))
	if nivel >= 3:
		for x in range(4, 8):
			paredes.append(Vector2i(x, 3))
			paredes.append(Vector2i(19 - x, 10))
	fase = "preparado"
	_colocar_sello()


func _colocar_sello() -> void:
	var libres: Array[Vector2i] = []
	for y in range(TAMANO.y):
		for x in range(TAMANO.x):
			var celda := Vector2i(x, y)
			if not cuerpo.has(celda) and not paredes.has(celda):
				libres.append(celda)
	if libres.is_empty():
		fase = "victoria"
		return
	# LCG pequeño, independiente del RNG global y sin bucles de rechazo.
	_semilla = (_semilla * 25173 + 13849) % 65536
	sello = libres[_semilla % libres.size()]
