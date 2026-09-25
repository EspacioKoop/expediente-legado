## Fondo 3D en tiempo real del menú de inicio (#830): oficina nocturna con un
## puesto de #400, un monitor CRT propio y la calle lluviosa de #566 al fondo.
##
## Se renderiza a baja resolución interna con `nearest` y sin MSAA, igual que
## `VentanaExterior3D`, y se expone como una textura para que `inicio_app.gd`
## la pinte a pantalla completa detrás del menú. No depende de ninguna
## jornada: es un diorama aparte que solo instancia utilería ya existente.
class_name InicioDiorama3D
extends Node3D

const TAM_VIEWPORT := Vector2i(384, 216)
const CRT_SHADER: Shader = preload("res://arte/crt_menu_inicio.gdshader")

const CAMARA_POS := Vector3(0.0, 1.56, 2.55)
const CAMARA_MIRA := Vector3(0.05, 1.18, -1.4)
const FOV_BASE := 48.0

## Deriva sutil de encuadre por opción enfocada: nunca cambia de escena, solo
## corrige cámara/mirada unos centímetros y, en "salir", oscurece el ambiente.
const ZONAS := {
	"continuar": {"pos": Vector3.ZERO, "mira": Vector3.ZERO, "oscurecer": 0.0},
	"nueva":
	{"pos": Vector3(-0.10, -0.02, 0.0), "mira": Vector3(-0.28, -0.05, 0.0), "oscurecer": 0.0},
	"cargar":
	{"pos": Vector3(0.08, -0.02, 0.0), "mira": Vector3(0.30, -0.10, 0.0), "oscurecer": 0.0},
	"extras": {"pos": Vector3(0.04, 0.04, 0.0), "mira": Vector3(0.18, 0.20, 0.0), "oscurecer": 0.0},
	"opciones":
	{"pos": Vector3(0.0, 0.05, 0.05), "mira": Vector3(-0.05, -0.18, 0.15), "oscurecer": 0.0},
	"salir": {"pos": Vector3(0.0, 0.0, 0.35), "mira": Vector3.ZERO, "oscurecer": 0.35},
}
const VELOCIDAD_DERIVA := 1.8
const AMPLITUD_DRIFT_AMBIENTAL := 0.018
const AMPLITUD_PAPEL := 0.012
const AMPLITUD_VAPOR := 0.018

## #830/#888: el attract mode reutiliza la misma oficina y expresa la gramática
## simbólica mediante composición, no mediante cartas, glifos o texto visible.
## Los IDs solo sirven a dirección/tests; nunca llegan a la UI.
const SEGUNDOS_INACTIVIDAD_ATTRACT := 45.0
const SEGUNDOS_PLANO_ATTRACT := 10.0
const VELOCIDAD_DERIVA_ATTRACT := 0.35
const TABLEAUX_ATTRACT := [
	{"id": "balanza", "zona": "cargar", "fov": 47.6, "luz": 0.92},
	{"id": "vigilia", "zona": "opciones", "fov": 46.8, "luz": 0.74},
	{"id": "reflejo", "zona": "continuar", "fov": 48.8, "luz": 0.62},
	{"id": "umbral", "zona": "extras", "fov": 49.4, "luz": 0.80},
]

var _viewport: SubViewport
var _camara: Camera3D
var _entorno: Environment
var _luz_fluorescente: OmniLight3D
var _material_crt: ShaderMaterial
var _exterior: VentanaExterior3D
var _papel_bandeja: Node3D
var _vapor_taza: MeshInstance3D
var _papel_pos_base := Vector3.ZERO
var _vapor_pos_base := Vector3.ZERO

var _reduccion_movimiento := false
var _tiempo := 0.0
var _zona_actual := "continuar"
var _zona_usuario := "continuar"
var _offset_pos := Vector3.ZERO
var _offset_mira := Vector3.ZERO
var _oscurecer := 0.0
var _energia_base := 0.0
var _siguiente_fallo_fluorescente := 0.0
var _inactividad := 0.0
var _attract_activo := false
var _tiempo_plano_attract := 0.0
var _indice_plano_attract := 0
var _fov_objetivo := FOV_BASE
var _multiplicador_luz_attract := 1.0


func _ready() -> void:
	_construir()


## Textura ya renderizada, lista para pintar en un `TextureRect` de fondo.
func obtener_textura() -> ViewportTexture:
	return _viewport.get_texture()


## Suspende el render y la lógica ambiental cuando otra superficie modal cubre
## por completo el menú (p. ej. el portátil). Evita mantener dos viewports 3D
## actualizándose detrás de un overlay que el jugador no puede ver.
func configurar_activo(activo: bool) -> void:
	set_process(activo)
	set_process_input(activo)
	if _viewport != null:
		_viewport.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS if activo else SubViewport.UPDATE_DISABLED
		)
	if _exterior != null:
		_exterior.configurar_activo(activo)


