## Dressing documental pasivo para #961.
##
## Materializa ecos abstractos de los gestos de atención del día. Son nodos
## puramente visuales: no tienen colisión, señales, objetivos ni persistencia.
class_name SuenoAtencionDocumental
extends RefCounted

const MOTIVOS_VALIDOS := ["fecha", "margen", "folio", "relacion", "relectura"]
const COLOR_PAPEL := Color(0.72, 0.68, 0.58)
const COLOR_TINTA := Color(0.20, 0.18, 0.20)
const COLOR_SELLO := Color(0.42, 0.16, 0.18)


static func montar(
	mundo: Node3D,
	id_escena: String,
	dia: int,
	raiz_azar: int,
	motivos: Array,
) -> Array:
	var limpios := _normalizar_motivos(motivos)
	if limpios.is_empty():
		return []

	var forma := SuenoFormas.de(id_escena)
	var bloques: Array = forma.get("bloques", [])
	var entrada: Vector2i = forma.get("entrada", Vector2i.ZERO)
	if bloques.is_empty():
		return []

	var semilla := (
		Azar
		. derivar_texto(
			raiz_azar,
			"sueno",
			"meticulosidad:%s" % id_escena,
			[dia],
		)
	)
	var desplazamiento := posmod(semilla, limpios.size())
	var cantidad := mini(2, limpios.size())
	var celdas := Planta.repartidas(bloques, cantidad, [entrada])
	var creados := []

	for i in cantidad:
		var motivo := String(limpios[(i + desplazamiento) % limpios.size()])
		var eco := _crear_eco(motivo)
		eco.name = "EcoMeticulosidad%d" % (i + 1)
		eco.position = Planta.centro_en_metros(bloques, celdas[i]) + Vector3(0.0, 1.15, 0.0)
		eco.rotation_degrees.y = float(posmod(semilla + i * 47, 120) - 60)
		eco.set_meta("motivo_meticulosidad", motivo)
		eco.set_meta("decorativo", true)
		mundo.add_child(eco)
		creados.append(eco)
	return creados


static func _normalizar_motivos(motivos: Array) -> Array[String]:
	var resultado: Array[String] = []
	for valor in motivos:
		var motivo := String(valor).strip_edges()
		if MOTIVOS_VALIDOS.has(motivo) and not resultado.has(motivo):
			resultado.append(motivo)
	return resultado


static func _crear_eco(motivo: String) -> Node3D:
	var raiz := Node3D.new()
	var papel := _lamina(Vector3(0.64, 0.035, 0.88), COLOR_PAPEL)
	raiz.add_child(papel)

	match motivo:
		"fecha":
			for i in 3:
				var raya := _lamina(Vector3(0.08, 0.018, 0.34), COLOR_TINTA)
				raya.position = Vector3(-0.18 + float(i) * 0.18, 0.032, 0.14)
				raiz.add_child(raya)
		"margen":
			var margen := _lamina(Vector3(0.035, 0.018, 0.72), COLOR_TINTA)
			margen.position = Vector3(-0.23, 0.032, 0.0)
			raiz.add_child(margen)
		"folio":
			var pestana := _lamina(Vector3(0.22, 0.025, 0.12), COLOR_SELLO)
			pestana.position = Vector3(0.16, 0.035, -0.38)
			raiz.add_child(pestana)
		"relacion":
			var pareja := _lamina(Vector3(0.64, 0.035, 0.88), COLOR_PAPEL.darkened(0.12))
			pareja.position = Vector3(0.20, -0.04, 0.14)
			pareja.rotation_degrees.y = 18.0
			raiz.add_child(pareja)
		"relectura":
			var copia := _lamina(Vector3(0.64, 0.035, 0.88), COLOR_PAPEL.darkened(0.08))
			copia.position = Vector3(-0.10, -0.04, 0.10)
			copia.rotation_degrees.y = -12.0
			raiz.add_child(copia)
	return raiz


static func _lamina(tamano: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	visual.mesh = malla
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	visual.material_override = material
	return visual
