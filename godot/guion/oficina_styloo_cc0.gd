## Capa opcional del School Classrooms Asset Pack de Styloo (#223).
##
## El lote entra de forma atómica: si falta cualquiera de los seis GLB
## administrativos, la oficina conserva íntegramente el dressing CC0 actual.
## Cuando están todos disponibles, sustituye únicamente visuales y añade dos
## props sin colisión; la física y las interacciones existentes siguen mandando.
class_name OficinaStylooCc0
extends RefCounted

const MODELOS := {
	"desk": "styloo_school/principal_office_desk",
	"principal_chair": "styloo_school/principal_office_chair",
	"shelf": "styloo_school/principal_office_shelf",
	"telephone": "styloo_school/principal_office_telephone",
	"old_pc": "styloo_school/computer_pc_old",
	"printer": "styloo_school/computer_printer",
}

const TAM_PC := Vector3(0.22, 0.55, 0.55)
const TAM_PRINTER := Vector3(0.62, 0.36, 0.54)


static func disponible() -> bool:
	for nombre in MODELOS.values():
		if not Modelos.hay(String(nombre)):
			return false
	return true


static func montar(mundo: Node3D) -> bool:
	if mundo.has_meta("oficina_styloo_cc0"):
		return true
	if not disponible():
		return false

	var sustituciones := 0
	for bulto in EspaciosCatalogo.OFICINA.bultos:
		var tipo := String(bulto.get("modelo", ""))
		var pos: Vector3 = bulto.get("pos", Vector3.ZERO)
		if tipo == "desk" and pos.x < 0.0 and pos.z > 0.0:
			if _sustituir_bulto(mundo, pos, String(MODELOS.desk), bulto.tam):
				sustituciones += 1
		elif tipo == "chairDesk" and pos.x < 0.0 and pos.z > 0.0:
			if _sustituir_bulto(
				mundo, pos, String(MODELOS.principal_chair), bulto.tam
			):
				sustituciones += 1
		elif tipo == "bookcaseClosed" and pos.z > 3.0:
			if _sustituir_bulto(mundo, pos, String(MODELOS.shelf), bulto.tam):
				sustituciones += 1

	var puesto := mundo.get_node_or_null("PuestoUtileria2") as Node3D
	if puesto != null:
		var telefono := puesto.get_node_or_null("TelefonoBase") as Node3D
		if telefono != null and AssetCc0.sustituir(
			telefono, String(MODELOS.telephone), Vector3(0.42, 0.20, 0.30)
		):
			sustituciones += 1
			var auricular := puesto.get_node_or_null("Auricular") as Node3D
			if auricular != null:
				auricular.hide()
		if _agregar_prop(
			puesto,
			"TorrePcStyloo",
			String(MODELOS.old_pc),
			Vector3(0.72, 0.30, -0.25),
			TAM_PC
		):
			sustituciones += 1

	if _agregar_prop(
		mundo,
		"PrinterStyloo",
		String(MODELOS.printer),
		Vector3(5.5, 2.05, 3.5),
		TAM_PRINTER
	):
		sustituciones += 1

	if sustituciones != MODELOS.size():
		push_warning(
			"Styloo disponible pero el montaje administrativo quedó incompleto: %d/%d"
			% [sustituciones, MODELOS.size()]
		)
		return false

	mundo.set_meta("oficina_styloo_cc0", true)
	return true


static func _sustituir_bulto(
	mundo: Node3D, posicion: Vector3, modelo: String, tam: Vector3
) -> bool:
	for cuerpo in mundo.get_children():
		if cuerpo is StaticBody3D and cuerpo.position.is_equal_approx(posicion):
			return AssetCc0.sustituir(cuerpo, modelo, tam)
	return false


static func _agregar_prop(
	padre: Node3D, nombre: String, modelo: String, posicion: Vector3, tam: Vector3
) -> bool:
	if padre.has_node(nombre):
		return true
	var ancla := Node3D.new()
	ancla.name = nombre
	ancla.position = posicion
	padre.add_child(ancla)
	if AssetCc0.sustituir(ancla, modelo, tam):
		return true
	ancla.queue_free()
	return false
