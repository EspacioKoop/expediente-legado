## Gramática de cielos oníricos contextuales (#435/#935).
##
## Un cielo no selecciona qué se sueña. Esa autoridad sigue en SemillasOniricas
## y MitologiasNoche. Este catálogo solo traduce la familia ya seleccionada a
## una presentación del SkyMaterial común y permite superponer modificadores
## externos (religión, Tarot, ideología, gramática simbólica...) sin crear un
## shader ni una combinación escrita a mano por cada cruce.
class_name SuenoCielos
extends RefCounted

const PRIORIDAD_EXTERNA_DEFECTO := 100

## Parámetros del shader que esta gramática puede gobernar. Un modificador nunca
## puede inyectar una propiedad arbitraria en el material.
const PARAMETROS_VALIDOS := [
	"cielo_alto",
	"horizonte",
	"ocaso",
	"ocaso_mezcla",
	"luna_color",
	"luna_halo",
	"resplandor_ciudad",
	"resplandor_fuerza",
	"bruma_horizonte",
	"bruma_fuerza",
	"nube_color",
	"nubes",
	"cirro_color",
	"cirros",
	"luz_lunar_nubes",
	"via_lactea_color",
	"via_lactea",
	"estrellas",
	"estrellas_secundarias",
	"bandas",
]

## Cielo onírico sin familia cultural activa. Se diferencia de la calle, pero
## sigue siendo deliberadamente sobrio: la rareza fuerte la aporta el contexto.
const PERFIL_BASE := {
	"cielo_alto": Color(0.035, 0.030, 0.080),
	"horizonte": Color(0.120, 0.080, 0.140),
	"ocaso": Color(0.240, 0.100, 0.160),
	"ocaso_mezcla": 0.22,
	"luna_color": Color(0.80, 0.82, 0.92),
	"luna_halo": 0.12,
	"resplandor_ciudad": Color(0.20, 0.10, 0.25),
	"resplandor_fuerza": 0.30,
	"bruma_horizonte": Color(0.12, 0.10, 0.18),
	"bruma_fuerza": 0.38,
	"nube_color": Color(0.10, 0.09, 0.15),
	"nubes": 0.22,
	"cirro_color": Color(0.18, 0.15, 0.25),
	"cirros": 0.20,
	"luz_lunar_nubes": 0.36,
	"via_lactea_color": Color(0.25, 0.22, 0.38),
	"via_lactea": 0.11,
	"estrellas": 0.56,
	"estrellas_secundarias": 0.40,
	"bandas": 36.0,
}

