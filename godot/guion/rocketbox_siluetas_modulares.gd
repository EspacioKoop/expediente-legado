## Muestra modular de siluetas sobre el rig Rocketbox existente (#1805).
##
## Reutiliza el vocabulario de prendas ya probado por VestuarioHumano3D, pero
## solo para tres históricos. Las capas cuelgan de huesos del Skeleton3D que ya
## trae cada avatar: nunca crean un rig auxiliar ni sustituyen piel, pelo o ropa
## importados.
class_name RocketboxSiluetasModulares
extends RefCounted

const VESTUARIO := preload("res://guion/vestuario_humano_3d.gd")
const MARCA := "silueta_rocketbox_1805"
const OBJETIVOS := ["emperador", "aduanero_ny", "correspondencia"]

const COLORES := {
	"emperador": Color(0.20, 0.22, 0.24),
	"aduanero_ny": Color(0.29, 0.27, 0.24),
	"correspondencia": Color(0.18, 0.19, 0.21),
}

## Límite del prototipo. Las texturas extra deben seguir siendo cero: las capas
## son geometría/material compartible sobre el avatar Rocketbox ya texturizado.
const PRESUPUESTO_MAX := {
	"skeletons_extra": 0,
	"triangulos_extra": 900,
	"superficies_extra": 18,
	"materiales_extra": 18,
	"texturas_extra": 0,
}


static func aplica_a(retrato: String) -> bool:
	return OBJETIVOS.has(retrato)


static func aplicar(pieza: Node3D, retrato: String) -> bool:
	if pieza == null or not aplica_a(retrato):
		return false
	var esqueleto := _esqueleto(pieza)
	if esqueleto == null or esqueleto.has_meta(MARCA):
		return false
	var perfil: Variant = VESTUARIO.PERFILES_PERSONAJE.get(retrato, {})
	if not perfil is Dictionary or (perfil as Dictionary).is_empty():
		return false

	var antes := _ids_hijos(esqueleto)
	var vestidor := VESTUARIO.new()
	var aplicado := vestidor.vestir(
		pieza,
		(perfil as Dictionary).duplicate(true),
		Color(COLORES[retrato]),
		retrato,
	)
	vestidor.free()
	if not aplicado:
		return false

	var piezas := 0
	for hijo in esqueleto.get_children():
		if antes.has(hijo.get_instance_id()):
			continue
		if not hijo is BoneAttachment3D:
			continue
		hijo.set_meta(MARCA, retrato)
		for nodo in hijo.find_children("*", "MeshInstance3D", true, false):
			var malla := nodo as MeshInstance3D
			var material := malla.material_override
			if material != null:
				material.set_meta(MARCA, retrato)
			piezas += 1

	esqueleto.set_meta(MARCA, retrato)
	esqueleto.set_meta("silueta_rocketbox_1805_piezas", piezas)
	return piezas > 0


static func auditar(pieza: Node3D) -> Dictionary:
	var esqueleto := _esqueleto(pieza)
	var texturas := {}
	var materiales := {}
	var triangulos := 0
	var superficies := 0
	var triangulos_overlay := 0
	var superficies_overlay := 0
	var materiales_overlay := {}
	var piezas_overlay := 0

	for nodo in pieza.find_children("*", "MeshInstance3D", true, false):
		var instancia := nodo as MeshInstance3D
		if instancia.mesh == null:
			continue
		var overlay := _es_overlay(instancia)
		var caras := instancia.mesh.get_faces()
		var tris := int(caras.size() / 3)
		triangulos += tris
		superficies += instancia.mesh.get_surface_count()
		if overlay:
			triangulos_overlay += tris
			superficies_overlay += instancia.mesh.get_surface_count()
			piezas_overlay += 1
		for superficie in instancia.mesh.get_surface_count():
			var material := instancia.get_active_material(superficie)
			if material == null:
				continue
			materiales[material.get_instance_id()] = true
			if overlay:
				materiales_overlay[material.get_instance_id()] = true
			_registrar_texturas(material, texturas)

	return {
		"skeletons": _contar_esqueletos(pieza),
		"triangulos": triangulos,
		"superficies": superficies,
		"materiales": materiales.size(),
		"texturas": texturas.size(),
		"resoluciones_textura": _resoluciones(texturas),
		"overlay_piezas": piezas_overlay,
		"overlay_triangulos": triangulos_overlay,
		"overlay_superficies": superficies_overlay,
		"overlay_materiales": materiales_overlay.size(),
	}


static func dentro_de_presupuesto(antes: Dictionary, despues: Dictionary) -> bool:
	return (
		int(despues.get("skeletons", 0)) - int(antes.get("skeletons", 0))
		<= int(PRESUPUESTO_MAX["skeletons_extra"])
		and int(despues.get("triangulos", 0)) - int(antes.get("triangulos", 0))
		<= int(PRESUPUESTO_MAX["triangulos_extra"])
		and int(despues.get("superficies", 0)) - int(antes.get("superficies", 0))
		<= int(PRESUPUESTO_MAX["superficies_extra"])
		and int(despues.get("materiales", 0)) - int(antes.get("materiales", 0))
		<= int(PRESUPUESTO_MAX["materiales_extra"])
		and int(despues.get("texturas", 0)) - int(antes.get("texturas", 0))
		<= int(PRESUPUESTO_MAX["texturas_extra"])
	)


## Firma geométrica del overlay, independiente del color. Incluye dimensiones y
## número de piezas; dos variantes con la misma recoloración seguirían dando la
## misma firma y el smoke las rechazaría.
static func firma_silueta(pieza: Node3D) -> String:
	var caja := AABB()
	var primera := true
	var piezas := 0
	for nodo in pieza.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		if not _es_overlay(malla):
			continue
		var relativa := pieza.global_transform.affine_inverse() * malla.global_transform
		var actual := relativa * malla.get_aabb()
		caja = actual if primera else caja.merge(actual)
		primera = false
		piezas += 1
	if primera:
		return ""
	return "%d|%.3f|%.3f|%.3f" % [piezas, caja.size.x, caja.size.y, caja.size.z]


static func _es_overlay(malla: MeshInstance3D) -> bool:
	var material := malla.material_override
	return material != null and material.has_meta(MARCA)


static func _ids_hijos(nodo: Node) -> Dictionary:
	var resultado := {}
	for hijo in nodo.get_children():
		resultado[hijo.get_instance_id()] = true
	return resultado


static func _contar_esqueletos(nodo: Node) -> int:
	var total := 1 if nodo is Skeleton3D else 0
	for hijo in nodo.get_children():
		total += _contar_esqueletos(hijo)
	return total


static func _esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null


static func _registrar_texturas(material: Material, salida: Dictionary) -> void:
	if material is BaseMaterial3D:
		var base := material as BaseMaterial3D
		for textura in [base.albedo_texture, base.normal_texture]:
			if textura is Texture2D:
				salida[(textura as Texture2D).get_instance_id()] = textura
		return
	if not material is ShaderMaterial:
		return
	var shader_material := material as ShaderMaterial
	for nombre in ["textura", "mapa_normal"]:
		var valor: Variant = shader_material.get_shader_parameter(nombre)
		if valor is Texture2D:
			salida[(valor as Texture2D).get_instance_id()] = valor


static func _resoluciones(texturas: Dictionary) -> Array[String]:
	var resultado: Array[String] = []
	for textura in texturas.values():
		if not textura is Texture2D:
			continue
		var medida := "%dx%d" % [(textura as Texture2D).get_width(), (textura as Texture2D).get_height()]
		if not resultado.has(medida):
			resultado.append(medida)
	resultado.sort()
	return resultado
