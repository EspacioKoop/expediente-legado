## Efectos ligeros de la calle (trayecto): salpicaduras en el suelo, goteo de
## las marquesinas, papeles al viento, humo de alcantarilla y vaho al respirar.
##
## Hermano de `EfectosLigeros`, que lo llama al montar el trayecto, y con su
## misma regla: presupuesto cerrado, sitios deterministas, nada de salas por su
## nombre y quieto o fuera con reducción de movimiento. Cada efecto responde al
## tiempo del día: con lluvia salpica y gotea; en seco vuelan papeles; con frío
## (nieve o niebla) humea la alcantarilla y se ve el aliento.
class_name EfectosCalle
extends RefCounted

const SHADER_SALPICADURAS := "res://arte/salpicaduras_suelo.gdshader"
const PARTICULAS_GOTEO := 12
const MAX_MARQUESINAS := 4
const PARTICULAS_PAPELES := 8
const PARTICULAS_HUMO := 16
const ALCANTARILLAS := [Vector2(-1.6, -6.0), Vector2(1.4, 7.5)]
const PARTICULAS_VAHO := 6
## Cada cuánto se respira, en segundos.
const RESPIRACION := 3.5


static func es_frio(clima: String) -> bool:
	return clima == Clima.NIEVE or clima == Clima.NIEBLA


static func montar(raiz: Node3D, mundo: Node3D, clima: String, reducir: bool) -> void:
	var llueve := clima == Clima.LLUVIA
	if llueve:
		_salpicaduras(raiz, reducir)
	if reducir:
		return
	if llueve:
		_goteo(mundo, raiz)
	elif clima != Clima.NIEVE:
		_papeles(raiz)
	if es_frio(clima):
		_humo(raiz)
		_vaho(raiz)


## Anillos de gota por toda la calzada: un único plano con shader, sin
## partículas. Encima de la calzada y por debajo de los charcos.
static func _salpicaduras(raiz: Node3D, reducir: bool) -> void:
	var suelo := MeshInstance3D.new()
	suelo.name = "Salpicaduras"
	var plano := PlaneMesh.new()
	plano.size = EfectosLigeros.SUELO_CALLE.size
	suelo.mesh = plano
	suelo.position = Vector3(
		EfectosLigeros.SUELO_CALLE.get_center().x, 0.028, EfectosLigeros.SUELO_CALLE.get_center().y
	)
	suelo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_SALPICADURAS)
	material.set_shader_parameter("velocidad", 0.0 if reducir else 1.0)
	material.set_shader_parameter("escala", plano.size)
	suelo.material_override = material
	raiz.add_child(suelo)


## Hilo de gotas por el borde de cada marquesina.
static func _goteo(mundo: Node3D, raiz: Node3D) -> void:
	var marquesinas := []
	for patron in ["Marquesina*", "*Toldo*"]:
		marquesinas.append_array(mundo.find_children(patron, "MeshInstance3D", true, false))
	for i in mini(marquesinas.size(), MAX_MARQUESINAS):
		var marquesina: MeshInstance3D = marquesinas[i]
		var caja := marquesina.global_transform * marquesina.get_aabb()
		var goteo := EfectosLigeros._emisor(PARTICULAS_GOTEO, 0.7, Vector2(0.012, 0.09))
		goteo.name = "Goteo%d" % i
		goteo.position = raiz.to_local(Vector3(caja.get_center().x, caja.position.y, caja.end.z))
		var proceso := goteo.process_material as ParticleProcessMaterial
		proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		proceso.emission_box_extents = Vector3(caja.size.x * 0.45, 0.01, 0.02)
		proceso.direction = Vector3.DOWN
		proceso.spread = 2.0
		proceso.initial_velocity_min = 0.5
		proceso.initial_velocity_max = 1.0
		proceso.gravity = Vector3(0.0, -9.8, 0.0)
		EfectosLigeros._color(goteo, Color(0.7, 0.8, 0.95, 0.7))
		goteo.visibility_aabb = AABB(
			Vector3(-caja.size.x, -4.0, -0.5), Vector3(caja.size.x * 2.0, 4.5, 1.0)
		)
		raiz.add_child(goteo)


