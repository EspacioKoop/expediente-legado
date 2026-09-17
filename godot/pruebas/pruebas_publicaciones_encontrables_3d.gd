extends SceneTree

const Encontrables := preload("res://guion/publicaciones_encontrables_3d.gd")
const Oficina := preload("res://guion/oficina_utileria.gd")
const Casa := preload("res://guion/casa_utileria.gd")
const CasaEstado := preload("res://guion/casa_estado_ambiental.gd")
const CasaAcumulacion := preload("res://guion/casa_acumulacion_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_catalogo_encontrable()
	_probar_recogida_en_oficina()
	_probar_manual_en_casa()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_catalogo_encontrable() -> void:
	var ids := Encontrables.ids_encontrables()
	_comprobar(ids.size() == 4, "hay cuatro ejemplares encontrables")
	_comprobar(ids.has("byte_domestico_42"), "Byte Doméstico es encontrable")
	_comprobar(ids.has("marcador_98_deportes"), "Marcador 98 es encontrable")
	_comprobar(ids.has("estratos_ciudad_06"), "Estratos de Ciudad es encontrable")
	_comprobar(ids.has("manual_casa_98"), "Manual de Casa es encontrable")

	for item_id in ids:
		var ficha := Publicaciones98.por_id(item_id)
		var objeto := Encontrables.objeto_inventario(item_id)
		_comprobar(not ficha.is_empty(), "%s existe en el catálogo" % item_id)
		_comprobar(not bool(ficha.get("comprable", true)), "%s no compite con el quiosco" % item_id)
		_comprobar(
			String(objeto.get("categoria", "")) == "publicacion",
			"%s entra como publicación" % item_id
		)
		_comprobar(not bool(objeto.get("vendible", true)), "%s no permite farmear dinero" % item_id)
		_comprobar(bool(objeto.get("permite_casa", false)), "%s se puede guardar en casa" % item_id)


func _probar_recogida_en_oficina() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	Oficina.montar(mundo)
	var inventario := Inventario.nuevo()

	_comprobar(
		Encontrables.listo_para_montar(mundo, "archivo", 1, inventario),
		"las anclas de oficina existen"
	)
	var dia_uno := Encontrables.montar(mundo, "archivo", 1, inventario)
	var encontrados_dia_uno := _recogibles(dia_uno)
	_comprobar(encontrados_dia_uno.size() == 2, "día 1 ofrece dos lecturas ambientales")
	_comprobar(_ids(encontrados_dia_uno).has("byte_domestico_42"), "Byte aparece en un puesto")
	_comprobar(
		_ids(encontrados_dia_uno).has("marcador_98_deportes"), "Marcador aparece junto al café"
	)
	_comprobar(not _ids(encontrados_dia_uno).has("estratos_ciudad_06"), "Estratos espera al día 2")

	var dia_dos := Encontrables.montar(mundo, "archivo", 2, inventario)
	var encontrados_dia_dos := _recogibles(dia_dos)
	_comprobar(encontrados_dia_dos.size() == 3, "día 2 ofrece las tres publicaciones de archivo")
	_comprobar(_ids(encontrados_dia_dos).has("estratos_ciudad_06"), "Estratos aparece desde día 2")

	var byte := _por_id(encontrados_dia_dos, "byte_domestico_42")
	_comprobar(byte != null, "localiza Byte como Recogible3D")
	if byte == null:
		mundo.queue_free()
		return
	_comprobar(byte.verbo == Interactuable3D.Verbo.COGER, "el ejemplar reutiliza el verbo COGER")
	_comprobar(
		byte.find_child("VolumenInteraccion", true, false) != null,
		"el recogible tiene volumen de interacción"
	)
	_comprobar(
		String(byte.get_meta("ancla_publicacion", "")) == "PuestoUtileria1",
		"Byte conserva ancla real"
	)

	var actor := Node.new()
	mundo.add_child(actor)
	_comprobar(byte.interactuar(actor), "recoger Byte usa Recogible3D")
	_comprobar(Inventario.contiene(inventario, "byte_domestico_42"), "Byte entra en Inventario")
	_comprobar(inventario[Inventario.CARRIED].size() == 1, "la recogida termina en carried")
	_comprobar(
		not bool(Inventario.vender(inventario, "byte_domestico_42").get("vendido", true)),
		"el hallazgo no se vende"
	)

	var remontado := Encontrables.montar(mundo, "archivo", 2, inventario)
	_comprobar(
		not _ids(_recogibles(remontado)).has("byte_domestico_42"),
		"un ejemplar poseído no respawnea"
	)
	_comprobar(
		Inventario.guardar_en_casa(inventario, "byte_domestico_42"),
		"el hallazgo usa almacenamiento normal"
	)

	var casa := Node3D.new()
	root.add_child(casa)
	Casa.montar_zonas_domesticas(casa)
	var ambiental := CasaEstado.derivar({"vuelta": 1}, inventario)
	var acumulacion := CasaAcumulacion.montar(casa, ambiental)
	var lectura := _publicacion_casa(acumulacion, "byte_domestico_42")
	_comprobar(lectura != null, "el hallazgo guardado reaparece físicamente en casa")
	if lectura != null:
		_comprobar(lectura.verbo == Interactuable3D.Verbo.LEER, "en casa cambia de COGER a LEER")

	casa.queue_free()
	mundo.queue_free()


func _probar_manual_en_casa() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	Casa.montar_zonas_domesticas(mundo)
	var inventario := Inventario.nuevo()
	_comprobar(
		Encontrables.listo_para_montar(mundo, "casa", 1, inventario), "el sofá es un ancla válida"
	)
	var raiz := Encontrables.montar(mundo, "casa", 1, inventario)
	var recogibles := _recogibles(raiz)
	_comprobar(recogibles.size() == 1, "casa solo ofrece el Manual encontrable")
	_comprobar(_ids(recogibles) == ["manual_casa_98"], "Manual de Casa aparece en el sofá")
	if not recogibles.is_empty():
		_comprobar(
			String(recogibles[0].get_meta("ancla_publicacion", "")) == "SofaCasa",
			"Manual conserva su ancla doméstica"
		)
	mundo.queue_free()


func _recogibles(raiz: Node3D) -> Array[Recogible3D]:
	var salida: Array[Recogible3D] = []
	if raiz == null:
		return salida
	for nodo in raiz.get_children():
		if nodo is Recogible3D:
			salida.append(nodo)
	return salida


func _ids(recogibles: Array[Recogible3D]) -> Array[String]:
	var salida: Array[String] = []
	for recogible in recogibles:
		salida.append(String(recogible.get_meta("publicacion_id", "")))
	return salida


func _por_id(recogibles: Array[Recogible3D], item_id: String) -> Recogible3D:
	for recogible in recogibles:
		if String(recogible.get_meta("publicacion_id", "")) == item_id:
			return recogible
	return null


func _publicacion_casa(raiz: Node3D, item_id: String) -> Interactuable3D:
	if raiz == null:
		return null
	for nodo in raiz.get_children():
		if nodo is Interactuable3D and String(nodo.get_meta("publicacion_id", "")) == item_id:
			return nodo
	return null


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PublicacionesEncontrables3D: " + nombre)
