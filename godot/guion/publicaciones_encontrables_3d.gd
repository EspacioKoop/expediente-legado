## Ejemplares de #674 que se encuentran explorando, no comprando.
##
## La presencia física se deriva del catálogo y del Inventario real: si el ID ya
## está en carried/home_storage no se vuelve a montar. Los props usan Recogible3D
## (#97/#283), por lo que esta capa no implementa recogida ni persistencia propia.
class_name PublicacionesEncontrables3D
extends RefCounted

const NOMBRE_RAIZ := "PublicacionesEncontrables98"
const ORIGEN := "publicaciones_encontrables_98"

const DEFINICIONES := [
	{
		"id": "byte_domestico_42",
		"fase": "archivo",
		"dia_min": 1,
		"ancla": "PuestoUtileria1",
		"offset": Vector3(-0.48, 0.86, -0.24),
		"giro_y": -8.0,
	},
	{
		"id": "marcador_98_deportes",
		"fase": "archivo",
		"dia_min": 1,
		"ancla": "MaquinaCafeInteractuable",
		"offset": Vector3(0.54, 0.06, 0.10),
		"giro_y": 12.0,
	},
	{
		"id": "estratos_ciudad_06",
		"fase": "archivo",
		"dia_min": 2,
		"ancla": "PuestoUtileria3",
		"offset": Vector3(-0.52, 0.86, -0.22),
		"giro_y": 5.0,
	},
	{
		"id": "manual_casa_98",
		"fase": "casa",
		"dia_min": 1,
		"ancla": "SofaCasa",
		"offset": Vector3(0.08, 0.57, -0.14),
		"giro_y": 90.0,
	},
]


static func montar(
	mundo: Node3D, fase: String, dia: int, inventario: Dictionary
) -> Node3D:
	limpiar(mundo)
	var raiz := Node3D.new()
	raiz.name = NOMBRE_RAIZ
	mundo.add_child(raiz)

	for definicion in _disponibles(fase, dia, inventario):
		var ancla := mundo.find_child(String(definicion["ancla"]), true, false) as Node3D
		if ancla == null:
			continue
		var item_id := String(definicion["id"])
		var datos := objeto_inventario(item_id)
		if datos.is_empty():
			continue
		var recogible := _crear_recogible(datos, definicion, inventario)
		var offset: Vector3 = definicion["offset"]
		raiz.add_child(recogible)
		recogible.global_position = ancla.to_global(offset)
	return raiz


static func limpiar(mundo: Node3D) -> void:
	var anterior := mundo.get_node_or_null(NOMBRE_RAIZ)
	if anterior == null:
		return
	mundo.remove_child(anterior)
	anterior.queue_free()


static func listo_para_montar(
	mundo: Node3D, fase: String, dia: int, inventario: Dictionary
) -> bool:
	for definicion in _disponibles(fase, dia, inventario):
		if mundo.find_child(String(definicion["ancla"]), true, false) == null:
			return false
	return true


static func firma(fase: String, dia: int, inventario: Dictionary) -> String:
	var ids: Array[String] = []
	for definicion in _disponibles(fase, dia, inventario):
		ids.append(String(definicion["id"]))
	return "%s|%d|%s" % [fase, dia, ",".join(ids)]


static func ids_encontrables() -> Array[String]:
	var salida: Array[String] = []
	for definicion in DEFINICIONES:
		salida.append(String(definicion["id"]))
	return salida


static func objeto_inventario(item_id: String) -> Dictionary:
	var ficha := Publicaciones98.por_id(item_id)
	if ficha.is_empty() or bool(ficha.get("comprable", false)):
		return {}
	return {
		"id": item_id,
		"nombre": String(ficha.get("titulo", item_id)),
		"categoria": "publicacion",
		"categoria_editorial": String(ficha.get("categoria", "publicacion")),
		"origen": ORIGEN,
		"vendible": false,
		"precio": 0,
		"permite_casa": bool(ficha.get("permite_casa", false)),
	}


static func _disponibles(fase: String, dia: int, inventario: Dictionary) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for valor in DEFINICIONES:
		var definicion: Dictionary = valor
		if String(definicion.get("fase", "")) != fase:
			continue
		if dia < int(definicion.get("dia_min", 1)):
			continue
		var item_id := String(definicion.get("id", ""))
		if Inventario.contiene(inventario, item_id):
			continue
		salida.append(definicion)
	return salida


static func _crear_recogible(
	datos: Dictionary, definicion: Dictionary, inventario: Dictionary
) -> Recogible3D:
	var recogible := Recogible3D.new()
	var item_id := String(datos["id"])
	recogible.name = "PublicacionEncontrable_%s" % item_id
	recogible.configurar(inventario, datos)
	recogible.rotation_degrees = Vector3(0.0, float(definicion.get("giro_y", 0.0)), 0.0)
	recogible.set_meta("publicacion_id", item_id)
	recogible.set_meta("ancla_publicacion", String(definicion.get("ancla", "")))
	recogible.set_meta("encontrable_1998", true)
	_decorar(recogible, item_id)
	return recogible


static func _decorar(raiz: Node3D, item_id: String) -> void:
	var ficha := Publicaciones98.por_id(item_id)
	var tam := Vector3(0.23, 0.026, 0.17)
	if String(ficha.get("categoria", "")) == "guia_practica":
		tam = Vector3(0.20, 0.055, 0.15)

	var malla := MeshInstance3D.new()
	malla.name = "CuerpoPublicacion"
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	Modelos._pintar(malla, _color(item_id))
	raiz.add_child(malla)

	var franja := MeshInstance3D.new()
	franja.name = "FranjaPortada"
	var franja_malla := BoxMesh.new()
	franja_malla.size = Vector3(tam.x * 0.66, 0.008, tam.z * 0.28)
	franja.mesh = franja_malla
	franja.position = Vector3(tam.x * 0.08, tam.y * 0.58, -tam.z * 0.18)
	Modelos._pintar(franja, Color(0.72, 0.67, 0.48))
	raiz.add_child(franja)


static func _color(item_id: String) -> Color:
	match item_id:
		"byte_domestico_42":
			return Color(0.18, 0.28, 0.38)
		"marcador_98_deportes":
			return Color(0.22, 0.42, 0.26)
		"estratos_ciudad_06":
			return Color(0.50, 0.38, 0.24)
		"manual_casa_98":
			return Color(0.50, 0.47, 0.32)
		_:
			return Color(0.42, 0.22, 0.18)
