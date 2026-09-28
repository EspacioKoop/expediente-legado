## Montaje del entorno común del día (#1761).
##
## Crea Environment, luz y Caminante, pero no decide fase ni contenido. DiaApp
## conserva _montar_entorno como hook para dia_cielo y asigna los nodos devueltos
## a los campos históricos que consumen las capas hijas.
class_name DiaEntornoApp
extends RefCounted


static func montar(host: Node3D, estado: Dictionary) -> Dictionary:
	var entorno := WorldEnvironment.new()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.05, 0.05, 0.06)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.55, 0.55, 0.58)
	ambiente.ambient_light_energy = 0.7
	ambiente.ssao_enabled = true
	ambiente.ssao_radius = 0.8
	ambiente.ssao_intensity = 2.0
	ambiente.ssil_enabled = true
	ambiente.ssil_intensity = 0.7
	entorno.environment = ambiente
	host.add_child(entorno)
	FiltroPantalla.aplicar(entorno, PreferenciasSiga.cargar())

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_energy = 0.7
	sol.shadow_enabled = true
	sol.shadow_bias = 0.03
	sol.shadow_normal_bias = 1.4
	host.add_child(sol)

	var caminante := load("res://escenas/caminante.tscn").instantiate() as CharacterBody3D
	var cuerpo_jugador := caminante.get_node_or_null("CuerpoJugador3D") as CuerpoJugador3D
	if cuerpo_jugador != null:
		cuerpo_jugador.perfil = estado.get("perfil_jugador", {})
	host.add_child(caminante)

	return {
		"ambiente": ambiente,
		"sol": sol,
		"caminante": caminante,
	}
