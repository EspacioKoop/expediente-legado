## Qué pistas ha descubierto el jugador y qué expedientes ha resuelto.
##
## Port de [code]ProgresoService[/code]. Desaparecen los repositorios y con
## ellos la razón de ser de la mitad del original: [code]pistasPorCaso[/code] y
## la variante de [code]progreso[/code] que reutilizaba el mapa existían para
## evitar un N+1 de consultas SQL. Sin base de datos no hay consulta que
## evitar, y las pistas ya vienen dentro de su caso.
##
## Lo que NO cambia es la regla: el progreso no se guarda en el caso, se deriva
## siempre del conjunto de pistas descubiertas.
class_name Progreso
extends RefCounted


static func caso_resuelto(caso: Dictionary, descubiertas: Array) -> bool:
	var pistas: Array = caso.get("pistas", [])
	if pistas.is_empty():
		return false
	for pista in pistas:
		if not descubiertas.has(pista["id"]):
			return false
	return true


static func todos_resueltos(casos: Array, descubiertas: Array) -> bool:
	if casos.is_empty():
		return false
	for caso in casos:
		if not caso_resuelto(caso, descubiertas):
			return false
	return true


## Por cada caso: cuántas pistas tiene, cuántas se han encontrado y si está
## resuelto.
static func de_casos(casos: Array, descubiertas: Array) -> Array:
	var resumen := []
	for caso in casos:
		var pistas: Array = caso.get("pistas", [])
		var encontradas := 0
		for pista in pistas:
			if descubiertas.has(pista["id"]):
				encontradas += 1
		(
			resumen
			. append(
				{
					"caso": caso,
					"total": pistas.size(),
					"encontradas": encontradas,
					"resuelto": not pistas.is_empty() and encontradas == pistas.size(),
				}
			)
		)
	return resumen
