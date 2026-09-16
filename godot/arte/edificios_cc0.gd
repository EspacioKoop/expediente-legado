## Selección mínima del Ultimate Buildings Pack de Quaternius (#218/#216).
##
## Fuente oficial: https://quaternius.com/packs/ultimatetexturedbuildings.html
## Licencia: CC0-1.0.
## `2Story_Mat.obj` y `1Story_Sign_Mat.obj` son el OBJ original del pack
## (carpeta "Models with Materials", sin texturas). `4Story_Mat.obj` y
## `6Story_Stack_Mat.obj` no estaban disponibles en OBJ en la carpeta de
## Google Drive enlazada por la página oficial (enlaces individuales
## bloqueados por límite de accesos); se exportaron a OBJ con `assimp` desde
## el FBX original de la misma carpeta oficial, tal y como permite el
## contrato de docs/assets/quaternius-ultimate-buildings.md. El FBX exporta
## en centímetros y assimp no aplicó el factor de unidad: sus vértices se
## reescalaron ×0.01 al versionarlos para que la altura quede en metros,
## coherente con `2Story_Mat`/`1Story_Sign_Mat` y con el LOD procedural de
## SkylineQuaternius (#404).
##
## Los OBJ/MTL versionados conservan la geometría original. Aquí se
## descartan sus materiales visuales y se aplica el shader común de SIGA-98
## para integrarlos con el resto del fondo urbano. No hay física ni
## interacción: son fondo/LOD, complementan (no sustituyen) el LOD
## procedural de SkylineQuaternius ya mergeado en #404.
class_name EdificiosCC0
extends RefCounted

const FUENTE := "https://quaternius.com/packs/ultimatetexturedbuildings.html"
const LICENCIA := "CC0-1.0"
const CARPETA := "res://assets/cc0/quaternius_ultimate_buildings/"

## Rol: bloque residencial bajo/medio.
const RESIDENCIAL_MEDIO := "2Story_Mat.obj"
## Rol: bloque residencial alto (silueta vertical).
const RESIDENCIAL_ALTO := "6Story_Stack_Mat.obj"
## Rol: edificio terciario/oficinas.
const TERCIARIO := "4Story_Mat.obj"
## Rol: pieza comercial/esquina.
const COMERCIAL := "1Story_Sign_Mat.obj"
const MODELOS := [RESIDENCIAL_MEDIO, RESIDENCIAL_ALTO, TERCIARIO, COMERCIAL]

static var _cache_mallas := {}
static var _cache_materiales := {}


static func crear(modelo: String, color: Color) -> MeshInstance3D:
	var instancia := MeshInstance3D.new()
	if modelo not in MODELOS:
		push_warning("Modelo de edificio fuera de la selección #218: %s" % modelo)
		return instancia

	var malla := _malla(modelo)
	if malla == null:
		push_warning("No se pudo cargar edificio CC0: %s" % modelo)
		return instancia

	instancia.mesh = malla
	instancia.material_override = _material_para(color)
	instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Son fondo lejano: la silueta completa solo importa hasta cierta distancia.
	instancia.visibility_range_end = 90.0
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


static func _material_para(color: Color) -> ShaderMaterial:
	var clave := color.to_html(false)
	if _cache_materiales.has(clave):
		return _cache_materiales[clave] as ShaderMaterial
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	_cache_materiales[clave] = material
	return material
