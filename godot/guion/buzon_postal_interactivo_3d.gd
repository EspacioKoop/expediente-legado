## Buzón físico del portal para #672.
##
## Usa el contrato común de interacción 3D: teclado y mando llegan por la acción
## semántica `interactuar`, sin teclas nuevas. El nodo no posee reglas de correo;
## solo presenta un volumen en el mundo y delega en CorreoPostal.
class_name BuzonPostalInteractivo3D
extends Interactuable3D

signal correo_recogido(resultado: Dictionary, actor: Node)
signal buzon_vacio(actor: Node)

const COLOR_CAJA := Color(0.18, 0.16, 0.14)
const COLOR_PUERTA := Color(0.30, 0.26, 0.20)
const COLOR_RANURA := Color(0.07, 0.06, 0.05)

var jornada: Dictionary = {}
var inventario: Dictionary = Inventario.nuevo()


func _ready() -> void:
	verbo = Verbo.ABRIR
	nombre_objeto = "buzón"
	_montar_geometria()
	_asegurar_volumen_interaccion()


func configurar(estado_jornada: Dictionary, estado_inventario: Dictionary) -> void:
	jornada = estado_jornada
	inventario = estado_inventario
	Inventario.completar(inventario)


func pendientes() -> int:
	if jornada.is_empty():
		return 0
	return CorreoPostal.disponibles(jornada).size()


func interactuar(actor: Node) -> bool:
	if jornada.is_empty():
		return false
	if not super.interactuar(actor):
		return false

	var resultado := CorreoPostal.recoger_siguiente(jornada, inventario)
	if not bool(resultado.get("ok", false)):
		buzon_vacio.emit(actor)
		return true

	correo_recogido.emit(resultado.duplicate(true), actor)
	return true


func _montar_geometria() -> void:
	if get_node_or_null("Caja") != null:
		return
	_crear_caja("Caja", Vector3(0.52, 0.68, 0.24), Vector3.ZERO, COLOR_CAJA)
	_crear_caja("Puerta", Vector3(0.44, 0.50, 0.035), Vector3(0, -0.02, -0.135), COLOR_PUERTA)
	_crear_caja("Ranura", Vector3(0.30, 0.045, 0.025), Vector3(0, 0.20, -0.16), COLOR_RANURA)


func _crear_caja(nombre: String, tam: Vector3, posicion: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = posicion
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	malla.material_override = material
	add_child(malla)


func _asegurar_volumen_interaccion() -> void:
	if get_node_or_null("VolumenInteraccion") != null:
		return
	var colision := CollisionShape3D.new()
	colision.name = "VolumenInteraccion"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.68, 0.86, 0.58)
	colision.shape = forma
	add_child(colision)