## Perfiles deliberadamente parciales: heredan PERFIL_BASE. Son dirección
## artística propia de SIGA-98, no reconstrucciones históricas ni afirmaciones
## sobre las tradiciones culturales que inspiran cada familia.
const PERFILES_MITO := {
	"gilgamesh":
	{
		"cielo_alto": Color(0.025, 0.045, 0.120),
		"horizonte": Color(0.30, 0.16, 0.08),
		"ocaso": Color(0.46, 0.24, 0.07),
		"resplandor_ciudad": Color(0.48, 0.26, 0.06),
		"resplandor_fuerza": 0.50,
		"via_lactea_color": Color(0.28, 0.30, 0.52),
		"via_lactea": 0.07,
		"estrellas": 0.68,
		"bandas": 32.0,
	},
	"minotauro":
	{
		"cielo_alto": Color(0.070, 0.025, 0.045),
		"horizonte": Color(0.25, 0.11, 0.06),
		"ocaso": Color(0.42, 0.20, 0.07),
		"bruma_horizonte": Color(0.24, 0.12, 0.08),
		"bruma_fuerza": 0.52,
		"nubes": 0.12,
		"via_lactea": 0.0,
		"estrellas": 0.24,
		"luna_halo": 0.055,
	},
	"aquiles":
	{
		"cielo_alto": Color(0.035, 0.060, 0.130),
		"horizonte": Color(0.30, 0.20, 0.10),
		"ocaso": Color(0.58, 0.32, 0.10),
		"ocaso_mezcla": 0.34,
		"luna_color": Color(0.96, 0.82, 0.50),
		"luna_halo": 0.065,
		"nubes": 0.10,
		"estrellas": 0.44,
	},
	"hidra":
	{
		"cielo_alto": Color(0.018, 0.050, 0.045),
		"horizonte": Color(0.08, 0.16, 0.11),
		"ocaso": Color(0.18, 0.22, 0.08),
		"nube_color": Color(0.07, 0.14, 0.10),
		"nubes": 0.76,
		"cirro_color": Color(0.10, 0.18, 0.13),
		"cirros": 0.52,
		"via_lactea": 0.0,
		"estrellas": 0.08,
	},
	"dragon_japones":
	{
		"cielo_alto": Color(0.020, 0.055, 0.095),
		"horizonte": Color(0.06, 0.18, 0.22),
		"ocaso": Color(0.11, 0.24, 0.24),
		"luna_color": Color(0.78, 0.90, 0.92),
		"luna_halo": 0.18,
		"nube_color": Color(0.06, 0.12, 0.16),
		"nubes": 0.72,
		"cirro_color": Color(0.12, 0.28, 0.30),
		"cirros": 0.62,
		"luz_lunar_nubes": 0.62,
		"via_lactea": 0.025,
	},
	"duat":
	{
		"cielo_alto": Color(0.008, 0.008, 0.018),
		"horizonte": Color(0.22, 0.12, 0.025),
		"ocaso": Color(0.52, 0.30, 0.035),
		"ocaso_mezcla": 0.40,
		"luna_color": Color(0.96, 0.72, 0.30),
		"luna_halo": 0.10,
		"resplandor_ciudad": Color(0.50, 0.27, 0.04),
		"resplandor_fuerza": 0.62,
		"via_lactea_color": Color(0.55, 0.35, 0.10),
		"via_lactea": 0.13,
		"estrellas": 0.62,
		"bandas": 28.0,
	},
	"simurgh":
	{
		"cielo_alto": Color(0.055, 0.030, 0.125),
		"horizonte": Color(0.20, 0.12, 0.26),
		"ocaso": Color(0.46, 0.25, 0.18),
		"luna_color": Color(0.94, 0.82, 0.56),
		"cirro_color": Color(0.34, 0.24, 0.46),
		"cirros": 0.56,
		"via_lactea_color": Color(0.43, 0.34, 0.62),
		"via_lactea": 0.18,
		"estrellas": 0.82,
	},
	"yggdrasil":
	{
		"cielo_alto": Color(0.015, 0.050, 0.070),
		"horizonte": Color(0.06, 0.16, 0.13),
		"ocaso": Color(0.12, 0.24, 0.16),
		"bruma_horizonte": Color(0.08, 0.18, 0.16),
		"nube_color": Color(0.06, 0.14, 0.14),
		"cirro_color": Color(0.10, 0.24, 0.22),
		"via_lactea_color": Color(0.18, 0.42, 0.36),
		"via_lactea": 0.20,
		"estrellas": 0.70,
	},
	"tir_na_nog":
	{
		"cielo_alto": Color(0.025, 0.090, 0.095),
		"horizonte": Color(0.12, 0.28, 0.18),
		"ocaso": Color(0.52, 0.34, 0.14),
		"ocaso_mezcla": 0.36,
		"bruma_horizonte": Color(0.12, 0.26, 0.20),
		"bruma_fuerza": 0.46,
		"via_lactea_color": Color(0.30, 0.52, 0.40),
		"via_lactea": 0.12,
		"estrellas": 0.58,
	},
	"mari":
	{
		"cielo_alto": Color(0.030, 0.038, 0.055),
		"horizonte": Color(0.11, 0.12, 0.14),
		"ocaso": Color(0.20, 0.13, 0.10),
		"bruma_horizonte": Color(0.16, 0.17, 0.18),
		"bruma_fuerza": 0.72,
		"nube_color": Color(0.10, 0.11, 0.13),
		"nubes": 0.92,
		"cirro_color": Color(0.16, 0.17, 0.18),
		"cirros": 0.72,
		"via_lactea": 0.0,
		"estrellas": 0.0,
	},
	"baba_yaga":
	{
		"cielo_alto": Color(0.018, 0.030, 0.034),
		"horizonte": Color(0.08, 0.12, 0.09),
		"ocaso": Color(0.17, 0.11, 0.07),
		"luna_color": Color(0.76, 0.78, 0.66),
		"luna_halo": 0.08,
		"bruma_horizonte": Color(0.10, 0.15, 0.12),
		"bruma_fuerza": 0.66,
		"nube_color": Color(0.06, 0.09, 0.08),
		"nubes": 0.62,
		"cirro_color": Color(0.12, 0.16, 0.13),
		"cirros": 0.28,
		"via_lactea": 0.03,
		"estrellas": 0.20,
	},
	"anansi_akan":
	{
		"cielo_alto": Color(0.035, 0.025, 0.100),
		"horizonte": Color(0.16, 0.08, 0.20),
		"ocaso": Color(0.42, 0.22, 0.08),
		"luna_color": Color(0.94, 0.78, 0.42),
		"cirro_color": Color(0.30, 0.18, 0.34),
		"cirros": 0.48,
		"via_lactea_color": Color(0.48, 0.34, 0.18),
		"via_lactea": 0.15,
		"estrellas": 0.72,
		"bandas": 30.0,
	},
	"maui_tamanuitera":
	{
		"cielo_alto": Color(0.085, 0.055, 0.120),
		"horizonte": Color(0.42, 0.20, 0.11),
		"ocaso": Color(0.78, 0.39, 0.12),
		"ocaso_mezcla": 0.62,
		"luna_color": Color(1.00, 0.76, 0.38),
		"luna_halo": 0.16,
		"resplandor_ciudad": Color(0.62, 0.30, 0.08),
		"resplandor_fuerza": 0.70,
		"nubes": 0.16,
		"via_lactea": 0.015,
		"estrellas": 0.10,
	},
	"popol_wuj":
	# Dirección propia SIGA-98: contraste entre dos corredores y vacío.
	{
		# No pretende reconstruir Xibalbá ni codificar iconografía k’iche’.
		"cielo_alto": Color(0.018, 0.030, 0.042),
		"horizonte": Color(0.12, 0.10, 0.075),
		"ocaso": Color(0.30, 0.20, 0.085),
		"ocaso_mezcla": 0.18,
		"luna_color": Color(0.78, 0.72, 0.55),
		"luna_halo": 0.08,
		"bruma_horizonte": Color(0.09, 0.11, 0.11),
		"bruma_fuerza": 0.58,
		"nube_color": Color(0.07, 0.09, 0.10),
		"nubes": 0.48,
		"via_lactea": 0.035,
		"estrellas": 0.32,
	},
}


