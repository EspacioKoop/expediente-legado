## Contraparte doméstica de Yggdrasil (#653 / #442).
##
## El póster puede existir sin activar nada. El jugador debe examinarlo al menos
## dos veces y después seguir deliberadamente una conexión entre sus nodos.
class_name YggdrasilVigilia
extends Interactuable3D

const FUENTE := "poster:yggdrasil_98"
const INSPECCIONES_MINIMAS := 2

const COLOR_MARCO := Color(0.18, 0.13, 0.09)
const COLOR_PAPEL := Color(0.70, 0.66, 0.54)
const COLOR_TINTA := Color(0.25, 0.22, 0.16)
const COLOR_CONEXION := Color(0.45, 0.34, 0.18)
const COLOR_ACTIVO := Color(0.78, 0.62, 0.26)

var _jornada: Dictionary = {}
var _poster: Node3D
var _conexion: MeshInstance3D
var _inspecciones := 0
var _conexion_reconocida := false
var _activada := false


func _ready() -> void:
	_configurar_prompt()
	if _poster == null:
		_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _poster == null:
		_montar()
	if not activado.is_connected(_al_examinar):
		activado.connect(_al_examinar)
	_intentar_activar()


func inspecciones() -> int:
	return _inspecciones


func conexion_reconocida() -> bool:
	return _conexion_reconocida


func esta_activada() -> bool:
	return _activada


## Las dos primeras interacciones observan nodos; la tercera sigue una línea
## entre ellos. Ese gesto completa la interacción deliberada exigida por #442.
func examinar() -> bool:
	if _inspecciones < INSPECCIONES_MINIMAS:
		_inspecciones += 1
	else:
		_conexion_reconocida = true
	_actualizar_feedback()
	return _intentar_activar()


func _al_examinar(_actor: Node) -> void:
	examinar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	_activada = SuenoYggdrasil.registrar_semilla(
		_jornada,
		_inspecciones,
		_conexion_reconocida,
		FUENTE,
		2,
	)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "póster de árbol ramificado"


func _montar() -> void:
	_poster = Node3D.new()
	_poster.name = "PosterYggdrasil"
	add_child(_poster)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionPosterYggdrasil"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.9, 1.45, 0.18)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.72, 0.0)
	add_child(colision)

	_agregar_caja(_poster, "Marco", Vector3(2.05, 1.55, 0.12), Vector3(0.0, 0.78, 0.0), COLOR_MARCO)
	_agregar_caja(_poster, "Papel", Vector3(1.78, 1.28, 0.05), Vector3(0.0, 0.78, -0.08), COLOR_PAPEL)
	_agregar_caja(_poster, "Tronco", Vector3(0.16, 0.92, 0.035), Vector3(0.0, 0.78, -0.13), COLOR_TINTA)
	_agregar_caja(_poster, "NodoIzquierdo", Vector3(0.26, 0.26, 0.035), Vector3(-0.56, 1.12, -0.14), COLOR_TINTA)
	_agregar_caja(_poster, "NodoDerecho", Vector3(0.26, 0.26, 0.035), Vector3(0.56, 1.12, -0.14), COLOR_TINTA)
	_agregar_caja(_poster, "NodoRaiz", Vector3(0.26, 0.26, 0.035), Vector3(0.0, 0.30, -0.14), COLOR_TINTA)
	_conexion = _agregar_caja(
		_poster,
		"ConexionVisible",
		Vector3(1.15, 0.07, 0.03),
		Vector3(0.0, 1.02, -0.15),
		COLOR_CONEXION,
	)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _conexion == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_ACTIVO if _activada else COLOR_CONEXION
	material.roughness = 0.78
	material.emission_enabled = _inspecciones >= INSPECCIONES_MINIMAS
	if material.emission_enabled:
		material.emission = COLOR_CONEXION
		material.emission_energy_multiplier = 1.0 if _conexion_reconocida else 0.45
	_conexion.material_override = material
	_conexion.scale.x = 1.08 if _conexion_reconocida else 1.0


func _agregar_caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
