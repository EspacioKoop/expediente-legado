## Tanteo y turnos del minijuego de bolos (#170).
##
## No conoce física, escenas ni Partida: quien lo use decide cuántos bolos
## derriba cada lanzamiento. Así el mismo estado sirve para una prueba, una
## escena provisional o la futura pista jugable de #159.
class_name Bolos
extends RefCounted

const BOLOS_POR_TURNO := 10
const LANZAMIENTOS_POR_TURNO := 2


static func nueva(lanzadores: Array) -> Dictionary:
	return {
		"lanzadores": lanzadores.duplicate(),
		"turno": 0,
		"lanzamiento": 0,
		"derribados_turno": 0,
		"puntuaciones": lanzadores.map(func(_nombre): return 0),
		"terminada": false,
		"abandonada": false,
	}


## Aplica un lanzamiento y devuelve el mismo estado para poder encadenar pasos.
## El valor se limita a los bolos que siguen en pie y nunca puede producir un
## tanteo negativo ni superar diez en un turno.
static func derribar(estado: Dictionary, bolos: int) -> Dictionary:
	if estado.get("terminada", false) or estado.get("abandonada", false):
		return estado
	var restantes := BOLOS_POR_TURNO - int(estado["derribados_turno"])
	var cantidad := clampi(bolos, 0, restantes)
	var indice := int(estado["turno"])
	estado["derribados_turno"] += cantidad
	estado["puntuaciones"][indice] += cantidad
	estado["lanzamiento"] += 1
	if turno_terminado(estado):
		estado["lanzamiento"] = 0
		estado["derribados_turno"] = 0
		estado["turno"] += 1
		if estado["turno"] >= estado["lanzadores"].size():
			estado["terminada"] = true
	return estado


static func turno_terminado(estado: Dictionary) -> bool:
	return int(estado.get("lanzamiento", 0)) >= LANZAMIENTOS_POR_TURNO


## También devuelve un resultado válido si la actividad se abandona a mitad:
## se puntúa lo jugado y se marca que no hubo ganador completo.
static func abandonar(estado: Dictionary) -> Dictionary:
	estado["abandonada"] = true
	return resultado(estado)


static func resultado(estado: Dictionary) -> Dictionary:
	var puntuaciones: Array = estado.get("puntuaciones", []).duplicate()
	var mayor := 0
	for puntos in puntuaciones:
		mayor = maxi(mayor, int(puntos))
	var ganadores := []
	for i in puntuaciones.size():
		if int(puntuaciones[i]) == mayor:
			ganadores.append(estado["lanzadores"][i])
	return {
		"ganador": ganadores[0] if ganadores.size() == 1 else "empate",
		"ganadores": ganadores,
		"puntos": mayor,
		"puntuaciones": puntuaciones,
		"completa": estado.get("terminada", false) and not estado.get("abandonada", false),
		"abandonada": estado.get("abandonada", false),
	}
