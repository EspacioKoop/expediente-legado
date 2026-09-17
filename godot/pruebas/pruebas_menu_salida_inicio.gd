extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	process_frame.connect(_esperar_integracion, CONNECT_ONE_SHOT)


func _esperar_integracion() -> void:
	process_frame.connect(_ejecutar, CONNECT_ONE_SHOT)


func _ejecutar() -> void:
	var menu := root.get_node_or_null("MenuGlobal")
	var extension := root.get_node_or_null("MenuSalidaInicio")
	_comprobar(menu != null, "MenuGlobal sigue cargado")
	_comprobar(extension != null, "la extensión de salida está cargada")
	if menu == null or extension == null:
		_finalizar()
		return

	var boton := menu.find_child("VolverInicio", true, false) as Button
	var aviso := menu.find_child("AvisoVolverInicio", true, false) as Label
	var confirmar := menu.find_child("ConfirmarVolverInicio", true, false) as ConfirmationDialog
	_comprobar(boton != null, "el menú contiene Volver al menú de inicio")
	_comprobar(aviso != null, "el menú contiene un aviso de fallo de guardado")
	_comprobar(confirmar != null, "el menú contiene confirmación")
	if boton == null or aviso == null or confirmar == null:
		_finalizar()
		return

	var salir := menu.get("_salir") as Button
	_comprobar(salir != null, "se conserva Salir al escritorio")
	if salir != null:
		_comprobar(boton.get_parent() == salir.get_parent(), "ambas salidas comparten navegación")
		_comprobar(boton.get_index() < salir.get_index(), "volver al inicio aparece antes de cerrar")
	_comprobar(not boton.visible, "fuera de una partida no se ofrece volver al inicio")
	_comprobar(boton.accessibility_name == boton.text, "el botón tiene nombre accesible")
	_comprobar(
		confirmar.get_cancel_button().text == tr("MENU_GLOBAL_CONTINUAR"),
		"cancelar la confirmación conserva la partida"
	)
	_finalizar()


func _finalizar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO MenuSalidaInicio: " + nombre)
