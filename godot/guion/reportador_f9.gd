## Acceso global al Parte de incidencias mediante F9 (#1460).
##
## Vive como autoload para que el tester pueda reportar desde cualquier escena,
## incluso si el juego ya está pausado por otra superficie. Preserva pausa,
## foco y modo del ratón al cerrar.
extends CanvasLayer

var _fondo: ColorRect
var _app: ParteIncidenciasApp
var _pausa_previa := false
var _mouse_previo := Input.MOUSE_MODE_VISIBLE
var _foco_previo: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1000
	_montar()


func _input(evento: InputEvent) -> void:
	if evento is InputEventKey:
		var tecla := evento as InputEventKey
		if (
			tecla.pressed
			and not tecla.echo
			and (tecla.keycode == KEY_F9 or tecla.physical_keycode == KEY_F9)
		):
			if _fondo.visible:
				_cerrar()
			else:
				_abrir()
			get_viewport().set_input_as_handled()
			return

	if _fondo.visible and evento.is_action_pressed("cancelar"):
		_cerrar()
		get_viewport().set_input_as_handled()


func _montar() -> void:
	_fondo = ColorRect.new()
	_fondo.name = "FondoReportadorF9"
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.color = EstiloJuego.VELO
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_fondo.visible = false
	add_child(_fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.add_child(centro)

	_app = ParteIncidenciasApp.new()
	_app.volver.connect(_cerrar)
	centro.add_child(_app)


func _abrir() -> void:
	if _fondo.visible:
		return
	_pausa_previa = get_tree().paused
	_mouse_previo = Input.mouse_mode
	_foco_previo = get_viewport().gui_get_focus_owner()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_fondo.visible = true
	# Desde F9 el diagnóstico técnico queda preactivado y visible. La persona
	# tester puede desmarcarlo antes de enviar.
	_app.abrir(PreferenciasSiga.cargar(), true)


func _cerrar() -> void:
	if not _fondo.visible:
		return
	_app.visible = false
	_fondo.visible = false
	get_tree().paused = _pausa_previa
	Input.mouse_mode = _mouse_previo
	if is_instance_valid(_foco_previo) and _foco_previo.is_inside_tree():
		_foco_previo.grab_focus()
	_foco_previo = null
