## Decisión de último recurso al llegar a cero vidas (#1205).
##
## Esta pantalla no decide reglas de Tarot: consulta la elegibilidad en
## Acusacion y emite la intención. El dueño aplica dominio y guardado.
class_name UltimoRecursoApp
extends Control

signal canje_solicitado(carta_id: String)
signal cese_solicitado

var _estado: Dictionary = {}
var _aviso: VBoxContainer
var _tarot: VBoxContainer
var _tarot_lista: VBoxContainer
var _ver_tarot: Button
var _firmar_cese: Button
var _volver: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = EstiloSiga.tema()
	_montar()


func abrir(estado: Dictionary) -> void:
	_estado = estado
	visible = true
	_mostrar_aviso()


func actualizar(estado: Dictionary) -> void:
	_estado = estado
	if _tarot.visible:
		_refrescar_tarot()


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
	panel.custom_minimum_size = Vector2(700, 520)
	centro.add_child(panel)

	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	panel.add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 14)
	margen.add_child(raiz)

	var titulo := Label.new()
	titulo.text = tr("ULTIMO_RECURSO_TITULO")
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(titulo)

	_aviso = VBoxContainer.new()
	_aviso.add_theme_constant_override("separation", 12)
	raiz.add_child(_aviso)
	_montar_aviso()

	_tarot = VBoxContainer.new()
	_tarot.add_theme_constant_override("separation", 10)
	_tarot.visible = false
	raiz.add_child(_tarot)
	_montar_tarot()


func _montar_aviso() -> void:
	var aviso := Label.new()
	aviso.text = tr("ULTIMO_RECURSO_AVISO")
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.add_child(aviso)

	var explicacion := Label.new()
	explicacion.text = tr("ULTIMO_RECURSO_EXPLICACION")
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.add_child(explicacion)

	_ver_tarot = Button.new()
	_ver_tarot.text = tr("ULTIMO_RECURSO_VER_TAROT")
	_ver_tarot.pressed.connect(_mostrar_tarot)
	_aviso.add_child(_ver_tarot)

	_firmar_cese = Button.new()
	_firmar_cese.text = tr("ULTIMO_RECURSO_CESE")
	_firmar_cese.pressed.connect(func(): cese_solicitado.emit())
	_aviso.add_child(_firmar_cese)


func _montar_tarot() -> void:
	var titulo := Label.new()
	titulo.text = tr("ULTIMO_RECURSO_TAROT_TITULO")
	_tarot.add_child(titulo)

	var ayuda := Label.new()
	ayuda.text = tr("ULTIMO_RECURSO_TAROT_AYUDA")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tarot.add_child(ayuda)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 350)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tarot.add_child(scroll)

	_tarot_lista = VBoxContainer.new()
	_tarot_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tarot_lista.add_theme_constant_override("separation", 8)
	scroll.add_child(_tarot_lista)

	_volver = Button.new()
	_volver.text = tr("ULTIMO_RECURSO_VOLVER")
	_volver.pressed.connect(_mostrar_aviso)
	_tarot.add_child(_volver)


func _mostrar_aviso() -> void:
	_aviso.visible = true
	_tarot.visible = false
	_ver_tarot.call_deferred("grab_focus")


func _mostrar_tarot() -> void:
	_aviso.visible = false
	_tarot.visible = true
	_refrescar_tarot()


func _refrescar_tarot() -> void:
	for nodo in _tarot_lista.get_children():
		_tarot_lista.remove_child(nodo)
		nodo.queue_free()

	var canjeables := Acusacion.cartas_canjeables(_estado)
	var primer_canje: Button = null
	var tarot_bruto = _estado.get("tarot", [])
	if typeof(tarot_bruto) == TYPE_ARRAY:
		for bruto in tarot_bruto:
			if typeof(bruto) != TYPE_DICTIONARY:
				continue
			var carta: Dictionary = bruto
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 10)
			_tarot_lista.add_child(fila)

			var estado_carta := tr("ULTIMO_RECURSO_ESTADO_SELLADA")
			if bool(carta.get("gastada", false)):
				estado_carta = tr("ULTIMO_RECURSO_ESTADO_GASTADA")
			elif bool(carta.get("recogida", false)):
				estado_carta = tr("ULTIMO_RECURSO_ESTADO_RECOGIDA")

			var nombre := Label.new()
			nombre.text = (
				tr("ULTIMO_RECURSO_CARTA")
				% [String(carta.get("nombre", carta.get("id", ""))), estado_carta]
			)
			nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fila.add_child(nombre)

			var carta_id := String(carta.get("id", ""))
			if canjeables.has(carta_id):
				var boton := Button.new()
				boton.text = tr("ULTIMO_RECURSO_CANJEAR")
				boton.pressed.connect(_solicitar_canje.bind(carta_id))
				fila.add_child(boton)
				if primer_canje == null:
					primer_canje = boton

	if primer_canje != null:
		primer_canje.call_deferred("grab_focus")
	else:
		_volver.call_deferred("grab_focus")


func _solicitar_canje(carta_id: String) -> void:
	canje_solicitado.emit(carta_id)
