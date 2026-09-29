extends SceneTree

const DiaIncidenteImpresoraApp = preload("res://guion/dia_incidente_impresora_app.gd")


class HostFalso:
	extends Node3D

	var jornada: Dictionary
	var _mundo: Node3D

	func _init(raiz: int) -> void:
		jornada = Jornada.nueva(raiz)
		_mundo = Node3D.new()
		_mundo.name = "Mundo"
		add_child(_mundo)


var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	await _probar_materializacion_y_chat()
	await _probar_secuencia_y_recarga()
	await _probar_ignorar_y_dia_nuevo()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _raiz_activa(jornada: Dictionary) -> int:
	for raiz in range(1, 500):
		if bool(IncidenteImpresoraOficina.programacion(jornada, raiz).get("activa", false)):
			return raiz
	return 1


func _nuevo_host() -> HostFalso:
	var base := Jornada.nueva(1)
	var raiz := _raiz_activa(base)
	var host := HostFalso.new(raiz)
	root.add_child(host)
	return host


func _nuevo_controller(host: HostFalso) -> DiaIncidenteImpresoraApp:
	var controller := DiaIncidenteImpresoraApp.new()
	host.add_child(controller)
	return controller


func _activar_umbral(host: HostFalso) -> Dictionary:
	var plan := IncidenteImpresoraOficina.programacion(host.jornada, int(host.jornada["raiz"]))
	host.jornada["acciones"] = Jornada.ACCIONES_POR_DIA - int(plan["tras_accion"])
	return plan


func _probar_materializacion_y_chat() -> void:
	var host := _nuevo_host()
	var controller := _nuevo_controller(host)
	var plan := IncidenteImpresoraOficina.programacion(host.jornada, int(host.jornada["raiz"]))
	var normal := controller.sincronizar(host)
	_comprobar(String(normal["status"]) == "normal", "antes del umbral la impresora está normal")
	_comprobar(controller._impresora != null, "la impresora física existe antes del atasco")
	_comprobar(not controller._impresora.habilitado, "la impresora normal no abre secuencia")
	_comprobar(not host.jornada.has(controller.CLAVE_ESTADO), "no crea estado antes de tiempo")
	_comprobar(
		not (host.jornada.get("eventos", []) as Array).has(IncidenteImpresoraOficina.EVENTO),
		"no publica evento antes de tiempo",
	)

	host.jornada["acciones"] = Jornada.ACCIONES_POR_DIA - int(plan["tras_accion"])
	var activa := controller.sincronizar(host)
	_comprobar(String(activa["status"]) == "incidencia", "el umbral materializa la incidencia")
	_comprobar(host.jornada.has(controller.CLAVE_ESTADO), "el incidente persiste en Jornada")
	_comprobar(controller._impresora.habilitado, "el atasco habilita interacción")
	_comprobar(
		controller._impresora.nombre_sonido().is_empty(),
		"inspeccionar no inventa un sonido genérico",
	)
	_comprobar(bool(activa["evento_publicado"]), "publica el evento canónico")

	var chat := ChatCorporativoModelo.new()
	(
		chat
		. configurar_contexto(
			{
				"fase": "archivo",
				"dia": host.jornada["dia"],
				"acciones": host.jornada["acciones"],
				"companeros": ["becario", "telefono"],
				"eventos": host.jornada["eventos"],
			},
		)
	)
	var ids: Array[String] = []
	for canal in chat.canales_visibles():
		ids.append(String(canal.get("id", "")))
	_comprobar(ids.has("inc-impresora"), "el evento real abre el canal corporativo")
	host.queue_free()
	await process_frame


