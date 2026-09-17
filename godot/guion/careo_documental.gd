## Capa documental de la Ventanilla (#779).
##
## `Combate` sigue resolviendo Objeción/Silencio/Insistencia y las habilidades.
## Esta capa añade una decisión que sí depende de la investigación: presentar
## una pista YA descubierta y vinculada al reclamante. No inventa relaciones ni
## hechos; todo sale de `casos.json` y de los ids que el concepto ya cita.
class_name CareoDocumental
extends RefCounted

const MAX_BONO_JUICIO := 3


static func evidencias_relevantes(
	rival: Dictionary, contenido: Contenido, descubiertas: Array
) -> Array:
	var ids_rival: Array = rival.get("pistas", [])
	if ids_rival.is_empty():
		return []

	var conocidas := {}
	for id in descubiertas:
		conocidas[String(id)] = true

	var evidencias: Array = []
	for caso in contenido.casos:
		for pista in caso.get("pistas", []):
			var id := String(pista.get("id", ""))
			if conocidas.has(id) and id in ids_rival:
				evidencias.append(pista.duplicate(true))
	return evidencias


static func nuevo(rival: Dictionary, cargas: Dictionary, evidencias: Array) -> Dictionary:
	var careo := Combate.nuevo("reactiva", rival, cargas)
	careo["evidencias"] = evidencias.duplicate(true)
	careo["evidencias_usadas"] = []
	careo["evidencias_acertadas"] = 0
	return careo


static func evidencias_disponibles(careo: Dictionary) -> Array:
	var usadas: Array = careo.get("evidencias_usadas", [])
	var disponibles: Array = []
	for evidencia in careo.get("evidencias", []):
		if String(evidencia.get("id", "")) not in usadas:
			disponibles.append(evidencia)
	return disponibles


static func jugar(
	careo: Dictionary,
	tipo_jugador: String,
	evidencia_id: String,
	habilidad: String,
	azar: Callable
) -> Dictionary:
	var evidencia := _evidencia_disponible(careo, evidencia_id)
	var ronda := Combate.jugar(careo, tipo_jugador, habilidad, azar)
	if ronda.is_empty():
		return ronda

	ronda["evidencia"] = {}
	ronda["impacto_evidencia"] = 0
	if evidencia.is_empty():
		return ronda

	var id := String(evidencia["id"])
	careo["evidencias_usadas"].append(id)
	ronda["evidencia"] = evidencia

	# Una prueba no rescata una respuesta que el rival acaba de desmontar. En
	# empate o victoria, en cambio, convierte la lectura correcta en presión
	# documental real. Así investigar ayuda sin sustituir la decisión de ronda.
	if ronda["veredicto"] == "gana_rival":
		return ronda

	careo["evidencias_acertadas"] += 1
	if careo["vida_rival"] > 0:
		careo["vida_rival"] -= 1
		ronda["dano_al_rival"] += 1
		ronda["impacto_evidencia"] = 1
		if careo["vida_rival"] <= 0:
			careo["terminado"] = true
			careo["ganador"] = "jugador"

	ronda["terminado"] = careo["terminado"]
	ronda["ganador"] = careo["ganador"]
	return ronda


static func bono_juicio(careo: Dictionary) -> int:
	return mini(MAX_BONO_JUICIO, maxi(0, int(careo.get("evidencias_acertadas", 0))))


static func _evidencia_disponible(careo: Dictionary, id: String) -> Dictionary:
	if id.is_empty():
		return {}
	for evidencia in evidencias_disponibles(careo):
		if String(evidencia.get("id", "")) == id:
			return evidencia
	return {}
