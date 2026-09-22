## Selección mínima del Stylized Tree Pack de Quaternius (#219).
##
## Fuente oficial: https://quaternius.com/packs/stylizedtree.html
## Licencia: CC0-1.0. Además de la ficha del pack, el `License.txt` incluido en
## la carpeta de descarga del autor declara "CC0 1.0 Universal" (comprobado el
## 16/09/2026); la QAL general posterior no revoca esa dedicación.
##
## Los OBJ/MTL versionados son los originales del pack. Se descartan sus texturas
## de caricatura y cada superficie (corteza/hojas) recibe el shader común de
## SIGA-98 con un color apagado: a distancia importa la masa, no la hoja.
## No se añade física ni interacción.
class_name ArbolesQuaternius
extends RefCounted

const FUENTE := "https://quaternius.com/packs/stylizedtree.html"
const LICENCIA := "CC0-1.0"
const CARPETA := "res://assets/cc0/quaternius_stylized_tree/"

const FRONDOSO := "Tree_1.obj"
const PINO := "Pine_2.obj"
const DESNUDO := "DeadTree_5.obj"
const MODELOS := [FRONDOSO, PINO, DESNUDO]

const COLOR_CORTEZA := Color(0.20, 0.17, 0.15)
const COLOR_HOJAS := Color(0.17, 0.21, 0.15)
const COLOR_AGUJAS := Color(0.12, 0.17, 0.14)

static var _cache_mallas := {}
static var _cache_materiales := {}


static func crear(modelo: String) -> MeshInstance3D:
	var instancia := MeshInstance3D.new()
	if modelo not in MODELOS:
		push_warning("Árbol fuera de la selección #219: %s" % modelo)
		return instancia

	var malla := _malla(modelo)
	if malla == null:
		push_warning("No se pudo cargar árbol CC0: %s" % modelo)
		return instancia

	instancia.mesh = malla
	for superficie in malla.get_surface_count():
		instancia.set_surface_override_material(superficie, _material_superficie(malla, superficie))
	instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Fondo: más allá de esta distancia la niebla y el skyline ya cierran el plano.
	instancia.visibility_range_end = 60.0
	# Un árbol quieto delata el decorado. `VientoAmbiental` recoge lo que esté en
	# este grupo; el balanceo lo pone el shader y la fuerza empieza en cero, así
	# que esto no mueve nada por sí solo (#1230).
	instancia.add_to_group(VientoAmbiental.GRUPO_FOLLAJE)
	return instancia


static func _malla(modelo: String) -> Mesh:
	if _cache_mallas.has(modelo):
		return _cache_mallas[modelo] as Mesh
	var ruta := CARPETA + modelo
	if not ResourceLoader.exists(ruta):
		return null
	var recurso := ResourceLoader.load(ruta)
	if not (recurso is Mesh):
		return null
	var malla := recurso as Mesh
	_cache_mallas[modelo] = malla
	return malla


## El nombre del material del MTL ("Bark", "Tree_Leaves", "Pine_Leaves") decide
## el color; si el importador no lo conserva, la superficie 0 se trata como corteza.
static func _material_superficie(malla: Mesh, superficie: int) -> ShaderMaterial:
	var nombre := ""
	var original := malla.surface_get_material(superficie)
	if original != null:
		nombre = original.resource_name
	if nombre.is_empty() and malla is ArrayMesh:
		nombre = (malla as ArrayMesh).surface_get_name(superficie)

	var color := COLOR_CORTEZA
	if nombre.begins_with("Pine_Leaves"):
		color = COLOR_AGUJAS
	elif nombre.contains("Leaves"):
		color = COLOR_HOJAS
	elif nombre.is_empty() and superficie > 0:
		color = COLOR_HOJAS
	return _material(color)


static func _material(color: Color) -> ShaderMaterial:
	var clave := color.to_html()
	if _cache_materiales.has(clave):
		return _cache_materiales[clave] as ShaderMaterial
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	_cache_materiales[clave] = material
	return material
