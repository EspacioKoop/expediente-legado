## Regresión de la entrada OS98 del RPG original Crónicas (#2589).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var escritorio := EscritorioSigaVisual.new()
	escritorio.name = "EscritorioPruebaCronicas"
	get_root().add_child(escritorio)
	await process_frame

	var avisos := [0]
	var app := CronicasOs98Enlace.registrar(
		escritorio, func(): avisos[0] += 1
	)
	_comprobar(app != null, "alta con EscritorioSigaApp existente")
	if app == null:
		escritorio.queue_free()
		_terminar()
		return
	_comprobar(app.id == CronicasOs98Enlace.ID_APP, "id estable del programa")
	_comprobar(app.persistir_estado, "solo metadata verificable en EstadoAplicacionesSiga")
	_comprobar(not app.multiples_instancias, "una instancia por escritorio")

	app.abrir(escritorio)
	await process_frame
	var ventana := escritorio.find_child("Ventana_cronicas-pc-98", true, false)
	_comprobar(ventana is Control, "ventana OS98 real abierta")
	var contenido: CronicasPc98 = null
	if ventana != null:
		contenido = ventana.find_child("Contenido", true, false) as CronicasPc98
	_comprobar(contenido != null, "fábrica usa programa original de 1998")
	if contenido == null:
		escritorio.queue_free()
		_terminar()
		return
	_comprobar(contenido.modo_ventana_os98, "encapsulación 3D activada")
	_comprobar(contenido.comenzar(), "lanzamiento por contrato oficial")
	await process_frame
	var contenedor := contenido.get_node_or_null("Area3DCronicas") as SubViewportContainer
	_comprobar(contenedor != null, "3D aislado del espacio de trabajo")
	var viewport: SubViewport = null
	if contenedor != null:
		viewport = contenedor.get_node_or_null("ViewportCronicas") as SubViewport
	_comprobar(viewport != null, "SubViewport exclusivo")
	if viewport == null:
		escritorio.queue_free()
		_terminar()
		return
	_comprobar(viewport.own_world_3d, "mundo 3D no comparte la escena real de Dia")
	var sala := viewport.get_node_or_null("PartidaCronicas") as CronicasBastion3D
	_comprobar(sala != null, "escena jugable dentro de ventana OS98")
	_comprobar(contenido.juego_en_curso(), "estado local activo")
	_comprobar(avisos[0] == 0, "arrancar programa no acredita visita")

	escritorio.minimizar(app.id)
	await process_frame
	_comprobar(sala.process_mode == Node.PROCESS_MODE_DISABLED, "minimizar pausa la escena")
	_comprobar(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "minimizar libera cursor")
	escritorio.restaurar(app.id)
	await process_frame
	_comprobar(sala.process_mode == Node.PROCESS_MODE_INHERIT, "restaurar reanuda escena")

	sala.registrar_lectura()
	sala.registrar_lectura()
	sala.registrar_resultado_duelo(true)
	_comprobar(sala.solicitar_salida(), "retorno desde final real del prólogo")
	_comprobar(avisos[0] == 1, "solo cruzar umbral acredita visita")
	await process_frame
	_comprobar(not contenido.juego_en_curso(), "sala liberada tras regreso")
	_comprobar(contenido.prologos_locales() == 1, "solo cuenta local")

	var cerrar := contenido.find_child("CerrarPrograma", true, false) as Button
	_comprobar(cerrar != null, "cierre de app accesible desde ventana")
	if cerrar != null:
		cerrar.pressed.emit()
	await process_frame
	_comprobar(
		escritorio.find_child("Ventana_cronicas-pc-98", true, false) == null,
		"cerrar devuelve a shell sin abandonar Dia",
	)
	_comprobar(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "sin ratón capturado al cerrar")
	_comprobar(avisos[0] == 1, "cerrar programa no acredita visita adicional")

	escritorio.queue_free()
	await process_frame
	_terminar()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("OS98 Crónicas: " + nombre)


func _terminar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)