## Papeles y hojas que arrastra el viento a ras de suelo, a lo largo de la calle.
static func _papeles(raiz: Node3D) -> void:
	var papeles := EfectosLigeros._emisor(PARTICULAS_PAPELES, 7.0, Vector2(0.14, 0.1))
	papeles.name = "Papeles"
	papeles.position = Vector3(0.0, 0.25, EfectosLigeros.SUELO_CALLE.position.y + 2.0)
	var proceso := papeles.process_material as ParticleProcessMaterial
	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proceso.emission_box_extents = Vector3(3.5, 0.2, 2.0)
	proceso.direction = Vector3(0.1, 0.15, 1.0)
	proceso.spread = 20.0
	proceso.initial_velocity_min = 2.0
	proceso.initial_velocity_max = 3.5
	proceso.gravity = Vector3(0.0, -0.4, 0.0)
	proceso.angular_velocity_min = -180.0
	proceso.angular_velocity_max = 180.0
	proceso.turbulence_enabled = true
	proceso.turbulence_noise_strength = 1.2
	proceso.turbulence_noise_scale = 2.0
	proceso.color_initial_ramp = _gradiente_papeles()
	proceso.alpha_curve = EfectosLigeros._curva_aparece_y_se_va()
	EfectosLigeros._color(papeles, Color(1, 1, 1, 0.9))
	(papeles.draw_pass_1 as QuadMesh).material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	(papeles.draw_pass_1 as QuadMesh).material.cull_mode = BaseMaterial3D.CULL_DISABLED
	papeles.visibility_aabb = AABB(Vector3(-5, -1, -2), Vector3(10, 3, 36))
	raiz.add_child(papeles)


## Hojas secas y papel de periódico: el color de cada pieza sale de aquí.
static func _gradiente_papeles() -> GradientTexture1D:
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.5, 0.51, 1.0])
	gradiente.colors = PackedColorArray(
		[
			Color(0.55, 0.36, 0.18),
			Color(0.62, 0.45, 0.22),
			Color(0.86, 0.84, 0.78),
			Color(0.93, 0.92, 0.88),
		]
	)
	var textura := GradientTexture1D.new()
	textura.gradient = gradiente
	return textura


## Columnas de vapor que salen de las alcantarillas las noches frías.
static func _humo(raiz: Node3D) -> void:
	for i in ALCANTARILLAS.size():
		var sitio: Vector2 = ALCANTARILLAS[i]
		var humo := EfectosLigeros._emisor(PARTICULAS_HUMO, 4.0, Vector2(0.35, 0.35))
		humo.name = "HumoAlcantarilla%d" % i
		humo.position = Vector3(sitio.x, 0.05, sitio.y)
		var proceso := humo.process_material as ParticleProcessMaterial
		proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		proceso.emission_sphere_radius = 0.25
		proceso.direction = Vector3.UP
		proceso.spread = 10.0
		proceso.initial_velocity_min = 0.3
		proceso.initial_velocity_max = 0.5
		proceso.gravity = Vector3(0.12, 0.05, 0.0)
		proceso.scale_min = 1.0
		proceso.scale_max = 3.0
		proceso.turbulence_enabled = true
		proceso.turbulence_noise_strength = 0.6
		proceso.alpha_curve = EfectosLigeros._curva_aparece_y_se_va()
		EfectosLigeros._color(humo, Color(0.82, 0.84, 0.86, 0.22), false, true)
		humo.visibility_aabb = AABB(Vector3(-1.5, 0, -1.5), Vector3(3, 3.5, 3))
		raiz.add_child(humo)


## El aliento del jugador en el frío: una nube pequeña delante de la cámara
## cada pocos segundos. La cámara se busca al respirar y no al montar, porque
## la del caminante llega después que el espacio.
static func _vaho(raiz: Node3D) -> void:
	var vaho := EfectosLigeros._emisor(PARTICULAS_VAHO, 1.6, Vector2(0.09, 0.09))
	vaho.name = "Vaho"
	vaho.one_shot = true
	vaho.emitting = false
	vaho.explosiveness = 0.7
	vaho.preprocess = 0.0
	var proceso := vaho.process_material as ParticleProcessMaterial
	proceso.direction = Vector3(0, 0.2, -1)
	proceso.spread = 18.0
	proceso.initial_velocity_min = 0.25
	proceso.initial_velocity_max = 0.45
	proceso.gravity = Vector3(0, 0.05, 0)
	proceso.scale_min = 1.0
	proceso.scale_max = 2.5
	proceso.alpha_curve = EfectosLigeros._curva_aparece_y_se_va()
	EfectosLigeros._color(vaho, Color(0.95, 0.96, 1.0, 0.35), false, true)
	raiz.add_child(vaho)
	var reloj := Timer.new()
	reloj.name = "Respiracion"
	reloj.wait_time = RESPIRACION
	reloj.autostart = true
	raiz.add_child(reloj)
	reloj.timeout.connect(func(): respirar(vaho))


## Coloca el vaho delante de la cámara activa y lo suelta. Falso si no hay
## cámara a la que pegarlo.
static func respirar(vaho: GPUParticles3D) -> bool:
	if not is_instance_valid(vaho) or not vaho.is_inside_tree():
		return false
	var camara := vaho.get_viewport().get_camera_3d()
	if camara == null:
		return false
	var delante := -camara.global_transform.basis.z
	vaho.global_position = camara.global_position + delante * 0.35 + Vector3(0, -0.12, 0)
	vaho.global_basis = camara.global_basis
	vaho.restart()
	return true
