## Reacciones puras de la memoria nocturna (#162).
##
## Consume exclusivamente la selección ya validada, el catálogo recibido y las
## pistas ya conocidas que se le pasan como argumentos. No carga archivos ni
## modifica estado global, y no convierte relaciones desconocidas en pistas nuevas.
class_name MemoriaNocturna
extends RefCounted


static func analizar(
	seleccion: Array,
	casos: Array,
	descubiertas: Array = [],
	contradicciones_declaradas: Array = [],
) -> Dictionary:
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
	var contradicciones := _contradicciones_conocidas(
		conteos, casos, descubiertas, contradicciones_declaradas
	)
	return {
		"documentos_unicos": conteos.size(),
		"intensidad_maxima": intensidad_maxima,
		"repeticiones": repeticiones,
		"relaciones": relaciones,
		"hay_relacion": not relaciones.is_empty(),
		"contradicciones": contradicciones,
		"hay_contradiccion": not contradicciones.is_empty(),
		"firma": firma(seleccion, relaciones, contradicciones),
	}


static func firma(
	seleccion: Array,
	relaciones: Array = [],
	contradicciones: Array = [],
) -> String:
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
	for contradiccion in contradicciones:
		if not contradiccion is Dictionary:
			continue
		var regla := contradiccion as Dictionary
		var id := String(regla.get("id", ""))
		var folios: Array = regla.get("folios", [])
		partes.append("contradiccion:%s:%s" % [id, ",".join(folios)])
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


static func _contradicciones_conocidas(
	conteos: Dictionary,
	casos: Array,
	descubiertas: Array,
	declaradas: Array,
) -> Array:
	var casos_por_id := {}
	for valor in casos:
		if not valor is Dictionary:
			continue
		var caso := valor as Dictionary
		var caso_id := String(caso.get("id", ""))
		if not caso_id.is_empty():
			casos_por_id[caso_id] = caso

	var resultado_por_id := {}
	for valor in declaradas:
		if not valor is Dictionary:
			continue
		var regla := valor as Dictionary
		var id := String(regla.get("id", ""))
		var caso_id := String(regla.get("caso_id", ""))
		var registros: Array = regla.get("registros", [])
		var pistas_requeridas: Array = regla.get("pistas_requeridas", [])
		if (
			id.is_empty()
			or caso_id.is_empty()
			or registros.size() != 2
			or pistas_requeridas.is_empty()
			or not casos_por_id.has(caso_id)
		):
			continue

		var registro_a := String(registros[0])
		var registro_b := String(registros[1])
		if registro_a.is_empty() or registro_b.is_empty() or registro_a == registro_b:
			continue

		var caso: Dictionary = casos_por_id[caso_id]
		var pistas_del_caso := _pistas_por_id(caso)
		var pistas := []
		var regla_conocida := true
		for pista_valor in pistas_requeridas:
			var pista_id := String(pista_valor)
			if (
				pista_id.is_empty()
				or not pistas_del_caso.has(pista_id)
				or not descubiertas.has(pista_id)
			):
				regla_conocida = false
				break
			pistas.append(pista_id)
		if not regla_conocida:
			continue

		var folios_por_id := _folios_por_registro(caso)
		var folio_a := String(folios_por_id.get(registro_a, ""))
		var folio_b := String(folios_por_id.get(registro_b, ""))
		if (
			folio_a.is_empty()
			or folio_b.is_empty()
			or not conteos.has(folio_a)
			or not conteos.has(folio_b)
		):
			continue

		var folios := [folio_a, folio_b]
		folios.sort()
		pistas.sort()
		resultado_por_id[id] = {
			"id": id,
			"caso_id": caso_id,
			"folios": folios,
			"pistas": pistas,
		}

	var ids := resultado_por_id.keys()
	ids.sort()
	var resultado := []
	for id in ids:
		resultado.append(resultado_por_id[id])
	return resultado


static func _pistas_por_id(caso: Dictionary) -> Dictionary:
	var resultado := {}
	for valor in caso.get("pistas", []):
		if not valor is Dictionary:
			continue
		var id := String((valor as Dictionary).get("id", ""))
		if not id.is_empty():
			resultado[id] = true
	return resultado


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
