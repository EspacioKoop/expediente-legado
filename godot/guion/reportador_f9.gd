## Acceso global al Parte de incidencias mediante F9 (#1460).
##
## Vive como autoload para que el tester pueda reportar desde cualquier escena,
## incluso si el juego ya está pausado por otra superficie. Preserva pausa,
## foco y modo del ratón al cerrar.
extends CanvasLayer

# Muestreo circular acotado: ninguna serie temporal llega al informe o a disco.
const INTERVALO_MUESTRA := 0.5
const MAX_MUESTRAS := 12

var _acumulado_muestra := 0.0
var _muestras_rendimiento: Array[Dictionary] = []
var _escena_muestreada := ""
var _fondo: ColorRect
var _app: ParteIncidenciasApp
var _pausa_previa := false
var _mouse_previo := Input.MOUSE_MODE_VISIBLE
var _foco_previo: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1000
	_montar()


func _process(delta: float) -> void:
	if get_tree().paused or _fondo.visible:
		return
	_sincronizar_escena()
	_acumulado_muestra += delta
	if _acumulado_muestra < INTERVALO_MUESTRA:
		return
	_acumulado_muestra = fposmod(_acumulado_muestra, INTERVALO_MUESTRA)
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	var dibujos := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	_agregar_muestra(fps, dibujos)


## Al cambiar de escena no mezclar frames de oficina, calle, casa y sueño.
func _sincronizar_escena() -> void:
	var actual := get_tree().current_scene
	_registrar_escena(actual.scene_file_path if actual != null else "")


func _registrar_escena(ruta: String) -> void:
	if ruta == _escena_muestreada:
		return
	_escena_muestreada = ruta
	_muestras_rendimiento.clear()
	_acumulado_muestra = 0.0


## Los tests pueden proporcionar mediciones sintéticas sin un renderizador GPU.
func _agregar_muestra(fps: float, dibujos: float) -> void:
	if not is_finite(fps) or not is_finite(dibujos) or fps <= 0.0 or dibujos < 0.0:
		return
	_muestras_rendimiento.append(
		{"fps": clampi(roundi(fps), 1, 240), "dibujos": clampi(roundi(dibujos), 0, 100000)}
	)
	while _muestras_rendimiento.size() > MAX_MUESTRAS:
		_muestras_rendimiento.pop_front()


func _resumen_rendimiento() -> Dictionary:
	if _muestras_rendimiento.is_empty():
		return {}
	var total_fps := 0
	var minimo_fps := 240
	var max_dibujos := 0
	for muestra in _muestras_rendimiento:
		var fps: int = muestra["fps"]
		total_fps += fps
		minimo_fps = mini(minimo_fps, fps)
		max_dibujos = maxi(max_dibujos, int(muestra["dibujos"]))
	return {
		"fps_media": roundi(float(total_fps) / _muestras_rendimiento.size()),
		"fps_min": minimo_fps,
		"draw_calls_max": max_dibujos,
		"muestras": _muestras_rendimiento.size(),
	}


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
	_sincronizar_escena()
	_pausa_previa = get_tree().paused
	_mouse_previo = Input.mouse_mode
	_foco_previo = get_viewport().gui_get_focus_owner()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_fondo.visible = true
	# Desde F9 el diagnóstico técnico queda preactivado y visible. La persona
	# tester puede desmarcarlo antes de enviar.
	_app.abrir(PreferenciasSiga.cargar(), true, _resumen_rendimiento())


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
