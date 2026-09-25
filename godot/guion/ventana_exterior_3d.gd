## Diorama urbano híbrido renderizado en vivo para la ventana de la casa (#566).
##
## El SubViewport conserva profundidad real, cámara, calle, árboles, coches,
## farolas, nubes, niebla y precipitación 3D. La línea de bloques procedurales que
## dominaba la vista se sustituye por un matte urbano propio de segunda línea:
## aporta balcones, azoteas, antenas y densidad de barrio sin duplicar geometría
## ni convertir la ventana en una captura estática.
##
## El matte se renderiza dentro del mismo mundo 3D y recibe un tinte por clima.
## El render a 320x180 con filtrado nearest mantiene la lectura PSX y las capas
## volumétricas siguen pasando por delante de la imagen.
class_name VentanaExterior3D
extends Node3D

const TAM_VIEWPORT := Vector2i(320, 180)
const FONDO_BARRIO_98 := preload("res://assets/texturas/ventana_casa_ai_98/fondo_barrio_98.webp")
const ESTADO_DEFECTO := Clima.DESPEJADO

var _viewport: SubViewport
var _fondo_material: StandardMaterial3D
var _entorno: Environment
var _sol: DirectionalLight3D
var _lluvia: GPUParticles3D
var _nieve: GPUParticles3D
var _niebla: Node3D
var _nubes: Node3D
var _suelo_nieve: Node3D
var _estado := ""
var _tiempo := 0.0
var _reduccion_movimiento := false


func _ready() -> void:
	_construir()
	configurar(ESTADO_DEFECTO)


func configurar(estado_clima: String) -> void:
	if not is_node_ready():
		_estado = estado_clima
		return
	if estado_clima == _estado:
		return
	_estado = estado_clima
	_aplicar_clima()


## El diorama del menú de inicio (#830) reutiliza este exterior y debe
## congelar la deriva de nubes/niebla cuando el jugador pide menos movimiento.
## La lluvia sigue el mismo patrón que un fuego o un reloj: un bucle ya
## estable, no un desplazamiento nuevo en pantalla, así que se deja intacta.
func configurar_activo(activo: bool) -> void:
	set_process(activo)
	if _viewport != null:
		_viewport.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS if activo else SubViewport.UPDATE_DISABLED
		)


func configurar_reduccion_movimiento(activa: bool) -> void:
	_reduccion_movimiento = activa


func _process(delta: float) -> void:
	if _reduccion_movimiento:
		return
	_tiempo += delta
	if _nubes != null and is_instance_valid(_nubes):
		_nubes.position.x = fposmod(_tiempo * 0.12 + 8.0, 16.0) - 8.0
	if _niebla != null and is_instance_valid(_niebla) and _niebla.visible:
		_niebla.position.x = sin(_tiempo * 0.10) * 0.55


func _construir() -> void:
	if _viewport != null:
		return

	_viewport = SubViewport.new()
	_viewport.name = "RenderExterior3D"
	_viewport.size = TAM_VIEWPORT
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	add_child(_viewport)

	var mundo := Node3D.new()
	mundo.name = "BarrioProcedural"
	_viewport.add_child(mundo)

	var world_environment := WorldEnvironment.new()
	world_environment.name = "EntornoExterior"
	_entorno = Environment.new()
	_entorno.background_mode = Environment.BG_COLOR
	_entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_entorno.ambient_light_color = Color(0.66, 0.68, 0.70)
	_entorno.ambient_light_energy = 0.72
	world_environment.environment = _entorno
	mundo.add_child(world_environment)

	_sol = DirectionalLight3D.new()
	_sol.name = "SolExterior"
	_sol.rotation_degrees = Vector3(-34.0, -28.0, 0.0)
	_sol.light_color = Color(1.0, 0.90, 0.73)
	_sol.light_energy = 1.25
	_sol.shadow_enabled = true
	mundo.add_child(_sol)

	var camara := Camera3D.new()
	camara.name = "CamaraVentana"
	camara.position = Vector3(0.0, 2.65, 6.8)
	camara.fov = 53.0
	camara.near = 0.08
	camara.far = 80.0
	mundo.add_child(camara)
	camara.look_at(Vector3(0.0, 2.0, -11.0), Vector3.UP)
	camara.current = true

	_montar_barrio(mundo)
	_montar_clima(mundo)
	_montar_pantalla()


