## Catálogo runtime de materiales PBR propios para la épica #435.
##
## Centraliza la duplicación de recursos para que los verticales puedan vestir
## geometría procedural sin mutar los .tres compartidos. Si un uso necesita
## transparencia/emisión, esas propiedades se aplican sobre la copia local.
class_name Mitologias435Materiales
extends RefCounted

const ARCILLA_URUK := preload("res://arte/mitologias_435/materiales/arcilla_uruk.tres")
const METAL_ARCHIVO := preload("res://arte/mitologias_435/materiales/metal_archivo_oxidado.tres")
const BRONCE_VOTIVO := preload("res://arte/mitologias_435/materiales/bronce_votivo.tres")
const ESCAMA_HIDRA := preload("res://arte/mitologias_435/materiales/escama_hidra.tres")
const JADE_RYU := preload("res://arte/mitologias_435/materiales/jade_ryu_humedo.tres")
const CALIZA_DUAT := preload("res://arte/mitologias_435/materiales/caliza_duat.tres")
const PAPEL_ARCHIVO := preload("res://arte/mitologias_435/materiales/papel_archivo_envejecido.tres")

const CATALOGO := {
	"arcilla_uruk": ARCILLA_URUK,
	"metal_archivo_oxidado": METAL_ARCHIVO,
	"bronce_votivo": BRONCE_VOTIVO,
	"escama_hidra": ESCAMA_HIDRA,
	"jade_ryu_humedo": JADE_RYU,
	"caliza_duat": CALIZA_DUAT,
	"papel_archivo_envejecido": PAPEL_ARCHIVO,
}


static func crear(
	id_material: String,
	color_emision: Color = Color.WHITE,
	transparente: bool = false,
	emision: bool = false,
) -> StandardMaterial3D:
	var base := CATALOGO.get(id_material) as StandardMaterial3D
	if base == null:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = color_emision
		fallback.roughness = 0.78
		return fallback

	var material := base.duplicate() as StandardMaterial3D
	material.resource_local_to_scene = true
	if transparente:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = color_emision.a
	if emision:
		material.emission_enabled = true
		material.emission = color_emision
		material.emission_energy_multiplier = 1.35
	return material
