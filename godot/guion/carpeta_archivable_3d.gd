## Carpeta física transportable para el archivado manual (#157).
##
## No es inventario general: vive únicamente durante la sesión de archivado y
## contiene la referencia al caso ya conocido por el jugador.
class_name CarpetaArchivable3D
extends Interactuable3D

var caso: Dictionary = {}
var destino := ""


func configurar(un_caso: Dictionary) -> void:
	caso = un_caso.duplicate(true)
	destino = Archivado.destino_de(caso)
	verbo = Interactuable3D.Verbo.COGER
	nombre_objeto = "carpeta %s" % String(caso.get("id", ""))
	_montar_visual()


func llevar(actor: Node) -> bool:
	if actor == null or caso.is_empty():
		return false
	var camara := actor.get_node_or_null("Camara") as Camera3D
	if camara == null:
		return false
	reparent(camara)
	position = Vector3(0.42, -0.28, -0.78)
	rotation_degrees = Vector3(-8, -12, 4)
	habilitado = false
	monitorable = false
	collision_layer = 0
	return true


func _montar_visual() -> void:
	var cuerpo := MeshInstance3D.new()
	cuerpo.name = "CarpetaManila"
	var caja := BoxMesh.new()
	caja.size = Vector3(0.52, 0.035, 0.36)
	cuerpo.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.55, 0.25)
	material.roughness = 0.9
	cuerpo.material_override = material
	add_child(cuerpo)

	var pestana := MeshInstance3D.new()
	pestana.name = "Pestana"
	var caja_pestana := BoxMesh.new()
	caja_pestana.size = Vector3(0.18, 0.025, 0.07)
	pestana.mesh = caja_pestana
	pestana.position = Vector3(0.14, 0.03, -0.14)
	pestana.material_override = material
	add_child(pestana)

	var etiqueta := Label3D.new()
	etiqueta.name = "Etiqueta"
	etiqueta.text = String(caso.get("id", "EXP"))
	etiqueta.font_size = 32
	etiqueta.pixel_size = 0.003
	etiqueta.position = Vector3(0, 0.025, 0.01)
	etiqueta.rotation_degrees = Vector3(-90, 0, 0)
	etiqueta.modulate = Color(0.12, 0.1, 0.08)
	add_child(etiqueta)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.58, 0.12, 0.42)
	colision.shape = forma
	add_child(colision)
