## Presentación mínima y accesible de la confrontación con Hastur (#1103).
##
## No decide reglas: pide jugadas al controller y vuelve a pintar el Dictionary
## persistente que gobierna ClimaxHastur. No hay animaciones, de modo que la
## preferencia de movimiento reducido se respeta de forma natural.
class_name ClimaxHasturPanel
extends Control

signal jugada_solicitada(tipo: String, habilidad: String)
signal continuar_solicitado()

var estado_climax: Dictionary = {}

var _cronica: Label
var _replica: Label
var _marcador: Label
var _botones: HBoxContainer
var _habilidades: HBoxContainer
var _caja: VBoxContainer
var _habilidad_eje := ""
var _continuar: Button
var _fin_mostrado := false


func configurar(estado: Dictionary) -> void:
	estado_climax = estado


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_construir()
	refrescar({})


func refrescar(ronda: Dictionary = {}) -> void:
	var combate := _combate()
	if combate.is_empty():
		return

	if not ronda.is_empty():
		_cronica.text = (
			tr("COMBATE_CRONICA")
			% [
				Combate.etiqueta(String(ronda.get("tipo_jugador", ""))),
				"Hastur",
				Combate.etiqueta(String(ronda.get("tipo_rival", ""))),
				_veredicto(String(ronda.get("veredicto", ""))),
			]
		)
		var revelada := String(ronda.get("revelada", ""))
		if not revelada.is_empty():
			_cronica.text += "\n" + tr("VENTANILLA_ADELANTA") % revelada
		var replica := String(ronda.get("replica", ""))
		_replica.text = tr("CAREO_REPLICA") % replica if not replica.is_empty() else ""

	_actualizar_marcador()
	_pintar_habilidades()

	var fase := String(estado_climax.get("fase", ""))
	if fase == ClimaxHastur.FASE_VICTORIA:
		_mostrar_fin(true)
	elif fase == ClimaxHastur.FASE_DERROTA:
		_mostrar_fin(false)


func bloquear(bloqueado: bool) -> void:
	for boton in _botones.get_children():
		if boton is Button:
			(boton as Button).disabled = bloqueado
	for boton in _habilidades.get_children():
		if boton is Button:
			(boton as Button).disabled = bloqueado
	if is_instance_valid(_continuar):
		_continuar.disabled = bloqueado


func _al_jugar(tipo: String) -> void:
	if String(estado_climax.get("fase", "")) != ClimaxHastur.FASE_COMBATE:
		return
	var habilidad := _habilidad_eje
	_habilidad_eje = ""
	jugada_solicitada.emit(tipo, habilidad)


func _al_continuar() -> void:
	if is_instance_valid(_continuar):
		_continuar.disabled = true
	continuar_solicitado.emit()


func _veredicto(cual: String) -> String:
	match cual:
		"gana_jugador":
			return tr("CAREO_VEREDICTO_JUGADOR")
		"gana_rival":
			return tr("CAREO_VEREDICTO_RIVAL")
		_:
			return tr("VEREDICTO_EMPATE")


func _actualizar_marcador() -> void:
	var combate := _combate()
	if combate.is_empty():
		return
	_marcador.text = (
		tr("COMBATE_VIDAS")
		% [
			_barra(int(combate.get("vida_jugador", 0))),
			int(combate.get("vida_jugador", 0)),
			"Hastur",
			_barra(int(combate.get("vida_rival", 0))),
			int(combate.get("vida_rival", 0)),
		]
	)


func _barra(vidas: int) -> String:
	return "█".repeat(maxi(0, vidas)) + "░".repeat(maxi(0, Combate.VIDA_INICIAL - vidas))


func _pintar_habilidades() -> void:
	for hijo in _habilidades.get_children():
		hijo.queue_free()
	if String(estado_climax.get("fase", "")) != ClimaxHastur.FASE_COMBATE:
		return

	var combate := _combate()
	for eje in Combate.cargas_disponibles(combate):
		var habilidad: Dictionary = Historias.HABILIDADES[eje]
		var boton := Button.new()
		boton.theme = EstiloSiga.tema()
		boton.text = (
			tr("VENTANILLA_HABILIDAD")
			% [
				tr(habilidad["nombre"]),
				int(combate["cargas"][eje]),
			]
		)
		boton.tooltip_text = tr(habilidad["efecto"])
		boton.accessibility_name = boton.text
		boton.toggle_mode = true
		boton.pressed.connect(
			func():
				_habilidad_eje = eje if boton.button_pressed else ""
				for otro in _habilidades.get_children():
					if otro != boton:
						otro.button_pressed = false
		)
		_habilidades.add_child(boton)


func _mostrar_fin(gano: bool) -> void:
	if _fin_mostrado:
		return
	_fin_mostrado = true
	_botones.visible = false
	_habilidades.visible = false
	_cronica.text += "\n\n" + tr("SUENO_DUELO_GANADO" if gano else "SUENO_DUELO_PERDIDO")

	_continuar = Button.new()
	_continuar.theme = EstiloSiga.tema()
	_continuar.text = tr("SUENO_DUELO_SEGUIR")
	_continuar.accessibility_name = _continuar.text
	_continuar.pressed.connect(_al_continuar)
	_caja.add_child(_continuar)
	_continuar.grab_focus()


func _combate() -> Dictionary:
	var bruto = estado_climax.get("combate", {})
	return bruto if typeof(bruto) == TYPE_DICTIONARY else {}


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.04, 0.03, 0.06, 0.82)
	add_child(fondo)

	_caja = VBoxContainer.new()
	_caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_caja.position = Vector2(-360, -150)
	_caja.custom_minimum_size = Vector2(720, 300)
	_caja.add_theme_constant_override("separation", 8)
	add_child(_caja)

	_marcador = _etiqueta("")
	_caja.add_child(_marcador)
	_replica = _etiqueta("")
	_caja.add_child(_replica)
	_cronica = _etiqueta("Hastur")
	_cronica.custom_minimum_size.y = 70
	_cronica.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_caja.add_child(_cronica)

	_habilidades = HBoxContainer.new()
	_caja.add_child(_habilidades)

	_botones = HBoxContainer.new()
	_caja.add_child(_botones)
	for tipo in Combate.TIPOS:
		var boton := Button.new()
		boton.theme = EstiloSiga.tema()
		boton.text = Combate.etiqueta(tipo)
		boton.accessibility_name = boton.text
		boton.pressed.connect(_al_jugar.bind(tipo))
		_botones.add_child(boton)

	if _botones.get_child_count() > 0:
		(_botones.get_child(0) as Button).grab_focus()


func _etiqueta(texto: String) -> Label:
	var marca := Label.new()
	marca.text = texto
	marca.theme = EstiloSiga.tema()
	marca.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	marca.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	marca.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	marca.add_theme_constant_override("outline_size", 4)
	return marca
