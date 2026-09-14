## La pantalla de un combate onírico (#88).
##
## Lo que se ve cuando te acercas a alguien a quien firmaste. El motor es
## `Combate` y las consecuencias son de `SuenoCombate`: aquí no se decide nada,
## solo se pinta y se cuenta.
##
## **No lleva la chapa del SIGA.** El expediente y la Ventanilla son ventanas de
## una aplicación de 1998 porque son eso; un sueño no tiene barra de título. Lo
## que hay es texto sobre lo que ya estaba, medio tapado: sigues dentro de la
## sala mientras discutes.
class_name SuenoDuelo
extends Control

## Se emite al cerrar, con lo que devolvió `SuenoCombate.resolver`: quien abrió
## la pantalla es quien sabe qué hacer con la jornada después.
signal terminado(gano: bool)

## Contra quién, en el formato que deja `SuenoContenido.fuentes`: id, nombre,
## acusado y sus réplicas.
var figura: Dictionary = {}

## Las cargas de habilidad de la partida (`Historias.cargas`).
var cargas: Dictionary = {}

var _combate: Dictionary = {}
var _azar := RandomNumberGenerator.new()
var _gano := false

var _cronica: Label
var _replica: Label
var _marcador: Label
var _botones: HBoxContainer
var _habilidades: HBoxContainer
var _habilidad_eje := ""


func _ready() -> void:
	_azar.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_combate = SuenoCombate.nuevo(figura, cargas)
	_construir()
	_cronica.text = tr("SUENO_DUELO_SE_QUEDA") % figura.get("nombre", "")
	_pintar_habilidades()
	_actualizar_marcador()


func _al_jugar(tipo: String) -> void:
	if _combate.is_empty() or _combate["terminado"]:
		return
	var ronda := Combate.jugar(_combate, tipo, _habilidad_eje, _tirada())
	_habilidad_eje = ""

	_cronica.text = (
		tr("COMBATE_CRONICA")
		% [
			Combate.etiqueta(ronda["tipo_jugador"]),
			figura.get("nombre", ""),
			Combate.etiqueta(ronda["tipo_rival"]),
			_veredicto(ronda["veredicto"])
		]
	)
	if not ronda["revelada"].is_empty():
		_cronica.text += "\n" + tr("VENTANILLA_ADELANTA") % ronda["revelada"]
	_replica.text = (
		tr("CAREO_REPLICA") % ronda["replica"] if not ronda["replica"].is_empty() else ""
	)

	_pintar_habilidades()
	_actualizar_marcador()

	if ronda["terminado"]:
		_cerrar(ronda["ganador"] == "jugador")


## El final NO se cobra aquí: se dice. Quien cobra es quien tiene el estado y
## la jornada delante, y eso es la pantalla del día.
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


func _veredicto(cual: String) -> String:
	match cual:
		"gana_jugador":
			return tr("CAREO_VEREDICTO_JUGADOR")
		"gana_rival":
			return tr("CAREO_VEREDICTO_RIVAL")
		_:
			return tr("VEREDICTO_EMPATE")


func _tirada() -> Callable:
	return func(): return _azar.randf()


func _actualizar_marcador() -> void:
	_marcador.text = (
		tr("COMBATE_VIDAS")
		% [
			_barra(_combate["vida_jugador"]),
			_combate["vida_jugador"],
			figura.get("nombre", ""),
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


# --- Las cajas --------------------------------------------------------------


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Medio tapado a propósito: la sala se sigue viendo detrás. Un panel opaco
	# sacaría al jugador del sitio, y el sitio es la mitad de lo que pasa.
	fondo.color = Color(0.04, 0.03, 0.06, 0.72)
	add_child(fondo)

	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caja.offset_left = 24
	caja.offset_right = -24
	caja.offset_top = -220
	caja.offset_bottom = -24
	caja.add_theme_constant_override("separation", 8)
	add_child(caja)

	_marcador = _etiqueta("")
	caja.add_child(_marcador)
	_replica = _etiqueta("")
	caja.add_child(_replica)
	_cronica = _etiqueta("")
	_cronica.custom_minimum_size.y = 56
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
	return marca
