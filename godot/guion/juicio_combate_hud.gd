## Constructor del HUD del Juicio por Combate.
##
## Monta la jerarquía visual y devuelve referencias a sus controles. Las reglas
## y el estado continúan en JuicioCombate3D; este módulo solo compone interfaz.
class_name JuicioCombateHud
extends RefCounted


static func montar(
	anfitrion: Node,
	nombre_acusado: String,
	determinacion_rival: int,
	mostrar_ritual: bool,
	textos: Dictionary,
	ejecutar_finisher: Callable,
) -> Dictionary:
	var capa := CanvasLayer.new()
	capa.layer = 5
	anfitrion.add_child(capa)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_top", 18)
	capa.add_child(margen)

	var bloque := VBoxContainer.new()
	bloque.add_theme_constant_override("separation", 6)
	margen.add_child(bloque)

	var columnas := HBoxContainer.new()
	columnas.add_theme_constant_override("separation", 32)
	bloque.add_child(columnas)

	var barra_jugador := ProgressBar.new()
	barra_jugador.max_value = JuicioCombateReglas.DETERMINACION_BASE
	barra_jugador.show_percentage = false
	barra_jugador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columnas.add_child(barra_jugador)

	var nombre := Label.new()
	nombre.text = nombre_acusado
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columnas.add_child(nombre)

	var barra_rival := ProgressBar.new()
	barra_rival.max_value = determinacion_rival
	barra_rival.show_percentage = false
	barra_rival.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columnas.add_child(barra_rival)

	var etiqueta_ritual: Label = null
	if mostrar_ritual:
		etiqueta_ritual = Label.new()
		etiqueta_ritual.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bloque.add_child(etiqueta_ritual)

	var botones_doctrina := HBoxContainer.new()
	botones_doctrina.alignment = BoxContainer.ALIGNMENT_CENTER
	botones_doctrina.add_theme_constant_override("separation", 6)
	bloque.add_child(botones_doctrina)

	var etiqueta_ataque := Label.new()
	etiqueta_ataque.text = String(textos.get("ataque_inminente", ""))
	etiqueta_ataque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_ataque.add_theme_color_override("font_color", Color(0.94, 0.28, 0.18))
	etiqueta_ataque.visible = false
	bloque.add_child(etiqueta_ataque)

	var fila_momentum := HBoxContainer.new()
	fila_momentum.add_theme_constant_override("separation", 8)
	bloque.add_child(fila_momentum)

	var texto_momentum := Label.new()
	texto_momentum.text = String(textos.get("momentum", ""))
	fila_momentum.add_child(texto_momentum)

	var barra_momentum := ProgressBar.new()
	barra_momentum.show_percentage = true
	barra_momentum.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_momentum.add_child(barra_momentum)

	var boton_finisher := Button.new()
	boton_finisher.text = String(textos.get("finisher", ""))
	boton_finisher.disabled = true
	boton_finisher.tooltip_text = String(textos.get("finisher_tooltip", ""))
	boton_finisher.pressed.connect(ejecutar_finisher)
	fila_momentum.add_child(boton_finisher)

	var etiqueta_jungiana := Label.new()
	etiqueta_jungiana.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_jungiana.visible = false
	bloque.add_child(etiqueta_jungiana)

	return {
		"barra_jugador": barra_jugador,
		"barra_rival": barra_rival,
		"etiqueta_ritual": etiqueta_ritual,
		"etiqueta_ataque": etiqueta_ataque,
		"botones_doctrina": botones_doctrina,
		"barra_momentum": barra_momentum,
		"boton_finisher": boton_finisher,
		"etiqueta_jungiana": etiqueta_jungiana,
	}