func configurar_reduccion_movimiento(activa: bool) -> void:
	_reduccion_movimiento = activa
	if activa:
		_registrar_actividad()
	if _exterior != null:
		_exterior.configurar_reduccion_movimiento(activa)
	if _material_crt != null:
		_material_crt.set_shader_parameter("activo", not activa)
	if _vapor_taza != null:
		_vapor_taza.visible = not activa
		if activa:
			_vapor_taza.position = _vapor_pos_base
			_vapor_taza.scale = Vector3.ONE
	if _papel_bandeja != null and activa:
		_papel_bandeja.position = _papel_pos_base
		_papel_bandeja.rotation.y = 0.0
	if activa:
		_offset_pos = ZONAS.get(_zona_actual, ZONAS.continuar).pos
		_offset_mira = ZONAS.get(_zona_actual, ZONAS.continuar).mira
		_oscurecer = ZONAS.get(_zona_actual, ZONAS.continuar).oscurecer
		_camara.fov = FOV_BASE
		_actualizar_camara()
		_actualizar_ambiente()


## Deriva de encuadre según la opción de menú enfocada. `zona` es una clave de
## `ZONAS`; una desconocida cae en "continuar" (composición general).
func enfocar(zona: String) -> void:
	_zona_usuario = zona if ZONAS.has(zona) else "continuar"
	_registrar_actividad()
	_zona_actual = _zona_usuario
	if _reduccion_movimiento:
		configurar_reduccion_movimiento(true)


func _input(event: InputEvent) -> void:
	if _es_actividad_usuario(event):
		_registrar_actividad()


func _process(delta: float) -> void:
	_tiempo += delta
	_procesar_attract(delta)
	var datos: Dictionary = ZONAS.get(_zona_actual, ZONAS.continuar)
	var velocidad := VELOCIDAD_DERIVA_ATTRACT if _attract_activo else VELOCIDAD_DERIVA
	if not _reduccion_movimiento:
		_offset_pos = _offset_pos.lerp(datos.pos, minf(1.0, velocidad * delta))
		_offset_mira = _offset_mira.lerp(datos.mira, minf(1.0, velocidad * delta))
		_oscurecer = lerpf(_oscurecer, datos.oscurecer, minf(1.0, velocidad * delta))
		_camara.fov = lerpf(_camara.fov, _fov_objetivo, minf(1.0, velocidad * delta))
		_actualizar_ambiente()
		_actualizar_fluorescente()
		_actualizar_detalles_ambientales()
	_actualizar_camara()


func _procesar_attract(delta: float) -> void:
	if _reduccion_movimiento:
		return
	if _attract_activo:
		_tiempo_plano_attract += delta
		if _tiempo_plano_attract >= SEGUNDOS_PLANO_ATTRACT:
			_tiempo_plano_attract = 0.0
			_indice_plano_attract = (_indice_plano_attract + 1) % TABLEAUX_ATTRACT.size()
			_aplicar_tableau_attract()
		return
	_inactividad += delta
	if _inactividad >= SEGUNDOS_INACTIVIDAD_ATTRACT:
		_attract_activo = true
		_indice_plano_attract = 0
		_tiempo_plano_attract = 0.0
		_aplicar_tableau_attract()


func _aplicar_tableau_attract() -> void:
	var tableau: Dictionary = TABLEAUX_ATTRACT[_indice_plano_attract]
	_zona_actual = String(tableau.get("zona", "continuar"))
	_fov_objetivo = float(tableau.get("fov", FOV_BASE))
	_multiplicador_luz_attract = float(tableau.get("luz", 1.0))


func _registrar_actividad() -> void:
	_inactividad = 0.0
	_tiempo_plano_attract = 0.0
	_indice_plano_attract = 0
	_fov_objetivo = FOV_BASE
	_multiplicador_luz_attract = 1.0
	if _attract_activo:
		_attract_activo = false
		_zona_actual = _zona_usuario


func _es_actividad_usuario(event: InputEvent) -> bool:
	var activa := false
	if event is InputEventKey:
		activa = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		activa = event.pressed
	elif event is InputEventMouseMotion:
		activa = event.relative.length_squared() >= 4.0
	elif event is InputEventJoypadButton:
		activa = event.pressed
	elif event is InputEventJoypadMotion:
		activa = absf(event.axis_value) >= 0.25
	elif event is InputEventScreenTouch:
		activa = event.pressed
	else:
		activa = event is InputEventScreenDrag
	return activa


