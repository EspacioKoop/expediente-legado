## Primer uso runtime curado de Common game assets [Chill Vibes Art Jam 4] (#220).
##
## El pack es opcional: esta capa solo sustituye parte del dressing procedural
## de la zona de servicio si están presentes LOS DOS GLB aprobados. No descarga,
## no fabrica assets y no cambia la geografía/colisión de la calle.
class_name ChillVibesCC0
extends RefCounted

const PALLET := "chill_vibes/shipping_pallet"
const CRATE := "chill_vibes/crate"

const TAM_PALLET := Vector3(0.80, 0.144, 1.20)
const TAM_CRATE := Vector3(1.00, 1.00, 1.00)

const MADERA_PALLET := Color(0.42, 0.34, 0.24)
const MADERA_CAJA := Color(0.37, 0.30, 0.22)


static func disponible() -> bool:
	return Modelos.hay(PALLET) and Modelos.hay(CRATE)


## Monta un pequeño lote de carga dentro de una zona de servicio existente.
## Devuelve false sin tocar el árbol si falta cualquiera de las dos piezas:
## el caller conserva entonces su fallback procedural completo.
static func montar_lote_servicio(raiz: Node3D) -> bool:
	if raiz == null or not disponible():
		return false

	var lote := Node3D.new()
	lote.name = "ChillVibesServicio"

	if not _pieza(
		lote,
		"Pallet",
		PALLET,
		Vector3(1.18, TAM_PALLET.y * 0.5, -0.52),
		TAM_PALLET,
		MADERA_PALLET,
		-8.0
	):
		lote.free()
		return false
	if not _pieza(
		lote,
		"Crate",
		CRATE,
		Vector3(1.20, TAM_CRATE.y * 0.5, 0.18),
		TAM_CRATE,
		MADERA_CAJA,
		7.0
	):
		lote.free()
		return false

	raiz.add_child(lote)
	return true


static func _pieza(
	padre: Node3D,
	nombre: String,
	modelo: String,
	posicion: Vector3,
	tam: Vector3,
	color: Color,
	giro_y: float
) -> bool:
	var cuerpo := Node3D.new()
	cuerpo.name = nombre
	cuerpo.position = posicion
	cuerpo.rotation_degrees.y = giro_y
	padre.add_child(cuerpo)

	if not Modelos.mueble(cuerpo, modelo, tam, color):
		cuerpo.queue_free()
		return false
	return true
