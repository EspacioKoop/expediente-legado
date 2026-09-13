## Interacción ligera para los archivadores reales de la oficina (#283).
##
## No contiene documentos ni reglas de investigación. Solo hace visible la
## intención de abrir/cerrar y da una respuesta espacial inmediata.
class_name ArchivadorInteractivo3D
extends Interactuable3D

const COLOR_CAJON := Color(0.28, 0.27, 0.25)
const PROFUNDIDAD_CAJON := 0.34

var _abierto := false
var _cajon: MeshInstance3D


func configurar(tam: Vector3) -> void:
	verbo = Verbo.ABRIR
	nombre_objeto = "archivador"

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam + Vector3(0.18, 0.08, 0.18)
	colision.shape = forma
	add_child(colision)

	_cajon = MeshInstance3D.new()
	_cajon.name = "CajonAbierto"
	var malla := BoxMesh.new()
	malla.size = Vector3(PROFUNDIDAD_CAJON, 0.18, minf(tam.z * 0.78, 0.48))
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_CAJON
	malla.material = material
	_cajon.mesh = malla
	_cajon.position = Vector3(-tam.x * 0.52, tam.y * 0.18, 0.0)
	_cajon.visible = false
	add_child(_cajon)

	activado.connect(_alternar)


func esta_abierto() -> bool:
	return _abierto


func _alternar(_actor: Node) -> void:
	_abierto = not _abierto
	_cajon.visible = _abierto
	verbo = Verbo.CERRAR if _abierto else Verbo.ABRIR
