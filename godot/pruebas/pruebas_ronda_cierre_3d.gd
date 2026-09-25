## Recorrido físico y abandono de la ronda de cierre (#156).
extends SceneTree

const RondaApp := preload("res://guion/dia_ronda_cierre_app.gd")


class DiaFalso:
	extends Node
	var jornada: Dictionary
	var partida := Partida.new()
	var guardados := 0

	func _init() -> void:
		partida.estado = Partida.nueva()
		jornada = partida.estado["jornada"]

	func _guardar_o_avisar(_destino: String) -> bool:
		guardados += 1
		return true


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	await _probar_recorrido_completo()
	await _probar_abandono_parcial()
	await _probar_cunado_montado_tarde()
	await _probar_sello_planta_en_orden()
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


func _probar_sello_planta_en_orden() -> void:
	var dia := DiaFalso.new()
	root.add_child(dia)
	var estado := _estado(["recoger_a7", "apagar_lampara", "devolver_carpeta"])
	for id_punto in estado["ruta"]:
		RondaCierre.completar_punto(estado, String(id_punto))
	dia.jornada["ronda_cierre"] = estado

	var controller := RondaApp.new()
	dia.add_child(controller)
	controller._al_completar_punto("devolver_carpeta")
	_comprobar(bool(estado["finalizada"]), "completar la ruta finaliza la ronda")
	_comprobar(estado["rango"] == RondaCierre.IMPECABLE, "la ruta completa queda impecable")
	_comprobar(
		Sellos.tiene_sello(dia.partida.estado, RondaApp.SELLO_RECOMPENSA),
		"la ronda impecable concede planta-en-orden"
	)
	_comprobar(dia.guardados == 1, "sello y ronda se guardan por el camino canónico")

	controller._al_completar_punto("devolver_carpeta")
	var obtenidos: Array = dia.partida.estado.get(Sellos.CLAVE_ESTADO, [])
	_comprobar(
		obtenidos.count(RondaApp.SELLO_RECOMPENSA) == 1,
		"repetir la finalización no duplica el sello"
	)

	var dia_legado := DiaFalso.new()
	root.add_child(dia_legado)
	var estado_legado := _estado(["recoger_a7", "revisar_bandeja", "comprobar_tablon"])
	for id_punto in estado_legado["ruta"]:
		RondaCierre.completar_punto(estado_legado, String(id_punto))
	RondaCierre.finalizar(estado_legado)
	dia_legado.jornada["ronda_cierre"] = estado_legado
	var controller_legado := RondaApp.new()
	dia_legado.add_child(controller_legado)
	controller_legado._procesar_archivo(dia_legado)
	_comprobar(
		Sellos.tiene_sello(dia_legado.partida.estado, RondaApp.SELLO_RECOMPENSA),
		"una ronda impecable ya finalizada recupera el sello al cargar"
	)
	_comprobar(dia_legado.guardados == 1, "la migración del sello se guarda una sola vez")

	dia.queue_free()
	dia_legado.queue_free()
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
