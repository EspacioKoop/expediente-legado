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
var _tipo := ""
var _perfil: Dictionary = {}

var _area: Control
var _objetivo: ColorRect
var _cursor: ColorRect
var _racha: ProgressBar
var _confirmar: Button


static func centro_para(tipo: String, ronda: int, rival_id: String) -> float:
	var clave := "%s|%s" % [tipo, rival_id]
	var suma := ronda * 17
	for i in clave.length():
		suma += clave.unicode_at(i) * (i + 1)
	var unidad := float(posmod(suma, 1001)) / 1000.0
	return lerpf(0.26, 0.74, unidad)


static func perfil_para(tipo: String) -> Dictionary:
	match tipo:
		"objecion":
			return {
				"periodo": 0.56,
				"perfecta": 0.055,
				"buena": 0.13,
				"avance_perfecto": 2,
				"mantiene_bien": false,
				"cursor": 3.0,
			}
		"silencio":
			return {
				"periodo": 0.92,
				"perfecta": 0.105,
				"buena": 0.24,
				"avance_perfecto": 1,
				"mantiene_bien": false,
				"cursor": 7.0,
			}
		_:
			return {
				"periodo": 0.70,
				"perfecta": 0.075,
				"buena": 0.17,
				"avance_perfecto": 1,
				"mantiene_bien": true,
				"cursor": 4.0,
			}


static func posicion_para(segundos: float, periodo := PERIODO_SEGUNDOS) -> float:
	var fase := fposmod(maxf(0.0, segundos) / maxf(0.01, periodo), 2.0)
	return fase if fase <= 1.0 else 2.0 - fase


static func calidad_para(
	posicion: float,
	centro: float,
	reduccion_movimiento := false,
	media_perfecta := MEDIA_VENTANA_PERFECTA,
	media_buena := MEDIA_VENTANA_BUENA
) -> String:
	if reduccion_movimiento:
		return "perfecto"
	var distancia := absf(clampf(posicion, 0.0, 1.0) - clampf(centro, 0.0, 1.0))
	if distancia <= media_perfecta:
		return "perfecto"
	if distancia <= media_buena:
		return "bien"
	return "normal"


static func calidad_de(
	tipo: String, posicion: float, centro: float, reduccion_movimiento := false
) -> String:
	var perfil := perfil_para(tipo)
	return calidad_para(
		posicion,
		centro,
		reduccion_movimiento,
		float(perfil["perfecta"]),
		float(perfil["buena"]),
	)


static func racha_siguiente(
	actual: int, calidad: String, avance_perfecto := 1, mantiene_bien := false
) -> int:
	if calidad == "bien" and mantiene_bien:
		return maxi(0, actual)
	if calidad != "perfecto":
		return 0
	return mini(META_INICIATIVA, maxi(0, actual) + maxi(1, avance_perfecto))


static func racha_de(tipo: String, actual: int, calidad: String) -> int:
	var perfil := perfil_para(tipo)
	return racha_siguiente(
		actual,
		calidad,
		int(perfil["avance_perfecto"]),
		bool(perfil["mantiene_bien"]),
	)


static func iniciativa_lista(racha: int) -> bool:
	return racha >= META_INICIATIVA


static func aplicar_iniciativa(
	combate: Dictionary,
	ronda: Dictionary,
	racha: int,
	calidad: String,
	azar: Callable,
	tipo := ""
) -> int:
	var nueva := racha_de(tipo, racha, calidad) if not tipo.is_empty() else racha_siguiente(
		racha, calidad
	)
	if not iniciativa_lista(nueva):
		return nueva
	if bool(ronda.get("terminado", false)):
		return 0
	if int(combate.get("revelada", -1)) >= 0:
		return META_INICIATIVA - 1
	var indice := (
		Prometeo
		. jugada_rival(
			String(combate["modo"]),
			int(combate["ronda"]),
			Combate.TIPOS.size(),
			azar,
			int(combate["ultima_jugada_jugador"]),
		)
	)
	combate["revelada"] = indice
	ronda["revelada"] = Combate.etiqueta(Combate.TIPOS[indice])
	return 0


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
	_tipo = tipo
	_perfil = perfil_para(tipo)
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
	var periodo := float(_perfil.get("periodo", PERIODO_SEGUNDOS))
	var posicion := _centro if _reduccion_movimiento else posicion_para(_tiempo, periodo)
	_resolver(calidad_de(_tipo, posicion, _centro, _reduccion_movimiento))


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
	var media_perfecta := float(_perfil.get("perfecta", MEDIA_VENTANA_PERFECTA))
	var ancho_objetivo := ancho * media_perfecta * 2.0
	_objetivo.position = Vector2(_centro * ancho - ancho_objetivo * 0.5, 0.0)
	_objetivo.size = Vector2(ancho_objetivo, alto)
	var periodo := float(_perfil.get("periodo", PERIODO_SEGUNDOS))
	var posicion := _centro if _reduccion_movimiento else posicion_para(_tiempo, periodo)
	var grosor := float(_perfil.get("cursor", 4.0))
	_cursor.position = Vector2(
		clampf(posicion * ancho - grosor * 0.5, 0.0, ancho - grosor),
		0.0,
	)
	_cursor.size = Vector2(grosor, alto)
