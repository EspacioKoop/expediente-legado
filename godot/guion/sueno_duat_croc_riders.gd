## Eco visual entre el Duat de #441 y la ROM propia Croc Riders 98.
##
## Este módulo es deliberadamente PRESENTACIONAL: no activa semillas oníricas,
## no lee la sesión del emulador y no toca Partida/Jornada. Croc Riders 98 sigue
## siendo ocio improductivo según #95; el Duat reutiliza únicamente un vocabulario
## visual propio del proyecto (cocodrilo, pirámide, río y paleta GBC de 4 tonos).
class_name SuenoDuatCrocRiders
extends RefCounted

const ROM_ID := "croc_riders_98"
const RELACION := "eco_visual"
const COLOR_0 := Color(0.08, 0.10, 0.08)
const COLOR_1 := Color(0.22, 0.30, 0.18)
const COLOR_2 := Color(0.56, 0.48, 0.24)
const COLOR_3 := Color(0.86, 0.74, 0.42)
const TAM_PIXEL := 0.22

# Composición original de 16x10. No copia sprites de la ROM: resume tres motivos
# compartidos por ambas piezas — pirámide, agua y silueta de cocodrilo — como un
# relieve/panel que el Duat puede incrustar en pared, sarcófago o arquitectura.
const RELIEVE := [
	"0000003300000000",
	"0000033330000000",
	"0000333333000000",
	"0003333333300000",
	"0011111111110000",
	"0012222222210000",
	"0000112222110000",
	"0011111111111100",
	"0113331113331110",
	"1111111111111111",
]


static func contrato() -> Dictionary:
	return {
		"rom": ROM_ID,
		"relacion": RELACION,
		"desbloquea_duat": false,
		"modifica_estado_rom": false,
		"modifica_campana": false,
		"motivos": ["cocodrilo", "piramide", "nilo", "paleta_gbc_4"],
	}


## Crea un panel 3D procedural listo para colgar del prototipo del Duat.
## La llamada es idempotente por nombre para que un wiring posterior pueda
## invocarla más de una vez sin duplicar nodos.
static func acoplar_a_duat(
	raiz: Node3D,
	posicion: Vector3 = Vector3(-3.0, 2.2, -6.8),
) -> Node3D:
	if raiz == null:
		return null
	var existente := raiz.get_node_or_null("EcoCrocRiders98") as Node3D
	if existente != null:
		return existente

	var panel := Node3D.new()
	panel.name = "EcoCrocRiders98"
	panel.position = posicion
	panel.set_meta("duat_eco_fuente", ROM_ID)
	panel.set_meta("duat_eco_tipo", RELACION)
	panel.set_meta("duat_eco_presentacional", true)
	panel.set_meta("duat_eco_sin_recompensa", true)
	raiz.add_child(panel)

	for y in RELIEVE.size():
		var fila: String = RELIEVE[y]
		for x in fila.length():
			var indice := fila.substr(x, 1).to_int()
			if indice <= 0:
				continue
			var pixel := MeshInstance3D.new()
			pixel.name = "Pixel_%02d_%02d" % [x, y]
			pixel.position = Vector3(
				(float(x) - 7.5) * TAM_PIXEL,
				(4.5 - float(y)) * TAM_PIXEL,
				0.0,
			)
			var quad := QuadMesh.new()
			quad.size = Vector2(TAM_PIXEL * 0.94, TAM_PIXEL * 0.94)
			pixel.mesh = quad
			pixel.material_override = _material(_color(indice))
			panel.add_child(pixel)
	return panel


static func _color(indice: int) -> Color:
	match indice:
		1:
			return COLOR_1
		2:
			return COLOR_2
		3:
			return COLOR_3
		_:
			return COLOR_0


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
