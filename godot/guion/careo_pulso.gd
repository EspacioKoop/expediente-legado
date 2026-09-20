## Comando de acción de la Ventanilla (#1114).
##
## La estrategia sigue perteneciendo a Combate: aquí solo se ejecuta físicamente
## la jugada ya elegida. El cursor va y vuelve sobre una ventana determinista.
## Fallar nunca cambia la jugada; dos ejecuciones perfectas seguidas conceden
## iniciativa a la capa anfitriona.
class_name CareoPulso
extends VBoxContainer

signal confirmado(calidad: String)

const PERIODO_SEGUNDOS := 0.72
const ESPERA_MAXIMA := 2.40
const MEDIA_VENTANA_PERFECTA := 0.075
const MEDIA_VENTANA_BUENA := 0.18
const META_INICIATIVA := 2

var _activo := false
var _reduccion_movimiento := false
var _tiempo := 0.0
var _centro := 0.5

var _area: Control
var _objetivo: ColorRect
var _cursor: ColorRect
var _racha: ProgressBar
var _confirmar: Button


static func centro_para(tipo: String, ronda: int, rival_id: String) -> float:
	var clave := "%s|%d|%s" % [tipo, ronda, rival_id]
	var unidad := float(posmod(hash(clave), 1001)) / 1000.0
	return lerpf(0.26, 0.74, unidad)


static func posicion_para(segundos: float) -> float:
	var fase := fposmod(maxf(0.0, segundos) / PERIODO_SEGUNDOS, 2.0)
	return fase if fase <= 1.0 else 2.0 - fase


static func calidad_para(posicion: float, centro: float, reduccion_movimiento := false) -> String:
	if reduccion_movimiento:
		return "perfecto"
	var distancia := absf(clampf(posicion, 0.0, 1.0) - clampf(centro, 0.0, 1.0))
	if distancia <= MEDIA_VENTANA_PERFECTA:
		return "perfecto"
	if distancia <= MEDIA_VENTANA_BUENA:
		return "bien"
	return "normal"


static func racha_siguiente(actual: int, calidad: String) -> int:
	if calidad != "perfecto":
		return 0
	return mini(META_INICIATIVA, maxi(0, actual) + 1)


static func iniciativa_lista(racha: int) -> bool:
	return racha >= META_INICIATIVA


func _ready() -> void:
	add_theme_constant_override("separation", 4)

	_area = Control.new()
	_area.custom_minimum_size = Vector2(0.0, 24.0)
	_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_area)

	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = EstiloSiga.GRIS_OSCURO
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(fondo)

	_objetivo = ColorRect.new()
	_objetivo.color = EstiloSiga.BLANCO
	_objetivo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_objetivo)

	_cursor = ColorRect.new()
	_cursor.color = EstiloSiga.AZUL_TITULO
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_cursor)

	_racha = ProgressBar.new()
	_racha.max_value = META_INICIATIVA
	_racha.show_percentage = false
	_racha.custom_minimum_size.y = 5.0
	add_child(_racha)

	_confirmar = Button.new()
	_confirmar.pressed.connect(_confirmar_actual)
	add_child(_confirmar)

	visible = false
	set_process(false)


func armar(tipo: String, ronda: int, rival_id: String, reduccion: bool, racha: int) -> void:
	_centro = centro_para(tipo, ronda, rival_id)
	_reduccion_movimiento = reduccion
	_tiempo = 0.0
	_activo = true
	_racha.value = clampi(racha, 0, META_INICIATIVA)
	_confirmar.text = Combate.etiqueta(tipo)
	visible = true
	set_process(true)
	_actualizar_visual()
	_confirmar.grab_focus()


func cancelar() -> void:
	_activo = false
	visible = false
	set_process(false)


func activo() -> bool:
	return _activo


func _process(delta: float) -> void:
	if not _activo:
		return
	if not _reduccion_movimiento:
		_tiempo += delta
		if _tiempo >= ESPERA_MAXIMA:
			_resolver("normal")
			return
	_actualizar_visual()


func _unhandled_input(evento: InputEvent) -> void:
	if not _activo:
		return
	if evento.is_action_pressed("interactuar") or evento.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirmar_actual()


func _confirmar_actual() -> void:
	if not _activo:
		return
	var posicion := _centro if _reduccion_movimiento else posicion_para(_tiempo)
	_resolver(calidad_para(posicion, _centro, _reduccion_movimiento))


func _resolver(calidad: String) -> void:
	if not _activo:
		return
	_activo = false
	visible = false
	set_process(false)
	confirmado.emit(calidad)


func _actualizar_visual() -> void:
	if _area == null or _objetivo == null or _cursor == null:
		return
	var ancho := maxf(1.0, _area.size.x)
	var alto := maxf(1.0, _area.size.y)
	var ancho_objetivo := ancho * MEDIA_VENTANA_PERFECTA * 2.0
	_objetivo.position = Vector2(_centro * ancho - ancho_objetivo * 0.5, 0.0)
	_objetivo.size = Vector2(ancho_objetivo, alto)
	var posicion := _centro if _reduccion_movimiento else posicion_para(_tiempo)
	_cursor.position = Vector2(clampf(posicion * ancho - 2.0, 0.0, ancho - 4.0), 0.0)
	_cursor.size = Vector2(4.0, alto)
