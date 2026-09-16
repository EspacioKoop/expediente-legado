## Radio doméstica/trayecto para activar Tír na nÓg (#654 / #442).
##
## Estar cerca de la radio no cuenta. El jugador debe sintonizar el programa y
## escuchar dos tramos hasta su cierre; solo entonces se registra la semilla.
class_name TirNaNogVigilia
extends Interactuable3D

const FUENTE := "radio:tir_na_nog_98"
const SEGMENTOS_REQUERIDOS := 2
const SIN_SONIDO := ""

const COLOR_CARCASA := Color(0.22, 0.19, 0.16)
const COLOR_DIAL := Color(0.66, 0.55, 0.34)
const COLOR_SINTONIA := Color(0.34, 0.56, 0.44)

var _jornada: Dictionary = {}
var _radio: Node3D
var _dial: MeshInstance3D
var _programa_sintonizado := false
var _segmentos_escuchados := 0
var _activada := false


func _ready() -> void:
	_configurar_prompt()
	if _radio == null:
		_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _radio == null:
		_montar()
	if not activado.is_connected(_al_usar):
		activado.connect(_al_usar)
	_intentar_activar()


func programa_sintonizado() -> bool:
	return _programa_sintonizado


func segmentos_escuchados() -> int:
	return _segmentos_escuchados


func esta_activada() -> bool:
	return _activada


func sintonizar_programa() -> bool:
	_programa_sintonizado = true
	_actualizar_feedback()
	return _intentar_activar()


func escuchar_segmento() -> bool:
	if not _programa_sintonizado:
		return false
	_segmentos_escuchados = mini(_segmentos_escuchados + 1, SEGMENTOS_REQUERIDOS)
	_actualizar_feedback()
	return _intentar_activar()


## Interacción diegética compacta: primera pulsación sintoniza; las siguientes
## escuchan los dos tramos. Encender y marcharse nunca activa por sí solo.
func usar() -> bool:
	if not _programa_sintonizado:
		return sintonizar_programa()
	return escuchar_segmento()


func _al_usar(_actor: Node) -> void:
	usar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	_activada = SuenoTirNaNog.registrar_semilla(
		_jornada,
		_programa_sintonizado,
		_segmentos_escuchados >= SEGMENTOS_REQUERIDOS,
		FUENTE,
		2,
	)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "radio portátil"
	sonido = SIN_SONIDO


func _montar() -> void:
	_radio = Node3D.new()
	_radio.name = "RadioTirNaNog"
	add_child(_radio)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionRadio"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.45, 0.85, 0.48)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.43, 0.0)
	add_child(colision)

	_agregar_caja(
		_radio, "Carcasa", Vector3(1.45, 0.85, 0.48), Vector3(0.0, 0.43, 0.0), COLOR_CARCASA
	)
	_agregar_caja(
		_radio, "Altavoz", Vector3(0.68, 0.46, 0.04), Vector3(-0.30, 0.43, -0.265), Color(0.14, 0.13, 0.12)
	)
	_dial = _agregar_caja(
		_radio, "Dial", Vector3(0.38, 0.16, 0.04), Vector3(0.43, 0.58, -0.27), COLOR_DIAL
	)
	_agregar_caja(
		_radio, "Mando", Vector3(0.20, 0.20, 0.10), Vector3(0.48, 0.30, -0.28), COLOR_DIAL.darkened(0.2)
	)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _dial == null:
		return
	var material := StandardMaterial3D.new()
	material.roughness = 0.76
	material.albedo_color = COLOR_SINTONIA if _programa_sintonizado else COLOR_DIAL
	material.emission_enabled = _programa_sintonizado
	if material.emission_enabled:
		material.emission = COLOR_SINTONIA
		material.emission_energy_multiplier = 0.35 + 0.25 * float(_segmentos_escuchados)
	_dial.material_override = material
	_dial.scale.x = 1.08 if _activada else 1.0


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