func _montar_pantalla() -> void:
	var pantalla := MeshInstance3D.new()
	pantalla.name = "CristalVista3D"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.78, 1.06)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_texture = _viewport.get_texture()
	quad.material = material
	pantalla.mesh = quad
	# Delante del relleno oscuro histórico, pero detrás de los 4 cm del marco.
	pantalla.position = Vector3(0.0, 0.0, 0.022)
	add_child(pantalla)


func _montar_barrio(raiz: Node3D) -> void:
	# Calle y aceras: profundidad real, no una imagen en perspectiva.
	_agregar_caja(
		raiz,
		"Asfalto",
		Vector3(0.0, -0.12, -10.0),
		Vector3(18.0, 0.20, 21.0),
		Color(0.16, 0.16, 0.15)
	)
	_agregar_caja(
		raiz,
		"AceraIzquierda",
		Vector3(-6.25, 0.02, -10.0),
		Vector3(3.2, 0.18, 21.0),
		Color(0.43, 0.41, 0.37)
	)
	_agregar_caja(
		raiz,
		"AceraDerecha",
		Vector3(6.25, 0.02, -10.0),
		Vector3(3.2, 0.18, 21.0),
		Color(0.43, 0.41, 0.37)
	)

	# Segunda línea fotorealista. La calle, coches, vegetación y clima siguen
	# siendo 3D para que la vista conserve profundidad y respuesta ambiental.
	_montar_fondo_barrio(raiz)

	# Coches aparcados y uno más lejano rompen la lectura de maqueta vacía.
	_montar_coche(raiz, Vector3(-3.3, 0.30, -6.7), Color(0.22, 0.25, 0.27), 8.0)
	_montar_coche(raiz, Vector3(3.5, 0.30, -8.0), Color(0.49, 0.45, 0.32), -5.0)
	_montar_coche(raiz, Vector3(1.1, 0.27, -13.4), Color(0.29, 0.31, 0.26), 3.0)

	for datos in [
		[Vector3(-4.4, 0.0, -8.7), 1.35],
		[Vector3(4.2, 0.0, -10.2), 1.15],
		[Vector3(-2.2, 0.0, -15.3), 1.05],
	]:
		_montar_arbol(raiz, datos[0], float(datos[1]))

	for pos in [Vector3(-4.8, 0.0, -5.8), Vector3(4.8, 0.0, -7.4), Vector3(-4.8, 0.0, -13.0)]:
		_montar_farola(raiz, pos)


func _montar_fondo_barrio(raiz: Node3D) -> void:
	var fondo := MeshInstance3D.new()
	fondo.name = "FondoBarrioFotorealista98"
	var quad := QuadMesh.new()
	quad.size = Vector2(26.0, 14.625)
	_fondo_material = StandardMaterial3D.new()
	_fondo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fondo_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fondo_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_fondo_material.albedo_texture = FONDO_BARRIO_98
	quad.material = _fondo_material
	fondo.mesh = quad
	# Detrás de la calle procedural, suficientemente cerca para leer detalle sin
	# competir con los props volumétricos de primer término.
	fondo.position = Vector3(0.0, 4.65, -24.5)
	fondo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fondo.set_meta("ventana_casa_ai_98", true)
	raiz.add_child(fondo)


func _montar_coche(raiz: Node3D, pos: Vector3, color: Color, giro: float) -> void:
	var coche := Node3D.new()
	coche.name = "CocheAparcado"
	coche.position = pos
	coche.rotation_degrees.y = giro
	raiz.add_child(coche)
	_agregar_caja(coche, "Carroceria", Vector3(0.0, 0.28, 0.0), Vector3(1.65, 0.42, 0.78), color)
	_agregar_caja(
		coche,
		"Habitaculo",
		Vector3(-0.12, 0.58, -0.02),
		Vector3(0.92, 0.34, 0.70),
		color.lightened(0.04)
	)
	for x in [-0.58, 0.58]:
		for z in [-0.39, 0.39]:
			_agregar_cilindro(
				coche,
				"Rueda",
				Vector3(x, 0.16, z),
				0.15,
				0.10,
				Color(0.055, 0.055, 0.05),
				Vector3(90.0, 0.0, 0.0)
			)


