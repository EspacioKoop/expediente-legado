## Presentación base compartida del día (#1761).
##
## Construye únicamente el entorno visual/sonoro común y el HUD mínimo. No
## conoce Jornada, transiciones, guardado ni reglas de dominio.
class_name DiaPresentacionApp
extends RefCounted

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")


func montar_entorno(parent: Node3D, perfil_jugador: Dictionary) -> Dictionary:
	var entorno := WorldEnvironment.new()
	var ajustes := Environment.new()
	ajustes.background_mode = Environment.BG_COLOR
	ajustes.background_color = Color(0.05, 0.05, 0.06)
	ajustes.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ajustes.ambient_light_color = Color(0.55, 0.55, 0.58)
	ajustes.ambient_light_energy = 0.7
	ajustes.ssao_enabled = true
	ajustes.ssao_radius = 0.8
	ajustes.ssao_intensity = 2.0
	ajustes.ssil_enabled = true
	ajustes.ssil_intensity = 0.7
	entorno.environment = ajustes
	parent.add_child(entorno)
	FiltroPantalla.aplicar(entorno, PreferenciasSiga.cargar())

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_energy = 0.7
	sol.shadow_enabled = true
	sol.shadow_bias = 0.03
	sol.shadow_normal_bias = 1.4
	parent.add_child(sol)

	var caminante := ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	var cuerpo_jugador := caminante.get_node_or_null("CuerpoJugador3D") as CuerpoJugador3D
	if cuerpo_jugador != null:
		cuerpo_jugador.perfil = perfil_jugador
	parent.add_child(caminante)

	var voz := AudioStreamPlayer.new()
	parent.add_child(voz)
	var pisada := AudioStreamPlayer3D.new()
	pisada.unit_size = 3.0
	caminante.add_child(pisada)

	return {
		"ambiente": ajustes,
		"sol": sol,
		"caminante": caminante,
		"voz": voz,
		"pisada": pisada,
	}


func montar_interfaz(parent: Node, al_borrar: Callable) -> Dictionary:
	var capa := CanvasLayer.new()
	parent.add_child(capa)

	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	caja.offset_left = 12
	caja.offset_top = 10
	caja.theme = EstiloSiga.tema()
	capa.add_child(caja)

	var rotulo := Label.new()
	rotulo.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	rotulo.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	rotulo.add_theme_constant_override("outline_size", 4)
	caja.add_child(rotulo)

	var nomina := Label.new()
	nomina.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	nomina.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	nomina.add_theme_constant_override("outline_size", 4)
	caja.add_child(nomina)

	var borrar := Button.new()
	borrar.text = parent.tr("CASA_BORRAR")
	borrar.visible = false
	borrar.pressed.connect(al_borrar)
	caja.add_child(borrar)

	return {
		"hud": capa,
		"rotulo": rotulo,
		"nomina": nomina,
		"borrar": borrar,
	}
