## Regresión ejecutable del playtest #793.
##
## Cubre dos fallos que pueden dejar SIGA-98 sin salida: la rueda no debe
## recapturar el ratón mientras una pantalla mantiene al caminante inactivo y
## una acción normal de navegación debe reconstruir un foco perdido dentro del
## escritorio para que teclado/mando vuelvan a tener un punto de partida.
extends SceneTree

const CAMINANTE_SCRIPT := preload("res://guion/caminante.gd")
const CONTROLADOR_ESCRITORIO_SCRIPT := preload("res://guion/dia_escritorio_siga_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_recaptura_raton()
	await _probar_recuperacion_foco()
	await _probar_salida_menu_global()
	for frame in 2:
		await process_frame
	if _fallos == 0:
		print("Foco/ratón #793: OK (%d comprobaciones)" % _pasadas)
		quit(0)
		return
	push_error("Foco/ratón #793: %d fallos" % _fallos)
	quit(1)


func _probar_recaptura_raton() -> void:
	_comprobar(
		CAMINANTE_SCRIPT.debe_recapturar_raton(_raton(MOUSE_BUTTON_LEFT), true, false),
		"clic izquierdo recupera captura al caminar",
	)
	_comprobar(
		CAMINANTE_SCRIPT.debe_recapturar_raton(_raton(MOUSE_BUTTON_RIGHT), true, false),
		"clic derecho recupera captura al caminar",
	)
	_comprobar(
		CAMINANTE_SCRIPT.debe_recapturar_raton(_raton(MOUSE_BUTTON_MIDDLE), true, false),
		"clic central recupera captura al caminar",
	)
	_comprobar(
		not CAMINANTE_SCRIPT.debe_recapturar_raton(_raton(MOUSE_BUTTON_WHEEL_UP), true, false),
		"rueda arriba no captura el ratón",
	)
	_comprobar(
		not CAMINANTE_SCRIPT.debe_recapturar_raton(_raton(MOUSE_BUTTON_WHEEL_DOWN), true, false),
		"rueda abajo no captura el ratón",
	)
	_comprobar(
		not CAMINANTE_SCRIPT.debe_recapturar_raton(_raton(MOUSE_BUTTON_LEFT, false), true, false),
		"soltar un botón no captura el ratón",
	)
	_comprobar(
		not CAMINANTE_SCRIPT.debe_recapturar_raton(_raton(MOUSE_BUTTON_LEFT), false, false),
		"una pantalla con caminante inactivo conserva ratón visible",
	)
	_comprobar(
		not CAMINANTE_SCRIPT.debe_recapturar_raton(_raton(MOUSE_BUTTON_LEFT), true, true),
		"un árbol pausado conserva ratón visible",
	)


func _probar_recuperacion_foco() -> void:
	var escritorio := EscritorioSigaVisual.new()
	root.add_child(escritorio)
	await process_frame

	_liberar_foco()
	_comprobar(
		escritorio.recuperar_foco(_accion("ui_down")),
		"navegación recupera foco si no existe",
	)
	var foco := root.gui_get_focus_owner()
	_comprobar(
		is_instance_valid(foco) and foco.name == "BotonMenu",
		"sin ventanas el foco vuelve al menú del sistema",
	)
	var foco_valido := foco
	_comprobar(
		not escritorio.recuperar_foco(_accion("ui_accept")),
		"un foco válido dentro del escritorio no se roba",
	)
	_comprobar(root.gui_get_focus_owner() == foco_valido, "se conserva el foco válido")

	escritorio.registrar_aplicacion("prueba", "Prueba", Callable(self, "_crear_contenido_prueba"))
	escritorio.abrir_aplicacion("prueba")
	await process_frame
	_liberar_foco()
	_comprobar(
		escritorio.recuperar_foco(_accion("ui_right")),
		"una ventana abierta recupera el foco perdido",
	)
	foco = root.gui_get_focus_owner()
	_comprobar(
		is_instance_valid(foco) and foco.name == "BotonContenidoPrueba",
		"se prioriza el contenido de la ventana superior",
	)

	escritorio._alternar_menu()
	await process_frame
	_liberar_foco()
	_comprobar(
		escritorio.recuperar_foco(_accion("ui_down")),
		"el menú abierto recupera foco antes que las ventanas",
	)
	foco = root.gui_get_focus_owner()
	_comprobar(
		is_instance_valid(foco) and escritorio._menu.is_ancestor_of(foco),
		"el foco recuperado pertenece al menú visible",
	)
	escritorio._alternar_menu()

	var modal := VBoxContainer.new()
	var boton_modal := Button.new()
	boton_modal.name = "BotonModalPrueba"
	boton_modal.text = "Modal"
	modal.add_child(boton_modal)
	escritorio.abrir_modal("modal-prueba", "Modal", modal)
	await process_frame
	_liberar_foco()
	_comprobar(
		escritorio.recuperar_foco(_accion("ui_accept")),
		"una modal recupera foco antes que cualquier otra superficie",
	)
	foco = root.gui_get_focus_owner()
	var panel_modal: Control = escritorio._ventanas["modal-prueba"]["panel"]
	_comprobar(
		is_instance_valid(foco) and panel_modal.is_ancestor_of(foco),
		"el foco recuperado queda atrapado dentro de la modal",
	)
	escritorio.cerrar("modal-prueba")
	await process_frame

	# Al minimizar la última ventana, el foco que vivía dentro queda oculto. La
	# reparación automática debe dejar un control visible desde el que el mando
	# pueda seguir navegando hasta «Cerrar sesión».
	escritorio.minimizar("prueba")
	await process_frame
	foco = root.gui_get_focus_owner()
	_comprobar(
		is_instance_valid(foco) and foco.name == "BotonMenu",
		"minimizar la última ventana deja foco visible en el menú",
	)

	_liberar_foco()
	var movimiento := InputEventMouseMotion.new()
	_comprobar(
		not escritorio.recuperar_foco(movimiento),
		"el movimiento del ratón no cambia el foco de teclado/mando",
	)

	_liberar_foco()
	root.remove_child(escritorio)
	escritorio.free()


func _probar_salida_menu_global() -> void:
	var controlador := CONTROLADOR_ESCRITORIO_SCRIPT.new()
	# Esta regresión prueba la integración del botón, no el wrapping del puesto.
	# Evitamos que _process() consulte un Dia real y ejercitamos directamente el
	# contrato aislado que debe seguir disponible aunque OS98 haya perdido foco.
	controlador.set_process(false)
	root.add_child(controlador)
	await process_frame

	var boton: Button = controlador._boton_salida_menu_global
	_comprobar(is_instance_valid(boton), "el menú global recibe la salida de rescate")
	if not is_instance_valid(boton):
		root.remove_child(controlador)
		controlador.free()
		return

	_comprobar(not boton.visible, "la salida de rescate se oculta fuera de SIGA")
	_comprobar(
		boton.focus_mode != Control.FOCUS_NONE,
		"la salida de rescate participa en navegación de teclado/mando",
	)
	var menu := root.get_node_or_null("MenuGlobal")
	var salir: Button = menu.get("_salir") if menu != null else null
	_comprobar(
		is_instance_valid(salir) and boton.get_parent() == salir.get_parent(),
		"la salida usa el mismo recorrido del menú global",
	)

	controlador._actualizar_salida_menu_global(true)
	_comprobar(boton.visible, "la salida aparece mientras SIGA está activo")
	controlador._actualizar_salida_menu_global(false)
	_comprobar(not boton.visible, "la salida vuelve a ocultarse al dejar el puesto")

	root.remove_child(controlador)
	controlador.free()
	await process_frame
	_comprobar(
		not is_instance_valid(boton),
		"el controlador limpia la extensión del menú al abandonar la escena",
	)


func _crear_contenido_prueba() -> Control:
	var caja := VBoxContainer.new()
	var boton := Button.new()
	boton.name = "BotonContenidoPrueba"
	boton.text = "Contenido"
	caja.add_child(boton)
	return caja


func _raton(boton: MouseButton, pulsado: bool = true) -> InputEventMouseButton:
	var evento := InputEventMouseButton.new()
	evento.button_index = boton
	evento.pressed = pulsado
	return evento


func _accion(nombre: StringName) -> InputEventAction:
	var evento := InputEventAction.new()
	evento.action = nombre
	evento.pressed = true
	return evento


func _liberar_foco() -> void:
	var foco := root.gui_get_focus_owner()
	if is_instance_valid(foco):
		foco.release_focus()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #793: " + nombre)
