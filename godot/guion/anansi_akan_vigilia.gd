## Contraparte doméstica del sueño de Anansi akan (#656 / #442).
##
## La cinta es ficticia y propia del proyecto. Estar colocada en casa no activa
## nada: el jugador debe avanzar deliberadamente por tres tramos y terminar la
## escucha. No se copian audio, ilustraciones ni textos de fuentes culturales.
class_name AnansiAkanVigilia
extends Interactuable3D

const ID_MITO := "anansi_akan"
const FUENTE := "cassette:anansi_akan_relato_98"
const PASOS_MINIMOS := 3

const COLOR_CARCASA := Color(0.18, 0.16, 0.13)
const COLOR_ETIQUETA := Color(0.72, 0.64, 0.48)
const COLOR_CINTA := Color(0.08, 0.07, 0.06)
const COLOR_FIN := Color(0.55, 0.42, 0.18)

var _jornada: Dictionary = {}
var _pasos_escuchados := 0
var _terminada := false
var _activada := false
var _etiqueta: MeshInstance3D


func _ready() -> void:
	_configurar_prompt()
	if _etiqueta == null:
		_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _etiqueta == null:
		_montar()
	if not activado.is_connected(_al_usar):
		activado.connect(_al_usar)
	_intentar_activar()


func escuchar() -> bool:
	if _terminada:
		return _activada
	_pasos_escuchados = mini(_pasos_escuchados + 1, PASOS_MINIMOS)
	_terminada = _pasos_escuchados >= PASOS_MINIMOS
	_intentar_activar()
	_actualizar_feedback()
	return _terminada


func pasos_escuchados() -> int:
	return _pasos_escuchados


func relato_terminado() -> bool:
	return _terminada


func esta_activada() -> bool:
	return _activada


func _al_usar(_actor: Node) -> void:
	escuchar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	_activada = (
		SuenoAnansiAkan
		. registrar_semilla(
			_jornada,
			_pasos_escuchados,
			_terminada,
			FUENTE,
			2,
		)
	)
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "cassette de relatos"
	sonido = SIN_SONIDO


func _montar() -> void:
	var colision := CollisionShape3D.new()
	colision.name = "ColisionCassette"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.55, 0.24, 0.96)
	colision.shape = forma
	add_child(colision)

	_crear_caja(
		self,
		"Carcasa",
		Vector3(1.55, 0.22, 0.96),
		Vector3.ZERO,
		COLOR_CARCASA,
	)
	_etiqueta = _crear_caja(
		self,
		"Etiqueta",
		Vector3(1.15, 0.035, 0.50),
		Vector3(0.0, 0.13, -0.03),
		COLOR_ETIQUETA,
	)
	_crear_bobina("BobinaIzquierda", Vector3(-0.35, 0.16, 0.04))
	_crear_bobina("BobinaDerecha", Vector3(0.35, 0.16, 0.04))
	_actualizar_feedback()


func _crear_bobina(nombre: String, posicion: Vector3) -> void:
	var malla := CylinderMesh.new()
	malla.top_radius = 0.16
	malla.bottom_radius = 0.16
	malla.height = 0.05
	malla.radial_segments = 16
	var bobina := MeshInstance3D.new()
	bobina.name = nombre
	bobina.mesh = malla
	bobina.position = posicion
	bobina.material_override = _material(COLOR_CINTA)
	add_child(bobina)


func _actualizar_feedback() -> void:
	if _etiqueta == null:
		return
	_etiqueta.material_override = _material(COLOR_FIN if _terminada else COLOR_ETIQUETA)
	set_meta("anansi_pasos_escuchados", _pasos_escuchados)
	set_meta("anansi_relato_terminado", _terminada)
	set_meta("anansi_semilla_activada", _activada)


func _crear_caja(
	padre: Node,
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
	nodo.material_override = _material(color)
	padre.add_child(nodo)
	return nodo


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material
