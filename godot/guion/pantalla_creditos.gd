## Pantalla «Créditos» del menú de inicio (#2530, corte 4 de #795).
##
## La apertura cinemática solo enseña los créditos clave; aquí está la fuente
## canónica entera (`CreditosInicio.bloques_completos()`), con cada atribución
## de assets y su licencia, para que el reconocimiento no dependa de ver la
## apertura. No guarda nada: quien la abre decide qué pasa al cerrarla.
class_name PantallaCreditos
extends Control

signal cerrada

var _boton_cerrar: Button


func _ready() -> void:
	theme = EstiloSiga.tema()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 32)
	margen.add_theme_constant_override("margin_top", 32)
	margen.add_theme_constant_override("margin_right", 32)
	margen.add_theme_constant_override("margin_bottom", 32)
	add_child(margen)

	var principal := VBoxContainer.new()
	principal.add_theme_constant_override("separation", 16)
	margen.add_child(principal)

	var titulo := Label.new()
	titulo.text = tr("CREDITOS_TITULO")
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	principal.add_child(titulo)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	principal.add_child(scroll)

	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 8)
	scroll.add_child(lista)

	var bloques := CreditosInicio.bloques_completos()
	for bloque in bloques:
		if not (bloque is Dictionary):
			continue
		var entradas: Array = bloque.get("entradas", [])
		if entradas.is_empty():
			continue

		var lbl_titulo := Label.new()
		lbl_titulo.text = String(bloque.get("titulo", ""))
		lbl_titulo.add_theme_font_size_override("font_size", 24)
		lbl_titulo.add_theme_color_override("font_color", EstiloSiga.AZUL_TITULO)
		lista.add_child(lbl_titulo)

		for entrada in entradas:
			if not (entrada is Dictionary):
				continue
			var nombre := String(entrada.get("nombre", ""))
			var detalle := String(entrada.get("detalle", ""))
			var licencia := String(entrada.get("licencia", ""))

			var texto := nombre
			if not detalle.is_empty():
				texto += " - " + detalle
			if not licencia.is_empty():
				texto += " (" + licencia + ")"

			var lbl_entrada := Label.new()
			lbl_entrada.text = texto
			lista.add_child(lbl_entrada)

	_boton_cerrar = Button.new()
	_boton_cerrar.text = tr("CREDITOS_CERRAR")
	_boton_cerrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_boton_cerrar.pressed.connect(func(): cerrada.emit())
	principal.add_child(_boton_cerrar)

	_boton_cerrar.grab_focus()


func _input(evento: InputEvent) -> void:
	# `cancelar` es la acción remapeable del juego; `ui_cancel`, la de Godot que
	# también cierra el resto de superposiciones del menú.
	if evento.is_action_pressed("cancelar") or evento.is_action_pressed("ui_cancel"):
		cerrada.emit()
		get_viewport().set_input_as_handled()
