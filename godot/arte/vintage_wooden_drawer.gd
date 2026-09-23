## Adaptación low-poly de `Vintage Wooden Drawer 01` de Poly Haven.
## Fuente: https://polyhaven.com/a/vintage_wooden_drawer_01
## Autor original: James Ray Cock. Licencia del asset de referencia: CC0-1.0.
##
## Poly Haven publica el original con 0,9 m de ancho y ~5K triángulos. Aquí no
## se redistribuye su GLB ni sus texturas: se reconstruye su silueta funcional
## (cuerpo, seis cajones y herrajes) con primitivas compartidas para evitar LFS,
## dependencias de packs y materiales externos. Es una adaptación derivada CC0
## deliberadamente austera para el lenguaje visual PSX de SIGA-98.
class_name VintageWoodenDrawer
extends RefCounted

const CAJONES := 6
const TAMANO := Vector3(0.90, 1.12, 0.46)
const COLOR_CUERPO := Color(0.24, 0.16, 0.10)
const COLOR_CAJON := Color(0.31, 0.21, 0.13)
const COLOR_LATON := Color(0.52, 0.39, 0.17)

static var _cuerpo: BoxMesh
static var _cajon: BoxMesh
static var _tirador: BoxMesh
static var _etiqueta: BoxMesh


static func crear() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "VintageWoodenDrawerVisual"

	var cuerpo := MeshInstance3D.new()
	cuerpo.name = "CuerpoArchivador"
	cuerpo.mesh = _malla_cuerpo()
	raiz.add_child(cuerpo)

	raiz.add_child(_multimesh("FrentesCajones", _malla_cajon(), _transformaciones_cajones()))
	raiz.add_child(_multimesh("TiradoresLaton", _malla_tirador(), _transformaciones_tiradores()))
	raiz.add_child(_multimesh("MarcosEtiqueta", _malla_etiqueta(), _transformaciones_etiquetas()))
	return raiz


static func _malla_cuerpo() -> BoxMesh:
	if _cuerpo == null:
		_cuerpo = _caja(TAMANO, COLOR_CUERPO)
	return _cuerpo


static func _malla_cajon() -> BoxMesh:
	if _cajon == null:
		_cajon = _caja(Vector3(0.82, 0.145, 0.045), COLOR_CAJON)
	return _cajon


static func _malla_tirador() -> BoxMesh:
	if _tirador == null:
		_tirador = _caja(Vector3(0.18, 0.035, 0.035), COLOR_LATON)
	return _tirador


static func _malla_etiqueta() -> BoxMesh:
	if _etiqueta == null:
		_etiqueta = _caja(Vector3(0.13, 0.045, 0.018), COLOR_LATON)
	return _etiqueta


static func _caja(tamano: Vector3, color: Color) -> BoxMesh:
	var caja := BoxMesh.new()
	caja.size = tamano
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.shader_del_sitio())
	material.set_shader_parameter("color_base", color)
	caja.material = material
	return caja


static func _multimesh(
	nombre: String, malla: Mesh, transformaciones: Array[Transform3D]
) -> MultiMeshInstance3D:
	var instancia := MultiMeshInstance3D.new()
	instancia.name = nombre
	var repetidos := MultiMesh.new()
	repetidos.transform_format = MultiMesh.TRANSFORM_3D
	repetidos.mesh = malla
	repetidos.instance_count = transformaciones.size()
	for indice in transformaciones.size():
		repetidos.set_instance_transform(indice, transformaciones[indice])
	instancia.multimesh = repetidos
	return instancia


static func _transformaciones_cajones() -> Array[Transform3D]:
	var resultado: Array[Transform3D] = []
	for indice in CAJONES:
		resultado.append(Transform3D(Basis.IDENTITY, Vector3(0, _y_cajon(indice), -0.247)))
	return resultado


static func _transformaciones_tiradores() -> Array[Transform3D]:
	var resultado: Array[Transform3D] = []
	for indice in CAJONES:
		resultado.append(Transform3D(Basis.IDENTITY, Vector3(0, _y_cajon(indice) + 0.025, -0.287)))
	return resultado


static func _transformaciones_etiquetas() -> Array[Transform3D]:
	var resultado: Array[Transform3D] = []
	for indice in CAJONES:
		resultado.append(Transform3D(Basis.IDENTITY, Vector3(0, _y_cajon(indice) - 0.025, -0.306)))
	return resultado


static func _y_cajon(indice: int) -> float:
	return -0.425 + float(indice) * 0.17
