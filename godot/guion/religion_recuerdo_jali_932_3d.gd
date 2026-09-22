## Proyección onírica de la exposición cultural de JALI 98 (#932/#935).
##
## Repite únicamente geometría, luz y sombra ya vistas en la ROM. No añade texto,
## iconografía religiosa, colisión, práctica ni convicción.
class_name ReligionRecuerdoJali9323D
extends RefCounted

const NOMBRE := "RecuerdoJali98"
const ALTURA := 0.045
const COLOR_LUZ := Color(0.58, 0.44, 0.18, 0.46)


static func montar(mundo: Node3D, recuerdo: Dictionary) -> Node3D:
	if mundo == null or recuerdo.is_empty():
		return null
	if String(recuerdo.get("fuente", "")) != ReligionRecuerdoJali932.FUENTE:
		return null
	if bool(recuerdo.get("hechos_nuevos", true)) or bool(recuerdo.get("asume_conviccion", true)):
		return null

	var existente := mundo.get_node_or_null(NOMBRE) as Node3D
	if existente != null:
		return existente

	var raiz := Node3D.new()
	raiz.name = NOMBRE
	raiz.set_meta("fuente_cultural", ReligionRecuerdoJali932.FUENTE)
	raiz.set_meta("motivos", recuerdo.get("motivos", []).duplicate())
	raiz.set_meta("asume_conviccion", false)
	mundo.add_child(raiz)

	for indice in 3:
		_montar_roseta(raiz, Vector3(-1.8 + indice * 1.8, ALTURA, 0.0), indice)
	return raiz


static func _montar_roseta(raiz: Node3D, centro: Vector3, indice: int) -> void:
	for brazo in 4:
		var marca := _barra(
			raiz,
			"Luz_%d_%d" % [indice, brazo],
			centro,
			Vector3(1.34, ALTURA * 2.0, 0.075),
		)
		marca.rotation_degrees.y = 45.0 * brazo


static func _barra(
	raiz: Node3D, nombre: String, posicion: Vector3, tamano: Vector3
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	malla.position = posicion
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var caja := BoxMesh.new()
	caja.size = tamano
	malla.mesh = caja
	malla.material_override = _material()
	raiz.add_child(malla)
	return malla


static func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_LUZ
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(COLOR_LUZ.r, COLOR_LUZ.g, COLOR_LUZ.b)
	material.emission_energy_multiplier = 0.8
	return material
