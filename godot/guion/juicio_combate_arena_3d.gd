## Construcción de la arena visual del Juicio por Combate.
##
## Devuelve las referencias que el orquestador necesita para mover actores,
## resolver ataques y actualizar cámara. No contiene reglas de combate.
class_name JuicioCombateArena3D
extends RefCounted


static func montar(
	anfitrion: Node3D,
	acusado: Dictionary,
	arcano: Dictionary,
	mito_id: String,
	ritual: Dictionary,
	radio_base: float,
	radio_ritual: float,
) -> Dictionary:
	var mundo := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.025, 0.027, 0.032)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.48, 0.50, 0.46)
	entorno.ambient_light_energy = 0.65
	mundo.environment = entorno
	anfitrion.add_child(mundo)
	FiltroPantalla.aplicar(mundo, PreferenciasSiga.cargar())

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	luz.light_energy = 1.25
	anfitrion.add_child(luz)

	var suelo := MeshInstance3D.new()
	var malla_suelo := CylinderMesh.new()
	malla_suelo.top_radius = radio_base + 0.8
	malla_suelo.bottom_radius = radio_base + 0.8
	malla_suelo.height = 0.16
	malla_suelo.radial_segments = 32
	suelo.mesh = malla_suelo
	suelo.position.y = -0.12
	suelo.material_override = JuicioCombateFeedback3D.material(Color(0.16, 0.17, 0.15))
	anfitrion.add_child(suelo)

	for i in 8:
		var angulo := TAU * float(i) / 8.0
		var archivador := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.9, 1.8, 0.55)
		archivador.mesh = caja
		archivador.position = Vector3(sin(angulo) * 5.7, 0.9, cos(angulo) * 5.7)
		archivador.rotation.y = angulo
		archivador.material_override = JuicioCombateFeedback3D.material(Color(0.28, 0.31, 0.28))
		anfitrion.add_child(archivador)

	JuicioSimbolico3D.montar(anfitrion, arcano, mito_id)
	_montar_limite_ritual(anfitrion, ritual, radio_ritual)

	var jugador := CharacterBody3D.new()
	jugador.position = Vector3(0.0, 0.0, 2.4)
	anfitrion.add_child(jugador)
	var figura_jugador := FiguraSilueta.construir(jugador, Vector3.ZERO, Color(0.68, 0.70, 0.64))

	var rival := CharacterBody3D.new()
	rival.position = Vector3(0.0, 0.0, -2.4)
	anfitrion.add_child(rival)
	var clave := String(acusado.get("id", acusado.get("nombre", "acusado")))
	var matiz := 0.52 + float(absi(hash(clave)) % 14) / 100.0
	var figura_rival := FiguraSilueta.construir(
		rival, Vector3.ZERO, Color.from_hsv(matiz, 0.34, 0.72)
	)
	var aviso_ataque := _montar_aviso_ataque(anfitrion)

	var camara := Camera3D.new()
	camara.fov = 52.0
	anfitrion.add_child(camara)

	return {
		"jugador": jugador,
		"rival": rival,
		"figura_jugador": figura_jugador,
		"figura_rival": figura_rival,
		"aviso_ataque": aviso_ataque,
		"camara": camara,
	}


static func _montar_aviso_ataque(anfitrion: Node3D) -> MeshInstance3D:
	var aviso := MeshInstance3D.new()
	aviso.name = "AvisoAtaqueRival"
	var malla := CylinderMesh.new()
	malla.top_radius = JuicioCombateReglas.ALCANCE_RIVAL
	malla.bottom_radius = JuicioCombateReglas.ALCANCE_RIVAL
	malla.height = 0.025
	malla.radial_segments = 32
	aviso.mesh = malla

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.82, 0.10, 0.08, 0.34)
	material.emission_enabled = true
	material.emission = Color(0.82, 0.10, 0.08)
	material.emission_energy_multiplier = 0.75
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aviso.material_override = material
	aviso.visible = false
	anfitrion.add_child(aviso)
	return aviso


static func _montar_limite_ritual(
	anfitrion: Node3D, ritual: Dictionary, radio_ritual: float
) -> void:
	if String(ritual.get("id", "")) != "laberinto_lunar":
		return
	var color := Color(0.42, 0.48, 0.68)
	for i in 20:
		var angulo := TAU * float(i) / 20.0
		var marca := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.08, 0.10, 0.42)
		marca.mesh = caja
		marca.position = Vector3(sin(angulo) * radio_ritual, 0.03, cos(angulo) * radio_ritual)
		marca.rotation.y = angulo
		marca.material_override = JuicioCombateFeedback3D.material(color, true)
		anfitrion.add_child(marca)
