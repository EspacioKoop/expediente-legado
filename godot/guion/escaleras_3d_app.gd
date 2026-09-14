## Ruta jugable de escaleras para #135.
##
## Es una capa de presentación: la jornada ya ha fichado, entrado en `trayecto`
## y guardado antes de instanciarla. Aquí solo se recorre físicamente la bajada
## de planta 4 a portal con geometría provisional y controles UI estándar.
extends Node3D

signal terminada

const ORIGEN := Vector3(0.0, 0.0, 150.0)
const VELOCIDAD := 6.0
const ALTURA_CAMARA := 0.78
const ANTICIPO_MIRADA := 1.35
const ANCHO_TRAMO := 2.15
const ESCALONES_POR_TRAMO := 12

const HORMIGON := Color("55524d")
const HORMIGON_OSCURO := Color("343331")
const BORDE := Color("77716a")
const PORTAL := Color("8a806f")
const EXTERIOR := Color("111317")

# Cuatro tramos descendentes: 4 -> 3 -> 2 -> 1 -> portal. Los segmentos
# horizontales intermedios son rellanos que fuerzan el giro de la escalera.
const PUNTOS := [
	Vector3(0.0, 2.4, 3.0),
	Vector3(0.0, 1.2, -3.0),
	Vector3(3.0, 1.2, -3.0),
	Vector3(3.0, 0.0, 3.0),
	Vector3(0.0, 0.0, 3.0),
	Vector3(0.0, -1.2, -3.0),
	Vector3(3.0, -1.2, -3.0),
	Vector3(3.0, -2.4, 3.0),
	Vector3(3.0, -2.4, 5.0),
]

var _camara: Camera3D
var _distancia := 0.0
var _longitud_total := 0.0
var _terminando := false


func _ready() -> void:
	_montar_geometria()
	_calcular_longitud()
	_montar_camara()
	_actualizar_camara()


func _process(delta: float) -> void:
	if _terminando:
		return

	# `ui_up`/`ui_down` funcionan también con mando y no añaden acciones nuevas
	# al proyecto. La ruta se puede retroceder hasta el rellano inicial.
	var avance := Input.get_axis("ui_down", "ui_up")
	if not is_zero_approx(avance):
		_distancia = clampf(_distancia + avance * VELOCIDAD * delta, 0.0, _longitud_total)
		_actualizar_camara()

	if _distancia >= _longitud_total - 0.01:
		_terminando = true
		set_process(false)
		terminada.emit()


func _calcular_longitud() -> void:
	_longitud_total = 0.0
	for i in PUNTOS.size() - 1:
		_longitud_total += PUNTOS[i].distance_to(PUNTOS[i + 1])


func _posicion_en_ruta(distancia: float) -> Vector3:
	var restante := clampf(distancia, 0.0, _longitud_total)
	for i in PUNTOS.size() - 1:
		var desde: Vector3 = PUNTOS[i]
		var hasta: Vector3 = PUNTOS[i + 1]
		var longitud := desde.distance_to(hasta)
		if restante <= longitud:
			return desde.lerp(hasta, restante / longitud if longitud > 0.0 else 0.0)
		restante -= longitud
	return PUNTOS[PUNTOS.size() - 1]


func _actualizar_camara() -> void:
	var posicion := _posicion_en_ruta(_distancia)
	var objetivo := _posicion_en_ruta(minf(_distancia + ANTICIPO_MIRADA, _longitud_total))
	_camara.position = ORIGEN + posicion + Vector3.UP * ALTURA_CAMARA
	var mira := ORIGEN + objetivo + Vector3.UP * 0.38
	if _camara.position.distance_to(mira) > 0.05:
		_camara.look_at(mira, Vector3.UP)


func _montar_camara() -> void:
	_camara = Camera3D.new()
	_camara.name = "CamaraEscaleras"
	_camara.current = true
	_camara.fov = 67.0
	add_child(_camara)