func _montar_arbol(raiz: Node3D, pos: Vector3, escala: float) -> void:
	var arbol := Node3D.new()
	arbol.name = "ArbolCalle"
	arbol.position = pos
	arbol.scale = Vector3.ONE * escala
	raiz.add_child(arbol)
	_agregar_cilindro(arbol, "Tronco", Vector3(0.0, 0.82, 0.0), 0.12, 1.65, Color(0.24, 0.16, 0.10))
	for copa in [Vector3(-0.28, 1.72, 0.0), Vector3(0.30, 1.82, 0.04), Vector3(0.0, 2.14, -0.08)]:
		_agregar_esfera(arbol, "Copa", copa, 0.72, Color(0.29, 0.34, 0.19))


func _montar_farola(raiz: Node3D, pos: Vector3) -> void:
	var farola := Node3D.new()
	farola.name = "Farola"
	farola.position = pos
	raiz.add_child(farola)
	_agregar_cilindro(farola, "Poste", Vector3(0.0, 1.55, 0.0), 0.045, 3.1, Color(0.19, 0.20, 0.19))
	_agregar_caja(
		farola,
		"Brazo",
		Vector3(0.20, 3.02, 0.0),
		Vector3(0.44, 0.045, 0.045),
		Color(0.19, 0.20, 0.19)
	)
	_agregar_caja(
		farola,
		"Luminaria",
		Vector3(0.42, 2.94, 0.0),
		Vector3(0.25, 0.10, 0.18),
		Color(0.70, 0.62, 0.38),
		true
	)


func _montar_clima(raiz: Node3D) -> void:
	_nubes = Node3D.new()
	_nubes.name = "Nubes3D"
	raiz.add_child(_nubes)
	for i in range(5):
		var nube := Node3D.new()
		nube.position = Vector3(-6.0 + i * 3.2, 7.0 + (i % 2) * 0.45, -24.0 - (i % 3) * 2.0)
		_nubes.add_child(nube)
		for j in range(3):
			_agregar_esfera(
				nube,
				"VolumenNube",
				Vector3(j * 0.85 - 0.8, sin(float(j)) * 0.18, 0.0),
				1.05 - j * 0.10,
				Color(0.66, 0.68, 0.69)
			)

	_niebla = Node3D.new()
	_niebla.name = "BancosNiebla3D"
	raiz.add_child(_niebla)
	for datos in [[-7.0, 0.23], [-13.0, 0.30], [-19.0, 0.38]]:
		var bruma := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(18.0, 7.0)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.66, 0.69, 0.70, float(datos[1]))
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		quad.material = mat
		bruma.mesh = quad
		bruma.position = Vector3(0.0, 3.0, float(datos[0]))
		_niebla.add_child(bruma)

	_lluvia = _crear_precipitacion(false)
	_lluvia.name = "Lluvia3D"
	raiz.add_child(_lluvia)

	_nieve = _crear_precipitacion(true)
	_nieve.name = "Nieve3D"
	raiz.add_child(_nieve)

	_suelo_nieve = Node3D.new()
	_suelo_nieve.name = "NieveAcumulada"
	raiz.add_child(_suelo_nieve)
	_agregar_caja(
		_suelo_nieve,
		"CapaCalle",
		Vector3(0.0, 0.015, -10.0),
		Vector3(17.0, 0.035, 20.0),
		Color(0.76, 0.79, 0.80)
	)


func _crear_precipitacion(es_nieve: bool) -> GPUParticles3D:
	var particulas := GPUParticles3D.new()
	particulas.amount = 190 if es_nieve else 330
	particulas.lifetime = 4.2 if es_nieve else 1.15
	particulas.position = Vector3(0.0, 5.2, -9.0)
	particulas.visibility_aabb = AABB(Vector3(-10.0, -7.0, -12.0), Vector3(20.0, 14.0, 24.0))

	var proceso := ParticleProcessMaterial.new()
	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proceso.emission_box_extents = Vector3(8.0, 1.8, 10.0)
	proceso.direction = Vector3(0.0, -1.0, 0.0)
	proceso.spread = 16.0 if es_nieve else 4.0
	proceso.initial_velocity_min = 0.8 if es_nieve else 10.0
	proceso.initial_velocity_max = 1.8 if es_nieve else 14.0
	proceso.gravity = Vector3(0.22, -0.35, 0.0) if es_nieve else Vector3(0.45, -7.0, 0.0)
	particulas.process_material = proceso

	var quad := QuadMesh.new()
	quad.size = Vector2(0.075, 0.075) if es_nieve else Vector2(0.018, 0.42)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(0.92, 0.95, 0.97, 0.88) if es_nieve else Color(0.63, 0.72, 0.78, 0.62)
	quad.material = mat
	particulas.draw_pass_1 = quad
	return particulas


