## Extensión del menú global para volver al inicio sin cerrar el juego (#788).
##
## Se monta después de MenuGlobal para no duplicar su modal, foco ni navegación.
## El botón usa el mismo VBox que «Salir al escritorio», por lo que entra en el
## recorrido nativo de teclado/mando. Antes de cambiar de escena delega el
## guardado en SalidaPartida; un fallo mantiene la partida abierta y lo anuncia.
extends Node

const RUTA_DIA := "res://escenas/dia.tscn"
const RUTA_INICIO := "res://escenas/inicio.tscn"

var _boton: Button
var _aviso: Label
var _confirmacion: ConfirmationDialog
var _visible_en_partida := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_integrar")


func _process(_delta: float) -> void:
	if _boton == null:
		return
	var en_partida := _en_partida()
	if en_partida == _visible_en_partida:
		return
	_visible_en_partida = en_partida
	_boton.visible = en_partida
	_aviso.visible = en_partida
	if not en_partida:
		_aviso.text = ""
		if _confirmacion.visible:
			_confirmacion.hide()


func _integrar() -> void:
	if _boton != null:
		return
	var salir := MenuGlobal.get("_salir") as Button
	if salir == null:
		call_deferred("_integrar")
		return
	var caja := salir.get_parent() as VBoxContainer
	if caja == null:
		return

	_boton = Button.new()
	_boton.name = "VolverInicio"
	_boton.text = "%s → %s" % [tr("MENU_GLOBAL_VOLVER"), tr("NAVEGADOR_INICIO")]
	_boton.tooltip_text = tr("INICIO_TITULO")
	_boton.accessibility_name = _boton.text
	_boton.pressed.connect(_pedir_confirmacion)
	caja.add_child(_boton)
	caja.move_child(_boton, salir.get_index())

	_aviso = Label.new()
	_aviso.name = "AvisoVolverInicio"
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.accessibility_live = AccessibilityServer.LIVE_ASSERTIVE
	caja.add_child(_aviso)
	caja.move_child(_aviso, salir.get_index())

	_confirmacion = ConfirmationDialog.new()
	_confirmacion.name = "ConfirmarVolverInicio"
	_confirmacion.title = tr("INICIO_TITULO")
	_confirmacion.ok_button_text = tr("MENU_GLOBAL_VOLVER")
	_confirmacion.confirmed.connect(_volver_al_inicio)
	MenuGlobal.add_child(_confirmacion)
	_confirmacion.get_cancel_button().text = tr("MENU_GLOBAL_CONTINUAR")
	_refrescar_visibilidad_inicial()


func _refrescar_visibilidad_inicial() -> void:
	_visible_en_partida = _en_partida()
	_boton.visible = _visible_en_partida
	_aviso.visible = _visible_en_partida


func _pedir_confirmacion() -> void:
	if not _en_partida():
		return
	_aviso.text = ""
	_confirmacion.dialog_text = "%s?\n%s" % [_boton.text, tr("INICIO_TITULO")]
	_confirmacion.popup_centered()
	_confirmacion.get_cancel_button().grab_focus.call_deferred()


func _volver_al_inicio() -> void:
	var escena := get_tree().current_scene
	if escena == null or escena.scene_file_path != RUTA_DIA:
		return
	var resultado := SalidaPartida.guardar_desde(escena)
	if not bool(resultado.get("ok", false)):
		_aviso.text = tr("ARCHIVO_ERROR_GUARDAR")
		_boton.grab_focus.call_deferred()
		return

	MenuGlobal.call("_cerrar")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(RUTA_INICIO)


func _en_partida() -> bool:
	var escena := get_tree().current_scene
	return escena != null and escena.scene_file_path == RUTA_DIA
