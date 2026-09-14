## Núcleo puro del golf de pasillo (#158).
##
## No conoce escenas, física ni Partida. Modela tres hoyos, turnos y tarjetas
## de golpes. La futura escena 3D solo tiene que decidir cuándo una bola entra
## en el hoyo y llamar a terminar_hoyo().
class_name Golf
extends RefCounted

const HOYOS := 3
const MAX_GOLPES_POR_HOYO := 12


static func nueva(jugadores: Array) -> Dictionary:
	var tarjetas := {}
	var golpes_hoyo := {}
	for jugador in jugadores:
		var nombre := String(jugador)
		tarjetas[nombre] = []
		golpes_hoyo[nombre] = 0
	return {
		"jugadores": jugadores.duplicate(),
		"hoyo": 0,
		"turno": 0,
		"tarjetas": tarjetas,
		"golpes_hoyo": golpes_hoyo,
		"terminada": jugadores.is_empty(),
		"abandonada": false,
	}


static func jugador_actual(estado: Dictionary) -> String:
	var jugadores: Array = estado.get("jugadores", [])
	if jugadores.is_empty() or estado.get("terminada", false):
		return ""
	var turno := clampi(int(estado.get("turno", 0)), 0, jugadores.size() - 1)
	return String(jugadores[turno])


static func golpear(estado: Dictionary, jugador: String, golpes_delta: int = 1) -> Dictionary:
	if not _puede_actuar(estado, jugador):
		return estado
	var incremento := maxi(golpes_delta, 1)
	var acumulados := int(estado["golpes_hoyo"].get(jugador, 0)) + incremento
	estado["golpes_hoyo"][jugador] = mini(acumulados, MAX_GOLPES_POR_HOYO)
	if int(estado["golpes_hoyo"][jugador]) >= MAX_GOLPES_POR_HOYO:
		return terminar_hoyo(estado, jugador)
	return estado


## Cierra el hoyo del jugador actual. Si alcanza el máximo de golpes también
## avanza, evitando turnos bloqueados por una bola irrecuperable.
static func terminar_hoyo(estado: Dictionary, jugador: String) -> Dictionary:
	if not _puede_actuar(estado, jugador):
		return estado
	var golpes := int(estado["golpes_hoyo"].get(jugador, 0))
	if golpes <= 0:
		return estado
	estado["tarjetas"][jugador].append(golpes)
	_avanzar_turno(estado)
	return estado


static func abandonar(estado: Dictionary) -> Dictionary:
	if estado.get("terminada", false):
		return estado
	estado["abandonada"] = true
	estado["terminada"] = true
	return estado


static func resultado(estado: Dictionary) -> Dictionary:
	var totales := {}
	for jugador in estado.get("tarjetas", {}):
		var total := 0
		for golpes in estado["tarjetas"][jugador]:
			total += int(golpes)
		totales[String(jugador)] = total

	var ranking := []
	for jugador in totales:
		ranking.append({"jugador": String(jugador), "golpes": int(totales[jugador])})
	ranking.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["golpes"]) == int(b["golpes"]):
				return String(a["jugador"]) < String(b["jugador"])
			return int(a["golpes"]) < int(b["golpes"])
	)

	var completa := estado.get("terminada", false) and not estado.get("abandonada", false)
	var ganador := ""
	if completa and not ranking.is_empty():
		ganador = String(ranking[0]["jugador"])
		if ranking.size() > 1 and int(ranking[0]["golpes"]) == int(ranking[1]["golpes"]):
			ganador = "empate"
	return {
		"completa": completa,
		"abandonada": estado.get("abandonada", false),
		"totales": totales,
		"ranking": ranking,
		"ganador": ganador,
	}


static func _puede_actuar(estado: Dictionary, jugador: String) -> bool:
	if estado.get("terminada", false) or estado.get("abandonada", false):
		return false
	if int(estado.get("hoyo", 0)) >= HOYOS:
		return false
	return jugador_actual(estado) == jugador


static func _avanzar_turno(estado: Dictionary) -> void:
	var jugadores: Array = estado.get("jugadores", [])
	var actual := jugador_actual(estado)
	if not actual.is_empty():
		estado["golpes_hoyo"][actual] = 0

	var siguiente := int(estado.get("turno", 0)) + 1
	if siguiente < jugadores.size():
		estado["turno"] = siguiente
		return

	estado["turno"] = 0
	estado["hoyo"] = int(estado.get("hoyo", 0)) + 1
	for jugador in jugadores:
		estado["golpes_hoyo"][String(jugador)] = 0
	if int(estado["hoyo"]) >= HOYOS:
		estado["terminada"] = true
