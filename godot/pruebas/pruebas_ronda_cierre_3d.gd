## Recorrido físico y abandono de la ronda de cierre (#156).
extends SceneTree

const RondaApp := preload("res://guion/dia_ronda_cierre_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	await _probar_recorrido_completo()
	await _probar_abandono_parcial()
	await _probar_cunado_montado_tarde()
	_probar_oferta_determinista()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(0 if _fallos == 0 else 1)


func _estado(ruta: Array) -> Dictionary:
	return {
		"dia": 7,
		"ruta": ruta,
		"completados": [],
		"abandonada": false,
		"finalizada": false,
		"rango": RondaCierre.INCOMPLETA,
	}


func _mundo_con_luz() -> Node3D:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var luz := OmniLight3D.new()
	luz.name = Espacio3D.NOMBRE_LUZ_SALA
	luz.position = RondaCierre3D.POS_LUZ_OBJETIVO
	mundo.add_child(luz)
	return mundo


func _probar_recorrido_completo() -> void:
	var mundo := _mundo_con_luz()
	var ruta := [
		"recoger_a7",
		"apagar_lampara",
		"cerrar_puerta",
		"revisar_bandeja",
		"devolver_carpeta",
	]
	var estado := _estado(ruta)
	var capa := RondaCierre3D.new()
	mundo.add_child(capa)
	capa.configurar(estado)
	await process_frame

	_comprobar(
		capa.find_children("*", "Label3D", true, false).is_empty(), "sin marcadores flotantes"
	)
	for id_punto in ruta:
		var objetivo := capa.punto(id_punto)
		_comprobar(objetivo != null, "%s existe físicamente" % id_punto)
		if objetivo != null:
			_comprobar(objetivo.interactuar(root), "%s usa interacción común" % id_punto)
			_comprobar(estado["completados"].has(id_punto), "%s persiste progreso" % id_punto)

	var luz := mundo.get_node_or_null(Espacio3D.NOMBRE_LUZ_SALA) as OmniLight3D
	_comprobar(luz != null and not luz.visible, "apagar lámpara cambia el mundo")
	_comprobar(
		RondaCierre.finalizar(estado) == RondaCierre.IMPECABLE, "recorrido completo es impecable"
	)
	_comprobar(bool(RondaCierre.progreso(estado)["completa"]), "progreso queda completo")
	mundo.queue_free()
	await process_frame


func _probar_abandono_parcial() -> void:
	var mundo := _mundo_con_luz()
	var estado := _estado(["recoger_a7", "comprobar_tablon", "devolver_carpeta"])
	var capa := RondaCierre3D.new()
	mundo.add_child(capa)
	capa.configurar(estado)
	await process_frame

	var primero := capa.punto("recoger_a7")
	_comprobar(
		primero != null and primero.interactuar(root), "se puede hacer un punto antes de abandonar"
	)
	RondaCierre.abandonar(estado)
	capa.refrescar()
	_comprobar(bool(estado["abandonada"]), "abandono queda persistido")
	_comprobar(estado["rango"] == RondaCierre.ABANDONADA, "abandono conserva su rango")
	var pendiente := capa.punto("comprobar_tablon")
	_comprobar(
		pendiente != null and not pendiente.habilitado, "abandono desactiva puntos pendientes"
	)
	_comprobar(estado["completados"].size() == 1, "abandono no duplica progreso")
	mundo.queue_free()
	await process_frame


func _probar_cunado_montado_tarde() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var estado := _estado(["recoger_a7", "devolver_carpeta", RondaCierre.PUNTO_CUNADO])
	var capa := RondaCierre3D.new()
	mundo.add_child(capa)
	capa.configurar(estado)
	await process_frame

	_comprobar(capa.punto(RondaCierre.PUNTO_CUNADO) == null, "cuñado ausente no crea un sustituto")
	var cunado := CompaneroInteractivo3D.new()
	cunado.position = RondaCierre3D.POS_CUNADO + Vector3.UP * RondaCierre3D.ALTURA_CONVERSABLE
	mundo.add_child(cunado)
	await process_frame
	capa.refrescar()
	_comprobar(capa.punto(RondaCierre.PUNTO_CUNADO) == cunado, "recarga reengancha al cuñado real")
	_comprobar(cunado.interactuar(root), "despedida reutiliza la interacción del compañero")
	_comprobar(
		estado["completados"].has(RondaCierre.PUNTO_CUNADO),
		"despedida queda en progreso persistido"
	)
	mundo.queue_free()
	await process_frame


func _probar_oferta_determinista() -> void:
	var a := RondaApp.ofrecida(7, 1234)
	var b := RondaApp.ofrecida(7, 1234)
	_comprobar(a == b, "misma semilla y día conservan oferta")
	var resultados := []
	for dia in range(1, 7):
		resultados.append(RondaApp.ofrecida(dia, 1234))
	_comprobar(resultados.has(true) and resultados.has(false), "la ronda aparece algunas tardes")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(nombre)