func _actualizar_camara() -> void:
	var drift := Vector3.ZERO
	if not _reduccion_movimiento:
		drift = Vector3(
			sin(_tiempo * 0.11) * AMPLITUD_DRIFT_AMBIENTAL,
			sin(_tiempo * 0.07 + 1.3) * AMPLITUD_DRIFT_AMBIENTAL * 0.6,
			0.0
		)
	_camara.position = CAMARA_POS + _offset_pos + drift
	_camara.look_at(CAMARA_MIRA + _offset_mira, Vector3.UP)


func _actualizar_ambiente() -> void:
	if _entorno == null:
		return
	_entorno.ambient_light_energy = maxf(
		0.05, 0.30 * (1.0 - _oscurecer) * _multiplicador_luz_attract
	)


func _actualizar_fluorescente() -> void:
	if _luz_fluorescente == null:
		return
	if _tiempo >= _siguiente_fallo_fluorescente:
		_luz_fluorescente.light_energy = _energia_base * 0.15
		_siguiente_fallo_fluorescente = _tiempo + randf_range(7.0, 16.0) + 0.12
	elif _tiempo >= _siguiente_fallo_fluorescente - 0.12:
		_luz_fluorescente.light_energy = _energia_base


func _actualizar_detalles_ambientales() -> void:
	# Movimiento deliberadamente mínimo: el papel apenas vibra y el vapor sube
	# unos píxeles a la resolución interna. Son textura ambiental, no animación
	# protagonista, y desaparecen/se congelan con reducción de movimiento.
	if _papel_bandeja != null:
		_papel_bandeja.rotation.y = sin(_tiempo * 0.38) * AMPLITUD_PAPEL
		_papel_bandeja.position = (
			_papel_pos_base + Vector3(0.0, absf(sin(_tiempo * 0.31)) * 0.002, 0.0)
		)
	if _vapor_taza != null:
		_vapor_taza.position = (
			_vapor_pos_base
			+ Vector3(sin(_tiempo * 0.29) * 0.008, sin(_tiempo * 0.47) * AMPLITUD_VAPOR, 0.0)
		)
		_vapor_taza.scale = Vector3(1.0, 0.92 + 0.08 * sin(_tiempo * 0.41), 1.0)


func _construir() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "RenderInicio3D"
	_viewport.size = TAM_VIEWPORT
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	add_child(_viewport)

	var mundo := Node3D.new()
	mundo.name = "OficinaNocturna"
	_viewport.add_child(mundo)

	var world_environment := WorldEnvironment.new()
	_entorno = Environment.new()
	_entorno.background_mode = Environment.BG_COLOR
	_entorno.background_color = Color(0.015, 0.017, 0.02)
	_entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_entorno.ambient_light_color = Color(0.30, 0.34, 0.38)
	_entorno.ambient_light_energy = 0.30
	world_environment.environment = _entorno
	mundo.add_child(world_environment)

	_camara = Camera3D.new()
	_camara.fov = FOV_BASE
	_camara.near = 0.05
	_camara.far = 60.0
	_camara.current = true
	mundo.add_child(_camara)
	_actualizar_camara()

	_construir_sala(mundo)
	_construir_puesto(mundo)
	_construir_monitor(mundo)
	_construir_fluorescente(mundo)
	_construir_exterior(mundo)


func _construir_sala(raiz: Node3D) -> void:
	var color_pared := Color(0.10, 0.10, 0.11)
	var color_suelo := Color(0.07, 0.07, 0.075)
	_agregar_caja(raiz, "Suelo", Vector3(0.0, -0.05, -1.0), Vector3(6.0, 0.10, 7.0), color_suelo)

	# Marco de pared con hueco central: la ventana exterior asoma por él sin
	# necesidad de una malla con boolean cutout.
	var ancho_hueco := 1.9
	var alto_hueco := 1.2
	var centro_hueco := Vector3(0.0, 1.42, -2.5)
	var ancho_sala := 6.0
	var alto_sala := 3.0
	_agregar_caja(
		raiz,
		"ParedSuperior",
		Vector3(0.0, centro_hueco.y + alto_hueco * 0.5 + (alto_sala - alto_hueco) * 0.25, -2.5),
		Vector3(ancho_sala, alto_sala - alto_hueco, 0.12),
		color_pared
	)
	_agregar_caja(
		raiz,
		"ParedInferior",
		Vector3(0.0, centro_hueco.y - alto_hueco * 0.5 - 0.35, -2.5),
		Vector3(ancho_sala, 0.7, 0.12),
		color_pared
	)
	var ancho_lateral := (ancho_sala - ancho_hueco) * 0.5
	_agregar_caja(
		raiz,
		"ParedIzquierda",
		Vector3(-(ancho_hueco * 0.5 + ancho_lateral * 0.5), centro_hueco.y, -2.5),
		Vector3(ancho_lateral, alto_hueco, 0.12),
		color_pared
	)
	_agregar_caja(
		raiz,
		"ParedDerecha",
		Vector3(ancho_hueco * 0.5 + ancho_lateral * 0.5, centro_hueco.y, -2.5),
		Vector3(ancho_lateral, alto_hueco, 0.12),
		color_pared
	)


