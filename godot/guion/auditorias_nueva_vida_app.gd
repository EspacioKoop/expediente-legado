## Oferta de condición antes de una reincorporación (#152).
##
## Solo captura la intención. No conoce guardado, Jornada ni reglas de dominio:
## Dia aplica la selección y no abre la vida hasta persistirla.
class_name AuditoriasNuevaVidaApp
extends Control

signal seleccion_confirmada(seleccion: Array)

var _selector: AuditoriasSiga
var _continuar: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = EstiloSiga.tema()
	_montar()


func abrir(estado_partida: Dictionary) -> void:
	if _selector != null:
		_selector.configurar_estado(estado_partida, true)
	visible = true
	if _continuar != null:
		_continuar.call_deferred("grab_focus")


func _montar() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.0, 0.0, 0.0, 0.78)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 360)
	centro.add_child(panel)

	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	panel.add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 12)
	margen.add_child(raiz)

	var titulo := Label.new()
	titulo.text = tr("AUDITORIAS_NUEVA_VIDA_TITULO")
	titulo.add_theme_font_size_override("font_size", 18)
	raiz.add_child(titulo)

	var ayuda := Label.new()
	ayuda.text = tr("AUDITORIAS_NUEVA_VIDA_AYUDA")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(ayuda)

	_selector = AuditoriasSiga.new()
	_selector.name = "SelectorAuditorias"
	raiz.add_child(_selector)

	_continuar = Button.new()
	_continuar.name = "Continuar"
	_continuar.text = tr("AUDITORIAS_NUEVA_VIDA_CONTINUAR")
	_continuar.pressed.connect(_confirmar)
	raiz.add_child(_continuar)


func _confirmar() -> void:
	seleccion_confirmada.emit(_selector.seleccion())
