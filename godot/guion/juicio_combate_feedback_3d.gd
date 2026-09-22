## Presentación efímera del Juicio por Combate.
##
## Recibe sus dependencias de forma explícita y no conserva estado: cámara,
## tweens, partículas y materiales quedan fuera del orquestador de combate.
class_name JuicioCombateFeedback3D
extends RefCounted


static func actualizar_camara(
	camara: Camera3D,
	jugador: Node3D,
	rival: Node3D,
	sacudida_restante: float,
	reduccion_movimiento: bool,
	rng: RandomNumberGenerator,
) -> void:
	if camara == null or jugador == null or rival == null:
		return
	var centro := (jugador.position + rival.position) * 0.5
	var sacudida := Vector3.ZERO
	if sacudida_restante > 0.0 and not reduccion_movimiento:
		sacudida = Vector3(
			rng.randf_range(-0.12, 0.12),
			rng.randf_range(-0.08, 0.08),
			0.0,
		)
	camara.position = centro + Vector3(0.0, 7.2, 8.2) + sacudida
	camara.look_at(centro + Vector3(0.0, 0.9, 0.0), Vector3.UP)


static func particulas_jungianas(
	anfitrion: Node, rival: Node3D, radio: float, es_super: bool
) -> void:
	if rival == null:
		return
	var particulas := CPUParticles3D.new()
	particulas.amount = 42 if es_super else 24
	particulas.one_shot = true
	particulas.lifetime = 0.65 if es_super else 0.45
	particulas.explosiveness = 1.0
	particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = clampf(radio * 0.22, 0.3, 1.4)
	particulas.gravity = Vector3(0.0, -1.8, 0.0)
	particulas.initial_velocity_min = 2.2
	particulas.initial_velocity_max = 4.5 if es_super else 3.2
	var malla := SphereMesh.new()
	malla.radius = 0.045 if es_super else 0.03
	malla.height = malla.radius * 2.0
	particulas.mesh = malla
	particulas.position = rival.position + Vector3(0.0, 1.0, 0.0)
	anfitrion.add_child(particulas)
	particulas.finished.connect(particulas.queue_free)
	particulas.restart()


static func reaccion(
	anfitrion: Node, figura: Node3D, desplazamiento: float, reduccion_movimiento: bool
) -> void:
	if reduccion_movimiento or figura == null:
		return
	var origen := figura.position
	var tween := anfitrion.create_tween()
	tween.tween_property(figura, "position:z", origen.z + desplazamiento, 0.08)
	tween.tween_property(figura, "position:z", origen.z, 0.16)


static func material(color: Color, emision: bool = false) -> StandardMaterial3D:
	var resultado := StandardMaterial3D.new()
	resultado.albedo_color = color
	resultado.roughness = 0.9
	if emision:
		resultado.emission_enabled = true
		resultado.emission = color
		resultado.emission_energy_multiplier = 0.8
	return resultado
