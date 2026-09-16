## Contraparte de vigilia para Mari (#651 / #442).
##
## Es un folleto doméstico/de excursión: estar presente no activa nada. El
## jugador debe leerlo, desplegarlo y seguir una ruta entre cueva y montaña.
class_name MariVigilia
extends Interactuable3D

const FUENTE := "folleto:cuevas_montana_98"
const INSPECCIONES_MINIMAS := 2

const COLOR_PAPEL := Color(0.72, 0.68, 0.55)
const COLOR_TINTA := Color(0.22, 0.24, 0.21)
const COLOR_RUTA := Color(0.38, 0.48, 0.40)
const COLOR_ACTIVO := Color(0.62, 0.53, 0.30)

var _jornada: Dictionary = {}
var _folleto: Node3D
var _ruta: MeshInstance3D
var _inspecciones := 0
var _desplegado := false
var _ruta_trazada := false
var _activada := false


func _ready() -> void:
	_configurar_prompt()
	if _folleto == null:
		_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _folleto == null:
		_montar()
	if not activado.is_connected(_al_examinar):
		activado.connect(_al_examinar)
	_intentar_activar()


func inspecciones() -> int:
	return _inspecciones


func esta_desplegado() -> bool:
	return _desplegado


func ruta_trazada() -> bool:
	return _ruta_trazada


func esta_activada() -> bool:
	return _activada


## 1-2: leer anverso/reverso; 3: desplegar; 4: seguir la ruta impresa. De este
## modo la semilla exige una decisión sostenida y no se dispara por proximidad.
func examinar() -> bool:
	if _inspecciones < INSPECCIONES_MINIMAS:
		_inspecciones += 1
	elif not _desplegado:
		_desplegado = true
	else:
		_ruta_trazada = true
	_actualizar_feedback()
	return _intentar_activar()


func _al_examinar(_actor: Node) -> void:
	examinar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	_activada = (
		SuenoMari
		. registrar_semilla(
			_jornada,
			_inspecciones,
			_desplegado,
			_ruta_trazada,
			FUENTE,
			2,
		)
	)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "folleto de cuevas y montaña"


func _montar() -> void:
	_folleto = Node3D.new()
	_folleto.name = "FolletoMari"
	add_child(_folleto)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionFolletoMari"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.8, 1.1, 0.18)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.55, 0.0)
	add_child(colision)

	_agregar_caja(_folleto, "Papel", Vector3(1.75, 1.05, 0.06), Vector3(0.0, 0.55, 0.0), COLOR_PAPEL)
	_agregar_caja(_folleto, "Pliegue", Vector3(0.05, 0.92, 0.03), Vector3(0.0, 0.55, -0.05), COLOR_TINTA)
	_agregar_caja(_folleto, "Montana", Vector3(0.52, 0.42, 0.03), Vector3(-0.43, 0.72, -0.06), COLOR_TINTA)
	_agregar_caja(_folleto, "Cueva", Vector3(0.44, 0.32, 0.03), Vector3(0.48, 0.36, -0.06), COLOR_TINTA)
	_ruta = _agregar_caja(
		_folleto,
		"RutaImpresa",
		Vector3(1.02, 0.055, 0.03),
		Vector3(0.02, 0.53, -0.075),
		COLOR_RUTA,
	)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _ruta == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_ACTIVO if _activada else COLOR_RUTA
	material.roughness = 0.80
	material.emission_enabled = _desplegado
	if material.emission_enabled:
		material.emission = COLOR_RUTA
		material.emission_energy_multiplier = 0.95 if _ruta_trazada else 0.35
	_ruta.material_override = material
	_ruta.scale.x = 1.12 if _ruta_trazada else 1.0
	_folleto.scale.x = 1.12 if _desplegado else 1.0


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
