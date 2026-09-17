## Ventana 3D de la Ventanilla (#779).
##
## El reclamante deja de ser solo un nombre: está al otro lado del mostrador y
## reacciona a cada resolución. Las pruebas presentadas quedan físicamente sobre
## la mesa como sellos; no cambian reglas aquí, solo cuentan lo ya resuelto por
## `CareoDocumental`. Cada ronda deja además las dos jugadas como fichas físicas
## sobre el mostrador y usa el catálogo común de sonido para distinguirlas.
class_name PrevisualizadorReclamante3D
extends SubViewportContainer

const TAM_VIEWPORT := Vector2i(360, 250)
const SONIDOS_JUGADA := {
	"objecion": "firmar",
	"silencio": "pulsar",
	"insistencia": "marcar",
}

var reduccion_movimiento := false

var _viewport: SubViewport
var _mundo: Node3D
var _figura: Node3D
var _sellos: Node3D
var _jugadas: Node3D
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
	_limpiar_jugadas()


func reaccion(ronda: Dictionary) -> void:
	if _figura == null:
		return
	_agregar_jugadas(ronda)
	_reproducir_jugada(String(ronda.get("tipo_jugador", "")))
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


static func sonido_jugada(tipo: String) -> String:
	return String(SONIDOS_JUGADA.get(tipo, ""))


func _reproducir_jugada(tipo: String) -> void:
	var nombre := sonido_jugada(tipo)
	if nombre.is_empty():
		return
	Sonido.sonar(self, nombre)


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

	_jugadas = Node3D.new()
	_jugadas.name = "JugadasRonda"
	_mundo.add_child(_jugadas)


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


func _agregar_jugadas(ronda: Dictionary) -> void:
	if _jugadas == null:
		return
	_limpiar_jugadas()
	var veredicto := String(ronda.get("veredicto", "empate"))
	_crear_ficha_jugada(
		String(ronda.get("tipo_jugador", "")),
		Vector3(-0.48, 0.735, 0.48),
		veredicto == "gana_jugador"
	)
	_crear_ficha_jugada(
		String(ronda.get("tipo_rival", "")),
		Vector3(0.48, 0.735, 0.48),
		veredicto == "gana_rival"
	)


func _crear_ficha_jugada(tipo: String, posicion: Vector3, destacada: bool) -> void:
	if tipo.is_empty():
		return
	var ficha := MeshInstance3D.new()
	ficha.name = "Jugada_%s" % tipo
	ficha.mesh = _malla_jugada(tipo)
	ficha.position = posicion
	ficha.material_override = _material(_color_jugada(tipo))
	if destacada:
		ficha.scale = Vector3(1.28, 1.0, 1.28)
		ficha.position.y += 0.025
	_jugadas.add_child(ficha)


func _malla_jugada(tipo: String) -> PrimitiveMesh:
	if tipo == "objecion":
		var caja := BoxMesh.new()
		caja.size = Vector3(0.28, 0.035, 0.28)
		return caja
	var ficha := CylinderMesh.new()
	ficha.top_radius = 0.15
	ficha.bottom_radius = 0.15
	ficha.height = 0.035
	ficha.radial_segments = 16 if tipo == "silencio" else 3
	return ficha


func _color_jugada(tipo: String) -> Color:
	match tipo:
		"objecion":
			return Color(0.62, 0.11, 0.08)
		"silencio":
			return Color(0.18, 0.36, 0.58)
		_:
			return Color(0.70, 0.52, 0.08)


func _limpiar_sellos() -> void:
	_cantidad_sellos = 0
	if _sellos == null:
		return
	for hijo in _sellos.get_children():
		hijo.queue_free()


func _limpiar_jugadas() -> void:
	if _jugadas == null:
		return
	for hijo in _jugadas.get_children():
		hijo.queue_free()


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material
