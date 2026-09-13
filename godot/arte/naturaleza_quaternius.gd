## Selección mínima del Ultimate Nature Pack de Quaternius (#229).
##
## Fuente oficial: https://quaternius.com/packs/ultimatenature.html
## Licencia: CC0-1.0.
## Espejo reproducible: Emaro/rovers-journey@ae16b37476c031075e4e767a848771b92ea5c4e0
##
## Los OBJ/MTL versionados son los originales del pack. Aquí se descartan sus
## materiales visuales y se aplica el shader común de SIGA-98 para que la forma
## natural no parezca un asset de otro juego. No se añade física ni interacción.
class_name NaturalezaQuaternius
extends RefCounted

const FUENTE := "https://quaternius.com/packs/ultimatenature.html"
const LICENCIA := "CC0-1.0"
const ESPEJO_COMMIT := "ae16b37476c031075e4e767a848771b92ea5c4e0"
const CARPETA := "res://assets/cc0/quaternius_ultimate_nature/"

const ARBUSTO_1 := "Bush_1.obj"
const ARBUSTO_2 := "Bush_2.obj"
const ROCA_1 := "Rock_1.obj"
const ROCA_5 := "Rock_5.obj"
const MODELOS := [ARBUSTO_1, ARBUSTO_2, ROCA_1, ROCA_5]

static var _cache_mallas := {}
static var _material_arbusto: ShaderMaterial
static var _material_roca: ShaderMaterial


static func crear(modelo: String) -> MeshInstance3D:
	var instancia := MeshInstance3D.new()
	if modelo not in MODELOS:
		push_warning("Modelo natural fuera de la selección #229: %s" % modelo)
		return instancia

	var malla := _malla(modelo)
	if malla == null:
		push_warning("No se pudo cargar naturaleza CC0: %s" % modelo)
		return instancia

	instancia.mesh = malla
	instancia.material_override = _material_para(modelo)
	instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Es dressing de borde: a gran distancia basta la silueta del terreno/skyline.
	instancia.visibility_range_end = 42.0
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


static func _material_para(modelo: String) -> ShaderMaterial:
	if modelo.begins_with("Bush_"):
		if _material_arbusto == null:
			_material_arbusto = _material(Color(0.22, 0.27, 0.16))
		return _material_arbusto
	if _material_roca == null:
		_material_roca = _material(Color(0.31, 0.29, 0.26))
	return _material_roca


static func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	return material
