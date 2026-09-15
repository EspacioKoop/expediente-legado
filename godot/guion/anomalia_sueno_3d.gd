## Objeto familiar del día devuelto deformado por el sueño (#400 / #149).
##
## Es una microinteracción local: no escribe Partida/Jornada ni concede progreso.
## Mirarlo y usar `interactuar` alterna una segunda deformación, mantiene la luz
## local y emite `observada` con un ID estable de catálogo. La persistencia y la
## idempotencia pertenecen a CatalogoAnomalias/Partida, no a este componente 3D.
class_name AnomaliaSueno3D
extends Interactuable3D

signal observada(anomalia_id: String, actor: Node)

const COLOR_LUZ := Color(0.58, 0.48, 0.82)

var _catalogo_id := ""
var _visual: Node3D
var _luz: OmniLight3D
var _escala_base := Vector3.ONE
var _escala_reaccion := Vector3.ONE
var _giro_base := Vector3.ZERO
var _giro_reaccion := Vector3.ZERO
var _reactiva := false


func configurar(
	catalogo_id: String,
	modelo: String,
	tam: Vector3,
	color: Color,
	nombre: String,
	escala_base: Vector3,
	escala_reaccion: Vector3,
	giro_base: Vector3,
	giro_reaccion: Vector3,
) -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = nombre
	_catalogo_id = catalogo_id.strip_edges()
	_escala_base = escala_base
	_escala_reaccion = escala_reaccion
	_giro_base = giro_base
	_giro_reaccion = giro_reaccion

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(
		tam.x * absf(escala_base.x),
		tam.y * absf(escala_base.y),
		tam.z * absf(escala_base.z),
	)
	colision.shape = forma
	add_child(colision)

	_visual = Node3D.new()
	_visual.name = "FormaDeformada"
	add_child(_visual)
	if not Modelos.mueble(_visual, modelo, tam, color):
		_montar_respaldo(tam, color)
	_aplicar_estado_visual()

	_luz = OmniLight3D.new()
	_luz.name = "RespuestaLuz"
	_luz.light_color = COLOR_LUZ
	_luz.light_energy = 1.15
	_luz.omni_range = 3.2
	_luz.position = Vector3(0.0, maxf(0.8, tam.y), 0.0)
	_luz.visible = false
	add_child(_luz)

	activado.connect(_alternar)
	activado.connect(_emitir_observacion)


func id_catalogo() -> String:
	return _catalogo_id


func reactiva() -> bool:
	return _reactiva


func escala_visual() -> Vector3:
	return _visual.scale


func luz_visible() -> bool:
	return _luz.visible


func _alternar(_actor: Node) -> void:
	_reactiva = not _reactiva
	_aplicar_estado_visual()
	_luz.visible = _reactiva


func _emitir_observacion(actor: Node) -> void:
	if _catalogo_id.is_empty():
		push_warning("Anomalía 3D sin ID de catálogo")
		return
	observada.emit(_catalogo_id, actor)


func _aplicar_estado_visual() -> void:
	if _visual == null:
		return
	_visual.scale = _escala_reaccion if _reactiva else _escala_base
	_visual.rotation_degrees = _giro_reaccion if _reactiva else _giro_base


func _montar_respaldo(tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	malla.name = "RespaldoGeometrico"
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	malla.material_override = material
	_visual.add_child(malla)