func _probar_secuencia_y_recarga() -> void:
	var host := _nuevo_host()
	var controller := _nuevo_controller(host)
	_activar_umbral(host)
	controller.sincronizar(host)
	var acciones_antes := int(host.jornada["acciones"])

	controller._al_activar(null)
	var estado: Dictionary = host.jornada[controller.CLAVE_ESTADO]
	_comprobar(bool(estado["inspeccionada"]), "primera interacción inspecciona")
	_comprobar(
		controller._impresora.verbo == Interactuable3D.Verbo.ABRIR,
		"después ofrece abrir bandeja",
	)
	_comprobar(
		controller._impresora.nombre_sonido() == "abrir", "abrir usa audio común"
	)

	controller._al_activar(null)
	estado = host.jornada[controller.CLAVE_ESTADO]
	_comprobar(
		String(estado["estado"]) == IncidenteImpresoraOficina.BANDEJA_ABIERTA,
		"segunda interacción abre bandeja",
	)
	_comprobar(controller._papel.visible, "al abrir se ve el papel atascado")
	_comprobar(
		controller._impresora.verbo == Interactuable3D.Verbo.COGER,
		"después ofrece coger papel",
	)
	_comprobar(
		controller._impresora.nombre_sonido() == "coger", "retirar papel usa audio común"
	)

	var guardado: Dictionary = (host.jornada[controller.CLAVE_ESTADO] as Dictionary).duplicate(true)
	controller.queue_free()
	await process_frame
	var recargado := _nuevo_controller(host)
	recargado.sincronizar(host)
	_comprobar(host.jornada[recargado.CLAVE_ESTADO] == guardado, "remontar conserva progreso")
	_comprobar(
		(host.jornada["eventos"] as Array).count(IncidenteImpresoraOficina.EVENTO) == 1,
		"remontar no duplica evento",
	)
	_comprobar(recargado._papel.visible, "remontar reconstruye el papel visible")

	recargado._al_activar(null)
	estado = host.jornada[recargado.CLAVE_ESTADO]
	_comprobar(
		String(estado["estado"]) == IncidenteImpresoraOficina.PAPEL_RETIRADO,
		"tercera interacción retira papel",
	)
	_comprobar(not recargado._papel.visible, "retirar oculta el papel")
	_comprobar(
		recargado._impresora.verbo == Interactuable3D.Verbo.CERRAR,
		"después ofrece cerrar",
	)
	_comprobar(
		recargado._impresora.nombre_sonido() == "cerrar", "cerrar usa audio común"
	)
	recargado._al_activar(null)
	estado = host.jornada[recargado.CLAVE_ESTADO]
	_comprobar(bool(estado["resuelta"]), "cuarta interacción resuelve")
	_comprobar(not recargado._impresora.habilitado, "resuelta deja impresora normal")
	_comprobar(int(host.jornada["acciones"]) == acciones_antes, "resolver no consume acciones")
	_comprobar(host.has_meta("ultimo_feedback_impresora"), "cada paso deja feedback observable")
	host.queue_free()
	await process_frame


func _probar_ignorar_y_dia_nuevo() -> void:
	var host := _nuevo_host()
	var controller := _nuevo_controller(host)
	_activar_umbral(host)
	controller.sincronizar(host)
	var estado_antes := (host.jornada[controller.CLAVE_ESTADO] as Dictionary).duplicate(true)
	var acciones_antes := int(host.jornada["acciones"])
	for _i in range(4):
		controller.sincronizar(host)
	_comprobar(
		host.jornada[controller.CLAVE_ESTADO] == estado_antes,
		"ignorar no avanza la incidencia",
	)
	_comprobar(
		int(host.jornada["acciones"]) == acciones_antes, "ignorar no bloquea ni gasta acciones"
	)

	host.jornada["dia"] = int(host.jornada["dia"]) + 1
	host.jornada["acciones"] = Jornada.ACCIONES_POR_DIA
	controller.sincronizar(host)
	var estado_nuevo: Variant = host.jornada.get(controller.CLAVE_ESTADO, {})
	_comprobar(
		not estado_nuevo is Dictionary or (estado_nuevo as Dictionary).is_empty(),
		"un día nuevo descarta el estado viejo antes de otro umbral",
	)
	_comprobar(
		not (host.jornada.get("eventos", []) as Array).has(IncidenteImpresoraOficina.EVENTO),
		"un día nuevo retira el evento temporal viejo",
	)
	host.queue_free()
	await process_frame


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
