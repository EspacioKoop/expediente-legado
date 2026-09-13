## Duelo ocasional de la ventanilla de alquiler (#85).
##
## Reutiliza `Combate` en modo reactiva, como la Ventanilla de Reclamaciones,
## pero no resuelve economía ni vivienda. Al terminar emite el resultado y el
## día, que posee la jornada, aplica `AlquilerDueloReglas`.
class_name AlquilerDuelo
extends Control

signal terminado(gano: bool)

var raiz := 0
var vuelta := 1
var dia := 1
var cargas: Dictionary = {}

var _combate: Dictionary = {}
var _azar := RandomNumberGenerator.new()
var _rival: Dictionary = {}
var _gano := false
var _habilidad_eje := ""

var _cronica: Label
var _replica: Label
var _marcador: Label
var _botones: HBoxContainer
var _habilidades: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rival = Ventanilla.DE_OFICIO.duplicate(true)
	_azar.seed = Azar.derivar(raiz, "combate", [vuelta, dia, AlquilerDueloReglas.INDICE_EVENTO])
	_combate = Combate.nuevo("reactiva", _rival, cargas)
	_construir()
	_cronica.text = tr("VENTANILLA_SE_PRESENTA") % tr(_rival["nombre"])
	_pintar_habilidades()
	_actualizar_marcador()
	call_deferred("_enfocar_primero")


func _enfocar_primero() -> void:
	if _botones != null and _botones.get_child_count() > 0:
		_botones.get_child(0).grab_focus()


func _al_jugar(tipo: String) -> void:
	if _combate.is_empty() or _combate["terminado"]:
		return
	var ronda := Combate.jugar(_combate, tipo, _habilidad_eje, _tirada())
	_habilidad_eje = ""
	_cronica.text = (
		tr("COMBATE_CRONICA")
		% [
			Combate.etiqueta(ronda["tipo_jugador"]),
			tr(_rival["nombre"]),
			Combate.etiqueta(ronda["tipo_rival"]),
			_veredicto(ronda["veredicto"])
		]
	)
	if not ronda["revelada"].is_empty():
		_cronica.text += "\n" + tr("VENTANILLA_ADELANTA") % ronda["revelada"]
	_replica.text = (
		tr("CAREO_REPLICA") % tr(ronda["replica"])
		if not ronda["replica"].is_empty()
		else ""
	)
	_pintar_habilidades()
	_actualizar_marcador()
	if ronda["terminado"]:
		_cerrar(ronda["ganador"] == "jugador")


func _cerrar(gano: bool) -> void:
	_gano = gano
	_botones.visible = false
	_habilidades.visible = false
	_cronica.text += "\n\n" + tr("SUENO_DUELO_GANADO" if gano else "SUENO_DUELO_PERDIDO")
	var seguir := Button.new()
	seguir.theme = EstiloSiga.tema()
	seguir.text = tr("SUENO_DUELO_SEGUIR")
	seguir.pressed.connect(func(): terminado.emit(_gano))
	_botones.get_parent().add_child(seguir)
	seguir.grab_focus()


func _tirada() -> Callable:
	return func(): return _azar.randf()


func _veredicto(cual: String) -> String:
	match cual:
		"gana_jugador":
			return tr("CAREO_VEREDICTO_JUGADOR")
		"gana_rival":
			return tr("CAREO_VEREDICTO_RIVAL")
		_:
			return tr("VEREDICTO_EMPATE")


func _actualizar_marcador() -> void:
	_marcador.text = (
		tr("COMBATE_VIDAS")
		% [
			_barra(_combate["vida_jugador"]),
			_combate["vida_jugador"],
			tr(_rival["nombre"]),
			_barra(_combate["vida_rival"]),
			_combate["vida_rival"]
		]
	)


func _barra(vidas: int) -> String:
	return "█".repeat(maxi(0, vidas)) + "░".repeat(maxi(0, Combate.VIDA_INICIAL - vidas))


func _pintar_habilidades() -> void:
	for hijo in _habilidades.get_children():
		hijo.queue_free()
	for eje in Combate.cargas_disponibles(_combate):
		var habilidad: Dictionary = Historias.HABILIDADES[eje]
		var boton := Button.new()
		boton.theme = EstiloSiga.tema()
		boton.text = tr("VENTANILLA_HABILIDAD") % [tr(habilidad["nombre"]), _combate["cargas"][eje]]
		boton.tooltip_text = tr(habilidad["efecto"])
		boton.toggle_mode = true
		boton.pressed.connect(
			func():
				_habilidad_eje = eje if boton.button_pressed else ""
				for otro in _habilidades.get_children():
					if otro != boton:
						otro.button_pressed = false
		)
		_habilidades.add_child(boton)


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.04, 0.03, 0.06, 0.86)
	add_child(fondo)

	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caja.custom_minimum_size = Vector2(720, 330)
	caja.position -= caja.custom_minimum_size / 2.0
	caja.theme = EstiloSiga.tema()
	caja.add_theme_constant_override("separation", 10)
	add_child(caja)

	var titulo := _etiqueta(tr("VENTANILLA_TITULO"))
	caja.add_child(titulo)
	_marcador = _etiqueta("")
	caja.add_child(_marcador)
	_replica = _etiqueta("")
	_replica.custom_minimum_size.y = 52
	caja.add_child(_replica)
	_cronica = _etiqueta("")
	_cronica.custom_minimum_size.y = 74
	_cronica.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	caja.add_child(_cronica)

	_habilidades = HBoxContainer.new()
	caja.add_child(_habilidades)
	_botones = HBoxContainer.new()
	caja.add_child(_botones)
	for tipo in Combate.TIPOS:
		var boton := Button.new()
		boton.theme = EstiloSiga.tema()
		boton.text = Combate.etiqueta(tipo)
		boton.pressed.connect(_al_jugar.bind(tipo))
		_botones.add_child(boton)


func _etiqueta(texto: String) -> Label:
	var marca := Label.new()
	marca.text = texto
	marca.theme = EstiloSiga.tema()
	marca.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	marca.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	marca.add_theme_constant_override("outline_size", 4)
	marca.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return marca
