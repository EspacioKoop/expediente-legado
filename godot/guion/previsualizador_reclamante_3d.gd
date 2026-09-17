## Ventana 3D de la Ventanilla (#779).
##
## El reclamante deja de ser solo un nombre: está al otro lado del mostrador y
## reacciona a cada resolución. Las pruebas presentadas quedan físicamente sobre
## la mesa como sellos; no cambian reglas aquí, solo cuentan lo ya resuelto por
## `CareoDocumental`.
class_name PrevisualizadorReclamante3D
extends SubViewportContainer

const TAM_VIEWPORT := Vector2i(360, 250)

var reduccion_movimiento := false

var _viewport: SubViewport
var _mundo: Node3D
var _figura: Node3D
var _sellos: Node3D
var _tween: Tween
var _cantidad_sellos := 0


func _ready() -> void:
	custom_minimum_size = Vector2(TAM_VIEWPORT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_montar_mundo()


func mostrar(rival: Dictionary) -> void:
	if _mundo == null:
		return
	if _figura != null:
		_figura.queue_free()
	var clave := String(rival.get("id", rival.get("nombre", "reclamante")))
	var matiz := 0.52 + float(absi(hash(clave)) % 14) / 100.0
	_figura = FiguraSilueta.construir(
		_mundo, Vector3(0.0, 0.0, -0.75), Color.from_hsv(matiz, 0.28, 0.72)
	)
	_figura.rotation.y = PI
	_limpiar_sellos()


func reaccion(ronda: Dictionary) -> void:
	if _figura == null:
		return
	if not ronda.get("evidencia", {}).is_empty():
		_agregar_sello(int(ronda.get("impacto_evidencia", 0)) > 0)
	if reduccion_movimiento:
		return

	if _tween != null and _tween.is_running():
		_tween.kill()
	_figura.position = Vector3(0.0, 0.0, -0.75)
	_figura.rotation.z = 0.0
	_tween = create_tween()
	if int(ronda.get("dano_al_rival", 0)) > 0:
		_tween.tween_property(_figura, "position:z", -1.05, 0.10)
		_tween.parallel().tween_property(_figura, "rotation:z", -0.08, 0.10)
	else:
		_tween.tween_property(_figura, "position:z", -0.56, 0.10)
	_tween.tween_property(_figura, "position:z", -0.75, 0.16)
	_tween.parallel().tween_property(_figura, "rotation:z", 0.0, 0.16)


func _montar_mundo() -> void:
	_viewport = SubViewport.new()
	_viewport.size = TAM_VIEWPORT
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.own_world_3d = true
	add_child(_viewport)

	_mundo = Node3D.new()
	_viewport.add_child(_mundo)

	var entorno_mundo := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.055, 0.06, 0.07)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.58, 0.60, 0.56)
	entorno.ambient_light_energy = 0.72
	entorno_mundo.environment = entorno
	_mundo.add_child(entorno_mundo)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-48.0, -22.0, 0.0)
	luz.light_energy = 1.15
	_mundo.add_child(luz)

	var camara := Camera3D.new()
	camara.position = Vector3(0.0, 2.0, 4.0)
	camara.fov = 43.0
	_mundo.add_child(camara)
	camara.look_at(Vector3(0.0, 1.0, -0.3), Vector3.UP)

	var suelo := MeshInstance3D.new()
	var malla_suelo := BoxMesh.new()
	malla_suelo.size = Vector3(5.5, 0.08, 4.0)
	suelo.mesh = malla_suelo
	suelo.position = Vector3(0.0, -0.08, -0.2)
	suelo.material_override = _material(Color(0.18, 0.19, 0.17))
	_mundo.add_child(suelo)

	var mostrador := MeshInstance3D.new()
	var malla_mostrador := BoxMesh.new()
	malla_mostrador.size = Vector3(3.0, 0.72, 0.78)
	mostrador.mesh = malla_mostrador
	mostrador.position = Vector3(0.0, 0.34, 0.35)
	mostrador.material_override = _material(Color(0.34, 0.28, 0.20))
	_mundo.add_child(mostrador)

	_sellos = Node3D.new()
	_sellos.name = "SellosEvidencia"
	_mundo.add_child(_sellos)


func _agregar_sello(acierto: bool) -> void:
	if _sellos == null:
		return
	var sello := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = 0.16
	malla.bottom_radius = 0.16
	malla.height = 0.025
	malla.radial_segments = 12
	sello.mesh = malla
	var columna := _cantidad_sellos % 5
	var fila := _cantidad_sellos / 5
	sello.position = Vector3(-0.85 + float(columna) * 0.42, 0.725, 0.18 - float(fila) * 0.22)
	sello.material_override = _material(
		Color(0.58, 0.08, 0.06) if acierto else Color(0.28, 0.29, 0.27)
	)
	_sellos.add_child(sello)
	_cantidad_sellos += 1


func _limpiar_sellos() -> void:
	_cantidad_sellos = 0
	if _sellos == null:
		return
	for hijo in _sellos.get_children():
		hijo.queue_free()


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material