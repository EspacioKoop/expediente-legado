## Presentación base compartida del día (#1761).
##
## Construye únicamente el entorno visual/sonoro común y el HUD mínimo. No
## conoce Jornada, transiciones, guardado ni reglas de dominio.
class_name DiaPresentacionApp
extends RefCounted

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const METROS_POR_ZANCADA := 0.72
const PITCH_PASOS := [0.96, 1.03, 0.99, 1.05, 0.95, 1.01]

var _desde_paso := 0.0
var _indice_paso := 0


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


## Los pasos se disparan por distancia recorrida, no por reloj. El acumulador
## vive junto a la voz de pisadas para que DiaApp no posea estado de presentación.
func avanzar_pasos(
	caminante: CharacterBody3D,
	pantalla_abierta: bool,
	pisada: AudioStreamPlayer3D,
	suelo: String,
	delta: float,
) -> void:
	if caminante == null or pisada == null:
		return
	if pantalla_abierta or not caminante.is_physics_processing():
		return
	var avance := Vector2(caminante.velocity.x, caminante.velocity.z).length() * delta
	_desde_paso += avance
	if _desde_paso < METROS_POR_ZANCADA:
		return
	_desde_paso = 0.0
	pisada.stream = Sonido.paso_sobre(suelo)
	pisada.pitch_scale = PITCH_PASOS[_indice_paso % PITCH_PASOS.size()]
	_indice_paso += 1
	pisada.play()


## El suelo es presentación del espacio; la nieve de trayecto sigue sustituyendo
## la textura base exactamente como antes del refactor.
func suelo_pisado(jornada: Dictionary, espacio_actual: Dictionary) -> String:
	if (
		String(jornada.get("fase", "")) == "trayecto"
		and Clima.estado(int(jornada.get("dia", 1))) == Clima.NIEVE
	):
		return Sonido.NIEVE
	return String(espacio_actual.get("textura_suelo", ""))


func sonar(voz: AudioStreamPlayer, nombre: String) -> void:
	if voz == null:
		return
	var stream := Sonido.stream(nombre)
	if stream == null:
		return
	voz.stream = stream
	voz.play()
