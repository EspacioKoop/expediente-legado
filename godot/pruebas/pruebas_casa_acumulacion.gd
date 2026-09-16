extends SceneTree

const CasaAcumulacion := preload("res://guion/casa_acumulacion_3d.gd")
const CasaEstadoAmbientalScript := preload("res://guion/casa_estado_ambiental.gd")
const CasaUtileriaScript := preload("res://guion/casa_utileria.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_acumulacion_domestica()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_acumulacion_domestica() -> void:
	var casa := Node3D.new()
	root.add_child(casa)
	CasaUtileriaScript.montar_zonas_domesticas(casa)

	var inventario := Inventario.nuevo()
	var objetos := [
		{"id": "lampara_verde_usada", "categoria": "hogar", "origen": "comercio_barrio"},
		{"id": "marco_latón_usado", "categoria": "hogar", "origen": "comercio_barrio"},
		{"id": "revista_umbral_98", "categoria": "publicacion", "origen": "publicaciones"},
		{"id": "cassette_grabado", "categoria": "audio", "origen": "radio"},
		{"id": "paquete_correo", "categoria": "paquete", "origen": "correo"},
		{"id": "ticket_cafeteria", "categoria": "documento", "origen": "archivo"},
		{"id": "figurita_regalo", "categoria": "recuerdo", "origen": "regalo"},
		{"id": "abrelatas_cocina", "categoria": "hogar", "origen": "casa"},
	]
	for objeto in objetos:
		_comprobar(Inventario.recoger(inventario, objeto), "recoge %s" % objeto["id"])
		_comprobar(
			Inventario.guardar_en_casa(inventario, String(objeto["id"])),
			"guarda %s en home_storage" % objeto["id"]
		)
	_comprobar(
		Inventario.recoger(
			inventario, {"id": "sello_oficina", "categoria": "util", "origen": "archivo"}
		),
		"prepara un objeto carried que no debe decorar la casa"
	)

	var estado := CasaEstadoAmbientalScript.derivar({"vuelta": 3}, inventario)
	var firma := CasaAcumulacion.firma(estado)
	var acumulacion := CasaAcumulacion.montar(casa, estado)
	_comprobar(acumulacion != null, "encuentra la estantería física de #133")
	_comprobar(acumulacion.get_child_count() == 8, "materializa ocho objetos domésticos acotados")
	_comprobar(not firma.contains("sello_oficina"), "carried no entra en la firma doméstica")

	var ids: Array[String] = []
	var variantes := {}
	for hijo in acumulacion.get_children():
		ids.append(String(hijo.get_meta("objeto_id", "")))
		variantes[String(hijo.get_meta("variante", ""))] = true
	_comprobar(ids[0] == "abrelatas_cocina", "ordena por id para una colocación reproducible")
	_comprobar(ids.has("lampara_verde_usada"), "la compra real de lámpara de #676 se hace visible")
	_comprobar(ids.has("marco_latón_usado"), "la compra real de marco de #676 se hace visible")
	_comprobar(not ids.has("sello_oficina"), "un objeto llevado no aparece como recuerdo doméstico")
	_comprobar(variantes.size() == 8, "hay ocho lecturas visuales para fuentes domésticas distintas")

	var repetida := CasaAcumulacion.montar(casa, estado)
	var ids_repetidos: Array[String] = []
	for hijo in repetida.get_children():
		ids_repetidos.append(String(hijo.get_meta("objeto_id", "")))
	_comprobar(ids_repetidos == ids, "el mismo estado produce la misma colocación")
	_comprobar(CasaAcumulacion.firma(estado) == firma, "la firma es determinista")

	_comprobar(
		Inventario.sacar_de_casa(inventario, "ticket_cafeteria"),
		"mover un objeto fuera de home_storage cambia el estado real"
	)
	var reducido := CasaEstadoAmbientalScript.derivar({"vuelta": 3}, inventario)
	var tras_sacar := CasaAcumulacion.montar(casa, reducido)
	_comprobar(tras_sacar.get_child_count() == 7, "la ausencia real retira el objeto de la casa")
	_comprobar(
		not CasaAcumulacion.firma(reducido).contains("ticket_cafeteria"),
		"la presencia no deja flags paralelos"
	)

	for extra in ["objeto_extra_a", "objeto_extra_b"]:
		_comprobar(
			Inventario.recoger(
				inventario, {"id": extra, "categoria": "hogar", "origen": "prueba"}
			),
			"recoge %s" % extra
		)
		_comprobar(Inventario.guardar_en_casa(inventario, extra), "guarda %s" % extra)
	var saturado := CasaEstadoAmbientalScript.derivar({"vuelta": 3}, inventario)
	var limitado := CasaAcumulacion.montar(casa, saturado)
	_comprobar(limitado.get_child_count() == 8, "la presentación no crece como inventario infinito")

	casa.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO CasaAcumulacion: " + nombre)
