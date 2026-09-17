extends SceneTree

const CasaAcumulacion := preload("res://guion/casa_acumulacion_3d.gd")
const CasaEstadoAmbientalScript := preload("res://guion/casa_estado_ambiental.gd")
const CasaUtileriaScript := preload("res://guion/casa_utileria.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_publicaciones_fisicas()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_publicaciones_fisicas() -> void:
	var casa := Node3D.new()
	root.add_child(casa)
	CasaUtileriaScript.montar_zonas_domesticas(casa)

	var inventario := Inventario.nuevo()
	for item_id in ["revista_umbral_98", "periodico_tarde_98", "manual_casa_98"]:
		var objeto := _objeto_publicacion(item_id)
		_comprobar(not objeto.is_empty(), "el catálogo conoce %s" % item_id)
		_comprobar(Inventario.recoger(inventario, objeto), "recoge %s" % item_id)
		_comprobar(Inventario.guardar_en_casa(inventario, item_id), "guarda %s" % item_id)

	var estado := CasaEstadoAmbientalScript.derivar({"vuelta": 2}, inventario)
	var acumulacion := CasaAcumulacion.montar(casa, estado)
	_comprobar(acumulacion != null, "la casa ofrece la estantería de acumulación")

	var publicaciones := _publicaciones(acumulacion)
	_comprobar(publicaciones.size() == 3, "tres publicaciones coexisten físicamente en casa")
	_comprobar(_ids(publicaciones).has("revista_umbral_98"), "Umbral aparece como objeto físico")
	_comprobar(_ids(publicaciones).has("periodico_tarde_98"), "La Tarde aparece como objeto físico")
	_comprobar(_ids(publicaciones).has("manual_casa_98"), "el manual aparece como objeto físico")

	for publicacion in publicaciones:
		var item_id := String(publicacion.get_meta("publicacion_id", ""))
		_comprobar(
			publicacion.verbo == Interactuable3D.Verbo.LEER,
			"%s reutiliza el verbo LEER de interacción 3D" % item_id
		)
		_comprobar(
			publicacion.texto_accion().begins_with("Leer "),
			"%s expone un prompt físico legible" % item_id
		)
		_comprobar(
			not String(publicacion.get_meta("titulo_publicacion", "")).is_empty(),
			"%s conserva título de catálogo" % item_id
		)
		_comprobar(
			not String(publicacion.get_meta("portada_titulo", "")).is_empty(),
			"%s conserva texto de portada o primera pieza" % item_id
		)
		_comprobar(_tiene_colision(publicacion), "%s puede recibir el raycast común" % item_id)
		_comprobar(
			publicacion.get_child_count() >= 4, "%s tiene cuerpo, cubierta y colisión" % item_id
		)

	_comprobar(
		_formato(publicaciones, "revista_umbral_98") == "revista", "Umbral se presenta como revista"
	)
	_comprobar(
		_formato(publicaciones, "periodico_tarde_98") == "periodico",
		"La Tarde se presenta como periódico plegado"
	)
	_comprobar(
		_formato(publicaciones, "manual_casa_98") == "libro", "el manual tiene lomo de libro"
	)

	var posiciones := _posiciones(publicaciones)
	var repetida := CasaAcumulacion.montar(casa, estado)
	_comprobar(
		_posiciones(_publicaciones(repetida)) == posiciones,
		"el mismo home_storage conserva colocación reproducible"
	)

	_comprobar(
		Inventario.sacar_de_casa(inventario, "periodico_tarde_98"),
		"sacar el periódico usa Inventario"
	)
	var reducido := CasaEstadoAmbientalScript.derivar({"vuelta": 2}, inventario)
	var tras_sacar := CasaAcumulacion.montar(casa, reducido)
	_comprobar(
		not _ids(_publicaciones(tras_sacar)).has("periodico_tarde_98"),
		"retirar de home_storage retira el periódico físico"
	)

	casa.queue_free()


func _objeto_publicacion(item_id: String) -> Dictionary:
	var ficha := Publicaciones98.por_id(item_id)
	if ficha.is_empty():
		return {}
	return {
		"id": item_id,
		"nombre": String(ficha.get("titulo", item_id)),
		"categoria": "publicacion",
		"origen": "publicaciones_98",
		"vendible": false,
		"precio": 0,
	}


func _publicaciones(acumulacion: Node3D) -> Array[Interactuable3D]:
	var salida: Array[Interactuable3D] = []
	if acumulacion == null:
		return salida
	for nodo in acumulacion.get_children():
		if nodo is Interactuable3D and not String(nodo.get_meta("publicacion_id", "")).is_empty():
			salida.append(nodo)
	return salida


func _ids(publicaciones: Array[Interactuable3D]) -> Array[String]:
	var salida: Array[String] = []
	for publicacion in publicaciones:
		salida.append(String(publicacion.get_meta("publicacion_id", "")))
	return salida


func _formato(publicaciones: Array[Interactuable3D], item_id: String) -> String:
	for publicacion in publicaciones:
		if String(publicacion.get_meta("publicacion_id", "")) == item_id:
			return String(publicacion.get_meta("formato_publicacion", ""))
	return ""


func _posiciones(publicaciones: Array[Interactuable3D]) -> Dictionary:
	var salida := {}
	for publicacion in publicaciones:
		salida[String(publicacion.get_meta("publicacion_id", ""))] = publicacion.position
	return salida


func _tiene_colision(publicacion: Interactuable3D) -> bool:
	for hijo in publicacion.get_children():
		if hijo is CollisionShape3D:
			return true
	return false


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PublicacionesCasa3D: " + nombre)
