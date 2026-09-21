## Proyección compacta del corpus mitológico de #1153 para uso en runtime.
##
## No carga los JSON-LD de investigación durante la partida. El export compacto
## conserva solo la relación familia->tradición y los promedios de los ocho ejes
## ACP. Esos promedios modulan presentación; nunca deciden progreso ni hechos.
class_name MitologiasRuntime
extends RefCounted

const RUTA := "res://datos/mitologias_runtime.json"

static var _cache: Dictionary = {}


static func familia(id_mito: String) -> Dictionary:
	var familias = _datos().get("familias", {})
	if typeof(familias) != TYPE_DICTIONARY:
		return {}
	var entrada = familias.get(id_mito, {})
	if typeof(entrada) != TYPE_DICTIONARY:
		return {}
	return entrada.duplicate(true)


static func ejes(id_mito: String) -> Dictionary:
	var entrada := familia(id_mito)
	var tradicion := String(entrada.get("tradicion", ""))
	if tradicion.is_empty() or entrada.has("sin_perfil_acp"):
		return {}
	var tradiciones = _datos().get("tradiciones", {})
	if typeof(tradiciones) != TYPE_DICTIONARY:
		return {}
	var perfil = tradiciones.get(tradicion, {})
	if typeof(perfil) != TYPE_DICTIONARY:
		return {}
	var valores = perfil.get("ejes_medios", {})
	if typeof(valores) != TYPE_DICTIONARY:
		return {}
	return valores.duplicate(true)


## Los ejes ajustan levemente el perfil artístico ya elegido por SuenoCielos.
## Sombra aumenta bruma y reduce estrellas; transformación añade variación de
## cirros/bandas; ascenso refuerza un poco el halo lunar. No se crean símbolos.
static func modular_cielo(id_mito: String, perfil: Dictionary) -> Dictionary:
	var valores := ejes(id_mito)
	var resultado := perfil.duplicate(true)
	if valores.is_empty():
		return resultado

	var sombra := float(valores.get("light-shadow", 0.5)) - 0.5
	var transformacion := float(valores.get("stasis-transformation", 0.5)) - 0.5
	var ascenso := 0.5 - float(valores.get("ascent-descent", 0.5))

	resultado["bruma_fuerza"] = clampf(
		float(resultado.get("bruma_fuerza", 0.38)) + sombra * 0.20,
		0.0,
		1.0,
	)
	resultado["estrellas"] = clampf(
		float(resultado.get("estrellas", 0.56)) - sombra * 0.24,
		0.0,
		1.0,
	)
	resultado["cirros"] = clampf(
		float(resultado.get("cirros", 0.20)) + transformacion * 0.18,
		0.0,
		1.0,
	)
	resultado["bandas"] = clampf(
		float(resultado.get("bandas", 36.0)) - transformacion * 8.0,
		24.0,
		48.0,
	)
	resultado["luna_halo"] = clampf(
		float(resultado.get("luna_halo", 0.12)) + ascenso * 0.10,
		0.0,
		0.35,
	)
	return resultado


## El eco 3D expresa literalmente dos ejes espaciales: ascenso/descent mueve la
## figura en vertical y stasis/transformation cambia ligeramente su elongación.
static func modulacion_juicio(id_mito: String) -> Dictionary:
	var valores := ejes(id_mito)
	if valores.is_empty():
		return {}
	var ascenso := 0.5 - float(valores.get("ascent-descent", 0.5))
	var transformacion := float(valores.get("stasis-transformation", 0.5)) - 0.5
	return {
		"desplazamiento_y": clampf(ascenso * 0.8, -0.30, 0.30),
		"escala_y": clampf(1.0 + transformacion * 0.45, 0.82, 1.18),
	}


static func _datos() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	if typeof(parsed) == TYPE_DICTIONARY:
		_cache = parsed
	return _cache