func _aplicar_clima() -> void:
	if _entorno == null:
		return
	var estado := _estado if _estado != "" else ESTADO_DEFECTO
	_lluvia.emitting = estado == Clima.LLUVIA
	_nieve.emitting = estado == Clima.NIEVE
	_niebla.visible = estado == Clima.NIEBLA
	_suelo_nieve.visible = estado == Clima.NIEVE
	_nubes.visible = estado != Clima.DESPEJADO

	match estado:
		Clima.NUBLADO:
			_tintar_fondo(Color(0.70, 0.72, 0.72))
			_entorno.background_color = Color(0.43, 0.48, 0.50)
			_entorno.ambient_light_color = Color(0.63, 0.65, 0.65)
			_entorno.ambient_light_energy = 0.72
			_sol.light_color = Color(0.78, 0.80, 0.78)
			_sol.light_energy = 0.62
		Clima.LLUVIA:
			_tintar_fondo(Color(0.48, 0.55, 0.60))
			_entorno.background_color = Color(0.25, 0.30, 0.33)
			_entorno.ambient_light_color = Color(0.48, 0.54, 0.57)
			_entorno.ambient_light_energy = 0.60
			_sol.light_color = Color(0.62, 0.67, 0.69)
			_sol.light_energy = 0.42
		Clima.NIEBLA:
			_tintar_fondo(Color(0.78, 0.79, 0.77))
			_entorno.background_color = Color(0.59, 0.62, 0.62)
			_entorno.ambient_light_color = Color(0.71, 0.72, 0.70)
			_entorno.ambient_light_energy = 0.82
			_sol.light_color = Color(0.76, 0.77, 0.73)
			_sol.light_energy = 0.32
		Clima.NIEVE:
			_tintar_fondo(Color(0.78, 0.84, 0.90))
			_entorno.background_color = Color(0.56, 0.62, 0.68)
			_entorno.ambient_light_color = Color(0.72, 0.78, 0.83)
			_entorno.ambient_light_energy = 0.88
			_sol.light_color = Color(0.83, 0.88, 0.94)
			_sol.light_energy = 0.70
		_:
			_tintar_fondo(Color(1.0, 0.96, 0.90))
			_entorno.background_color = Color(0.40, 0.57, 0.72)
			_entorno.ambient_light_color = Color(0.73, 0.67, 0.57)
			_entorno.ambient_light_energy = 0.74
			_sol.light_color = Color(1.0, 0.89, 0.71)
			_sol.light_energy = 1.20


func _tintar_fondo(color: Color) -> void:
	if _fondo_material != null:
		_fondo_material.albedo_color = color


func _agregar_caja(
	raiz: Node3D, nombre: String, pos: Vector3, tam: Vector3, color: Color, emisivo := false
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var mesh := BoxMesh.new()
	mesh.size = tam
	nodo.mesh = mesh
	nodo.position = pos
	nodo.material_override = _material(color, emisivo)
	raiz.add_child(nodo)
	return nodo


func _agregar_cilindro(
	raiz: Node3D,
	nombre: String,
	pos: Vector3,
	radio: float,
	alto: float,
	color: Color,
	rotacion := Vector3.ZERO
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var mesh := CylinderMesh.new()
	mesh.top_radius = radio
	mesh.bottom_radius = radio
	mesh.height = alto
	mesh.radial_segments = 6
	nodo.mesh = mesh
	nodo.position = pos
	nodo.rotation_degrees = rotacion
	nodo.material_override = _material(color)
	raiz.add_child(nodo)
	return nodo


func _agregar_esfera(
	raiz: Node3D, nombre: String, pos: Vector3, radio: float, color: Color
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var mesh := SphereMesh.new()
	mesh.radius = radio
	mesh.height = radio * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	nodo.mesh = mesh
	nodo.position = pos
	nodo.material_override = _material(color)
	raiz.add_child(nodo)
	return nodo


func _material(color: Color, emisivo := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mat.metallic = 0.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if emisivo:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.75
	return mat
