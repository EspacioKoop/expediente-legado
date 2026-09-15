## Contraparte de vigilia del sueño de la Hidra (#439).
##
## HYDRA_LOOP puede estar visible en casa sin contaminar el sueño. La semilla
## solo se activa después de dos EXAMINAR deliberados: arrancar la ROM y volver
## a interactuar tras comprobar que cortar cabezas empeora la pantalla.
class_name HidraVigilia
extends Interactuable3D

const ID_MITO := "hidra"
const FUENTE := "rom:hydra_loop_98"
const INTERACCIONES_REQUERIDAS := 2

var _jornada: Dictionary = {}
var _interacciones := 0
var _activada := false
var _objeto: Node3D
var _pantalla: MeshInstance3D


func _ready() -> void:
	_configurar_prompt()
	_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _objeto == null:
		_montar()
	if not activado.is_connected(_al_examinar):
		activado.connect(_al_examinar)
	_intentar_activar()


func interacciones_deliberadas() -> int:
	return _interacciones


func esta_activada() -> bool:
	return _activada


func estado_hydra_loop() -> String:
	if _activada:
		return "nodo_comun_detectado"
	if _interacciones == 1:
		return "sintomas_proliferan"
	return "cartucho_sin_arrancar"


## 1ª acción: arrancar HYDRA_LOOP y ver la proliferación.
## 2ª acción: insistir/observar el patrón hasta localizar el nodo compartido.
## La mera presencia del cartucho no llama nunca a SemillasOniricas.
func _al_examinar(_actor: Node) -> void:
	_interacciones = mini(_interacciones + 1, INTERACCIONES_REQUERIDAS)
	_actualizar_feedback()
	_intentar_activar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	if _interacciones < INTERACCIONES_REQUERIDAS:
		return false
	_activada = SemillasOniricas.activar_semilla_onirica(_jornada, ID_MITO, FUENTE, 2)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "cartucho HYDRA_LOOP"


func _montar() -> void:
	_objeto = Node3D.new()
	_objeto.name = "CartuchoHydraLoop"
	add_child(_objeto)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.6, 0.35, 1.0)
	colision.shape = forma
	add_child(colision)

	var carcasa := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(1.5, 0.28, 0.9)
	carcasa.mesh = caja
	_objeto.add_child(carcasa)

	_pantalla = MeshInstance3D.new()
	_pantalla.name = "EtiquetaHydraLoop"
	var etiqueta := QuadMesh.new()
	etiqueta.size = Vector2(1.05, 0.55)
	_pantalla.mesh = etiqueta
	_pantalla.position = Vector3(0.0, 0.15, 0.0)
	_pantalla.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_objeto.add_child(_pantalla)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _pantalla == null:
		return
	var material := StandardMaterial3D.new()
	match estado_hydra_loop():
		"nodo_comun_detectado":
			material.albedo_color = Color(0.18, 0.58, 0.28)
		"sintomas_proliferan":
			material.albedo_color = Color(0.70, 0.18, 0.12)
		_:
			material.albedo_color = Color(0.16, 0.22, 0.18)
	material.roughness = 0.72
	_pantalla.material_override = material