func _montar_geometria() -> void:
	# Caja del hueco. Se mantiene deliberadamente sobria: el objetivo de este
	# corte es validar espacio, orientación y ritmo sin comprometer arte final.
	_caja("MuroOeste", Vector3(-1.32, 0.0, 0.9), Vector3(0.16, 6.5, 9.0), HORMIGON_OSCURO)
	_caja("MuroEste", Vector3(4.32, 0.0, 0.9), Vector3(0.16, 6.5, 9.0), HORMIGON_OSCURO)
	_caja("MuroFondo", Vector3(1.5, 0.0, -4.0), Vector3(5.8, 6.5, 0.16), HORMIGON_OSCURO)

	for i in PUNTOS.size() - 1:
		var desde: Vector3 = PUNTOS[i]
		var hasta: Vector3 = PUNTOS[i + 1]
		if is_equal_approx(desde.y, hasta.y):
			_montar_rellano("Rellano%d" % i, desde, hasta)
		else:
			_montar_tramo("Tramo%d" % i, desde, hasta)

	# Un marco muy simple hace inequívoco el final del recorrido.
	_caja("PortalIzq", Vector3(1.75, -1.15, 5.30), Vector3(0.35, 2.55, 0.20), PORTAL)
	_caja("PortalDer", Vector3(4.25, -1.15, 5.30), Vector3(0.35, 2.55, 0.20), PORTAL)
	_caja("PortalDintel", Vector3(3.0, 0.02, 5.30), Vector3(2.85, 0.28, 0.20), PORTAL)
	_caja("Exterior", Vector3(3.0, -1.15, 5.42), Vector3(2.12, 2.20, 0.04), EXTERIOR, true)

	var luz := DirectionalLight3D.new()
	luz.name = "LuzEscalera"
	luz.rotation_degrees = Vector3(-52.0, -24.0, 0.0)
	luz.light_color = Color("e1d6c4")
	luz.light_energy = 1.15
	add_child(luz)

	var luz_portal := OmniLight3D.new()
	luz_portal.name = "LuzPortal"
	luz_portal.position = ORIGEN + Vector3(3.0, -0.7, 4.55)
	luz_portal.light_color = Color("d8bf96")
	luz_portal.light_energy = 1.35
	luz_portal.omni_range = 4.5
	add_child(luz_portal)


func _montar_tramo(nombre: String, desde: Vector3, hasta: Vector3) -> void:
	var horizontal := Vector3(hasta.x - desde.x, 0.0, hasta.z - desde.z)
	var largo := horizontal.length()
	var por_x := absf(horizontal.x) > absf(horizontal.z)
	for i in ESCALONES_POR_TRAMO:
		var t := (float(i) + 0.5) / float(ESCALONES_POR_TRAMO)
		var posicion := desde.lerp(hasta, t)
		var paso := largo / float(ESCALONES_POR_TRAMO) + 0.025
		var tamano := (
			Vector3(paso, 0.12, ANCHO_TRAMO) if por_x else Vector3(ANCHO_TRAMO, 0.12, paso)
		)
		_caja("%s_Escalon%02d" % [nombre, i], posicion - Vector3(0.0, 0.08, 0.0), tamano, HORMIGON)


func _montar_rellano(nombre: String, desde: Vector3, hasta: Vector3) -> void:
	var centro := desde.lerp(hasta, 0.5) - Vector3(0.0, 0.08, 0.0)
	var delta := hasta - desde
	var tamano := Vector3(maxf(absf(delta.x), ANCHO_TRAMO), 0.14, maxf(absf(delta.z), ANCHO_TRAMO))
	_caja(nombre, centro, tamano, BORDE)


func _caja(
	nombre: String, posicion: Vector3, tamano: Vector3, color: Color, sin_luz: bool = false
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var malla := BoxMesh.new()
	malla.size = tamano
	nodo.mesh = malla
	nodo.position = ORIGEN + posicion

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if sin_luz:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	nodo.material_override = material
	add_child(nodo)
	return nodo
