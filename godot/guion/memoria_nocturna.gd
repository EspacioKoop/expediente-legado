## Reacciones puras de la memoria nocturna (#162).
##
## Consume exclusivamente la selección ya validada, el catálogo recibido y las
## pistas ya conocidas que se le pasan como argumentos. No carga archivos ni
## modifica estado global, y no convierte relaciones desconocidas en pistas nuevas.
class_name MemoriaNocturna
extends RefCounted


static func analizar(seleccion: Array, casos: Array, descubiertas: Array = []) -> Dictionary:
	var conteos := _conteos(seleccion)
	var repeticiones := []
	var folios_ordenados := conteos.keys()
	folios_ordenados.sort()
	var intensidad_maxima := 0
	for dato in folios_ordenados:
		var folio := String(dato)
		var veces := int(conteos[folio])
		intensidad_maxima = maxi(intensidad_maxima, veces)
		if veces > 1:
			repeticiones.append({"folio": folio, "veces": veces})

	var relaciones := _relaciones_conocidas(conteos, casos, descubiertas)
	return {
		"documentos_unicos": conteos.size(),
		"intensidad_maxima": intensidad_maxima,
		"repeticiones": repeticiones,
		"relaciones": relaciones,
		"hay_relacion": not relaciones.is_empty(),
		"firma": firma(seleccion, relaciones),
	}


static func firma(seleccion: Array, relaciones: Array = []) -> String:
	var partes := []
	for dato in seleccion:
		var folio := String(dato)
		if not folio.is_empty():
			partes.append("folio:" + folio)
	for relacion in relaciones:
		if not relacion is Dictionary:
			continue
		var caso_id := String((relacion as Dictionary).get("caso_id", ""))
		var folios: Array = (relacion as Dictionary).get("folios", [])
		partes.append("relacion:%s:%s" % [caso_id, ",".join(folios)])
	return "|".join(partes)


static func _conteos(seleccion: Array) -> Dictionary:
	var conteos := {}
	for dato in seleccion:
		if typeof(dato) != TYPE_STRING:
			continue
		var folio := String(dato)
		if folio.is_empty():
			continue
		conteos[folio] = int(conteos.get(folio, 0)) + 1
	return conteos


static func _relaciones_conocidas(conteos: Dictionary, casos: Array, descubiertas: Array) -> Array:
	var relaciones_por_clave := {}
	for valor in casos:
		if not valor is Dictionary:
			continue
		var caso := valor as Dictionary
		var caso_id := String(caso.get("id", ""))
		var folios_por_id := _folios_por_registro(caso)
		for pista_valor in caso.get("pistas", []):
			if not pista_valor is Dictionary:
				continue
			var pista := pista_valor as Dictionary
			var pista_id := String(pista.get("id", ""))
			if pista_id.is_empty() or not descubiertas.has(pista_id):
				continue
			var origen_a := String(pista.get("registroOrigen", ""))
			var origen_b := String(pista.get("registroOrigen2", ""))
			if origen_a.is_empty() or origen_b.is_empty() or origen_a == origen_b:
				continue
			var folio_a := String(folios_por_id.get(origen_a, ""))
			var folio_b := String(folios_por_id.get(origen_b, ""))
			if (
				folio_a.is_empty()
				or folio_b.is_empty()
				or not conteos.has(folio_a)
				or not conteos.has(folio_b)
			):
				continue
			var pareja := [folio_a, folio_b]
			pareja.sort()
			var clave := "%s|%s|%s" % [caso_id, pareja[0], pareja[1]]
			if not relaciones_por_clave.has(clave):
				relaciones_por_clave[clave] = {
					"caso_id": caso_id,
					"folios": pareja,
					"pistas": [],
				}
			var ids: Array = relaciones_por_clave[clave]["pistas"]
			if not ids.has(pista_id):
				ids.append(pista_id)
				ids.sort()

	var claves := relaciones_por_clave.keys()
	claves.sort()
	var relaciones := []
	for clave in claves:
		relaciones.append(relaciones_por_clave[clave])
	return relaciones


static func _folios_por_registro(caso: Dictionary) -> Dictionary:
	var resultado := {}
	for valor in caso.get("registros", []):
		if not valor is Dictionary:
			continue
		var registro := valor as Dictionary
		var id := String(registro.get("id", ""))
		var folio := String(registro.get("folio", ""))
		if not id.is_empty() and not folio.is_empty():
			resultado[id] = folio
	return resultado
