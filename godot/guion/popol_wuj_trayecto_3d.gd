## Punto de lectura exterior para la semilla Popol Wuj de #655.
##
## No compra, no persiste y no activa semillas directamente. Solo materializa
## en el trayecto una copia de consulta del cuaderno declarado en Publicaciones98;
## el VisorPublicacion común registra la lectura y decide el cierre deliberado.
class_name PopolWujTrayecto3D
extends RefCounted

const NOMBRE_RAIZ := "PuntoLecturaQuioscoPopolWuj"
const ITEM_ID := "libro_popol_wuj_98"
const FUENTE := "libro:popol_wuj_98"
const POSICION := Vector3(4.55, 0.0, 2.40)

const COLOR_ATRIL := Color(0.27, 0.24, 0.20)
const COLOR_METAL := Color(0.17, 0.18, 0.19)
const COLOR_ROTULO := Color(0.86, 0.76, 0.52)


static func montar(mundo: Node3D) -> Interactuable3D:
	if mundo == null:
		return null
	var existente := mundo.get_node_or_null(NOMBRE_RAIZ) as Node3D
	if existente != null:
		return existente.get_node_or_null("LeerPopolWuj") as Interactuable3D

	var raiz := Node3D.new()
	raiz.name = NOMBRE_RAIZ
	raiz.position = POSICION
	mundo.add_child(raiz)

	_caja(
		raiz,
		"AtrilQuiosco",
		Vector3(0.0, 0.48, 0.0),
		Vector3(0.62, 0.96, 0.42),
		COLOR_ATRIL,
	)
	_caja(
		raiz,
		"PeanaMetal",
		Vector3(0.0, 0.10, 0.0),
		Vector3(0.82, 0.20, 0.62),
		COLOR_METAL,
	)
	_rotulo(raiz)

	var lectura := Interactuable3D.new()
	lectura.name = "LeerPopolWuj"
	lectura.position = Vector3(0.0, 1.05, 0.0)
	lectura.rotation_degrees.y = -90.0
	lectura.verbo = Interactuable3D.Verbo.LEER
	lectura.nombre_objeto = "cuaderno cultural Popol Wuj"
	lectura.set_meta("publicacion_id", ITEM_ID)
	lectura.set_meta("fuente_semilla", FUENTE)
	lectura.set_meta("punto_lectura_trayecto", true)
	raiz.add_child(lectura)

	PublicacionFisica3D.montar(lectura, ITEM_ID)

	var colision := CollisionShape3D.new()
	colision.name = "VolumenLectura"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.90, 1.10, 0.90)
	colision.shape = forma
	lectura.add_child(colision)
	return lectura


static func limpiar(mundo: Node3D) -> void:
	if mundo == null:
		return
	var raiz := mundo.get_node_or_null(NOMBRE_RAIZ)
	if raiz == null:
		return
	mundo.remove_child(raiz)
	raiz.queue_free()


static func _rotulo(raiz: Node3D) -> void:
	var etiqueta := Label3D.new()
	etiqueta.name = "RotuloQuioscoCultural"
	etiqueta.text = "QUIOSCO · CUADERNO CULTURAL"
	etiqueta.font = EstiloSiga.fuente_mono()
	etiqueta.font_size = 28
	etiqueta.pixel_size = 0.0022
	etiqueta.modulate = COLOR_ROTULO
	etiqueta.outline_size = 6
	etiqueta.outline_modulate = Color(0.0, 0.0, 0.0, 0.82)
	etiqueta.position = Vector3(0.0, 1.48, 0.0)
	etiqueta.rotation_degrees.y = 180.0
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.shaded = false
	raiz.add_child(etiqueta)


static func _caja(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	tam: Vector3,
	color: Color,
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.position = posicion
	var malla := BoxMesh.new()
	malla.size = tam
	nodo.mesh = malla
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