func _construir_puesto(raiz: Node3D) -> void:
	var base := Vector3(0.0, 0.0, -1.05)
	_agregar_caja(
		raiz,
		"Escritorio",
		Vector3(base.x, 0.375, base.z),
		Vector3(1.8, 0.75, 0.85),
		Color(0.24, 0.20, 0.15)
	)
	OficinaUtileria.montar_puesto_aislado(raiz, base, 0)

	var puesto := raiz.get_node_or_null("PuestoUtileria1")
	if puesto is Node3D:
		# La variante 0 ya trae bandeja/papeles; se suma la taza mediante el
		# helper compartido para cumplir la composición de #830 sin duplicarla.
		OficinaUtileria.agregar_taza(puesto, Vector3(-0.35, 0.86, 0.20))
		var papel := puesto.find_child("PapelBandeja", true, false)
		if papel is Node3D:
			_papel_bandeja = papel
			_papel_pos_base = _papel_bandeja.position
		_construir_vapor_taza(puesto, Vector3(-0.35, 1.07, 0.20))


func _construir_vapor_taza(raiz: Node3D, pos: Vector3) -> void:
	_vapor_taza = MeshInstance3D.new()
	_vapor_taza.name = "VaporTaza"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.07, 0.16)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.72, 0.76, 0.74, 0.16)
	material.roughness = 1.0
	quad.material = material
	_vapor_taza.mesh = quad
	_vapor_taza.position = pos
	_vapor_pos_base = pos
	raiz.add_child(_vapor_taza)


func _construir_monitor(raiz: Node3D) -> void:
	var pos_base := Vector3(0.05, 0.75, -1.20)
	var monitor := Node3D.new()
	monitor.name = "MonitorCRT"
	monitor.position = pos_base
	raiz.add_child(monitor)

	var cuerpo := MeshInstance3D.new()
	cuerpo.name = "CuerpoCRT"
	var caja := BoxMesh.new()
	caja.size = Vector3(0.42, 0.34, 0.40)
	cuerpo.mesh = caja
	cuerpo.position = Vector3(0.0, 0.20, 0.0)
	var mat_cuerpo := StandardMaterial3D.new()
	mat_cuerpo.albedo_color = Color(0.66, 0.63, 0.55)
	mat_cuerpo.roughness = 0.85
	cuerpo.material_override = mat_cuerpo
	monitor.add_child(cuerpo)

	var pantalla := MeshInstance3D.new()
	pantalla.name = "PantallaCRT"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.30, 0.23)
	_material_crt = ShaderMaterial.new()
	_material_crt.shader = CRT_SHADER
	quad.material = _material_crt
	pantalla.mesh = quad
	pantalla.position = Vector3(0.0, 0.21, 0.202)
	monitor.add_child(pantalla)

	var luz_pantalla := OmniLight3D.new()
	luz_pantalla.name = "LuzCRT"
	luz_pantalla.position = Vector3(0.0, 0.21, 0.3)
	luz_pantalla.light_color = Color(0.42, 0.95, 0.60)
	luz_pantalla.light_energy = 1.1
	luz_pantalla.omni_range = 3.5
	luz_pantalla.omni_attenuation = 1.4
	monitor.add_child(luz_pantalla)


func _construir_fluorescente(raiz: Node3D) -> void:
	_luz_fluorescente = OmniLight3D.new()
	_luz_fluorescente.name = "LuzFluorescente"
	_luz_fluorescente.position = Vector3(0.0, 2.7, -0.5)
	_luz_fluorescente.light_color = Color(0.80, 0.85, 0.86)
	_energia_base = 0.55
	_luz_fluorescente.light_energy = _energia_base
	_luz_fluorescente.omni_range = 6.0
	raiz.add_child(_luz_fluorescente)
	_siguiente_fallo_fluorescente = randf_range(7.0, 16.0)


func _construir_exterior(raiz: Node3D) -> void:
	_exterior = VentanaExterior3D.new()
	_exterior.name = "ExteriorLluvioso"
	_exterior.position = Vector3(0.0, 1.42, -2.56)
	raiz.add_child(_exterior)
	_exterior.configurar(Clima.LLUVIA)


func _agregar_caja(raiz: Node3D, nombre: String, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	malla.material_override = material
	raiz.add_child(malla)