## Devuelve qué familia corresponde a la escena actual según la misma asignación
## que usan los controllers 3D. Si no toca familia, el cielo base sigue solo.
static func familia_para_escena(familias: Array, cantidad_escenas: int, pendientes: int) -> String:
	var indice := MitologiasNoche.indice_escena_actual(cantidad_escenas, pendientes)
	var asignacion := MitologiasNoche.asignar(familias, cantidad_escenas)
	for familia_cruda in familias:
		var familia := String(familia_cruda)
		if int(asignacion.get(familia, -1)) == indice:
			return familia
	return ""


## Compone el perfil sin conocer la semántica de las capas externas.
##
## Cada modificador:
## {
##   "origen": "religion:<id>:practica" | "tarot:<id>" | "ideologia:<tag>" | ...,
##   "prioridad": 20,
##   "parametros": {"nubes": 0.5, ...}
## }
##
## La prioridad menor se aplica antes. El origen desempata para que guardar,
## recargar o cambiar el orden de un Array no cambie el resultado.
static func componer(familia: String, modificadores: Array = []) -> Dictionary:
	var resultado: Dictionary = PERFIL_BASE.duplicate(true)
	var perfil_mito = PERFILES_MITO.get(familia, {})
	if typeof(perfil_mito) == TYPE_DICTIONARY:
		resultado.merge(perfil_mito, true)

	var capas: Array = modificadores.duplicate(true)
	capas.sort_custom(_comparar_modificadores)
	for capa_cruda in capas:
		if typeof(capa_cruda) != TYPE_DICTIONARY:
			continue
		var capa: Dictionary = capa_cruda
		var parametros = capa.get("parametros", {})
		if typeof(parametros) != TYPE_DICTIONARY:
			continue
		for clave_cruda in parametros.keys():
			var clave := String(clave_cruda)
			if PARAMETROS_VALIDOS.has(clave):
				resultado[clave] = parametros[clave_cruda]
	return resultado


static func _comparar_modificadores(a: Variant, b: Variant) -> bool:
	var prioridad_a := PRIORIDAD_EXTERNA_DEFECTO
	var prioridad_b := PRIORIDAD_EXTERNA_DEFECTO
	var origen_a := ""
	var origen_b := ""
	if typeof(a) == TYPE_DICTIONARY:
		prioridad_a = int(a.get("prioridad", PRIORIDAD_EXTERNA_DEFECTO))
		origen_a = String(a.get("origen", ""))
	if typeof(b) == TYPE_DICTIONARY:
		prioridad_b = int(b.get("prioridad", PRIORIDAD_EXTERNA_DEFECTO))
		origen_b = String(b.get("origen", ""))
	if prioridad_a == prioridad_b:
		return origen_a < origen_b
	return prioridad_a < prioridad_b


static func aplicar(material: ShaderMaterial, perfil: Dictionary) -> void:
	if material == null:
		return
	for clave_cruda in perfil.keys():
		var clave := String(clave_cruda)
		if PARAMETROS_VALIDOS.has(clave):
			material.set_shader_parameter(clave, perfil[clave_cruda])
