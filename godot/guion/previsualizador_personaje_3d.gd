## Visor 3D en vivo para la ficha del protagonista (#701).
##
## Renderiza a baja resolución la misma `CuerpoJugador3D` que usa el caminante,
## pero en modo exterior: pies apoyados, cabeza visible y vestuario completo. El
## control solo recibe perfiles ya normalizados; no lee ni escribe la partida.
## Arrastrar con el botón izquierdo gira la figura para comparar la silueta.
class_name PrevisualizadorPersonaje3D
extends SubViewportContainer

const TAM_VIEWPORT := Vector2i(288, 360)
const TAM_MINIMO := Vector2(250.0, 330.0)
const ANGULO_INICIAL := -0.20
const SENSIBILIDAD_GIRO := 0.012

var _perfil: Dictionary = PerfilJugador.nuevo()
var _vista: SubViewport
var _mundo: Node3D
var _pedestal: Node3D
var _cuerpo: CuerpoJugador3D
var _camara: Camera3D
var _arrastrando := false
var _angulo := ANGULO_INICIAL


func _ready() -> void:
	custom_minimum_size = TAM_MINIMO
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_construir()
	aplicar(_perfil)


func aplicar(valor: Dictionary) -> void:
	_perfil = PerfilJugador.completar(valor)
	if _cuerpo == null:
		return
	_cuerpo.aplicar(_perfil)


## Accesores mínimos para smoke tests; el creador solo usa `aplicar`.
func cuerpo() -> CuerpoJugador3D:
	return _cuerpo


func vista() -> SubViewport:
	return _vista


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = evento.pressed
		accept_event()
		return
	if evento is InputEventMouseMotion and _arrastrando and _pedestal != null:
		_angulo = wrapf(_angulo - evento.relative.x * SENSIBILIDAD_GIRO, -PI, PI)
		_pedestal.rotation.y = _angulo
		accept_event()


func _construir() -> void:
	if _vista != null:
		return

	_vista = SubViewport.new()
	_vista.name = "VistaPersonaje"
	_vista.size = TAM_VIEWPORT
	_vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vista.own_world_3d = true
	_vista.msaa_3d = Viewport.MSAA_DISABLED
	_vista.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	add_child(_vista)

	_mundo = Node3D.new()
	_mundo.name = "EstudioPersonaje"
	_vista.add_child(_mundo)

	var world_environment := WorldEnvironment.new()
	world_environment.name = "EntornoPersonaje"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color("11161d")
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.63, 0.66, 0.70)
	entorno.ambient_light_energy = 0.78
	world_environment.environment = entorno
	_mundo.add_child(world_environment)

	var principal := DirectionalLight3D.new()
	principal.name = "LuzPrincipal"
	principal.rotation_degrees = Vector3(-34.0, -28.0, 0.0)
	principal.light_color = Color(1.0, 0.91, 0.78)
	principal.light_energy = 1.35
	principal.shadow_enabled = true
	_mundo.add_child(principal)

	var relleno := OmniLight3D.new()
	relleno.name = "LuzRelleno"
	relleno.position = Vector3(-1.4, 1.25, 1.7)
	relleno.light_color = Color(0.62, 0.72, 0.92)
	relleno.light_energy = 0.65
	relleno.omni_range = 5.0
	_mundo.add_child(relleno)

	_montar_suelo()

	_pedestal = Node3D.new()
	_pedestal.name = "Pedestal"
	_pedestal.rotation.y = _angulo
	_mundo.add_child(_pedestal)

	_cuerpo = CuerpoJugador3D.new()
	_cuerpo.name = "CuerpoPrevisualizado"
	_cuerpo.primera_persona = false
	_pedestal.add_child(_cuerpo)

	_camara = Camera3D.new()
	_camara.name = "CamaraFicha"
	_camara.position = Vector3(0.0, 0.92, 3.15)
	_camara.fov = 34.0
	_camara.near = 0.05
	_camara.far = 12.0
	_mundo.add_child(_camara)
	_camara.look_at(Vector3(0.0, 0.86, 0.0), Vector3.UP)
	_camara.current = true


func _montar_suelo() -> void:
	var suelo := MeshInstance3D.new()
	suelo.name = "SueloFicha"
	var plano := PlaneMesh.new()
	plano.size = Vector2(3.4, 3.4)
	suelo.mesh = plano
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("20262d")
	material.roughness = 1.0
	suelo.material_override = material
	_mundo.add_child(suelo)
