## Representación 3D del desorden derivado del archivado (#965).
##
## Es deliberadamente visual: no añade CollisionShape3D ni modifica navegación.
## La cantidad lógica completa se conserva como metadata aunque solo se dibujen
## tres carpetas para evitar convertir un error recuperable en una pared.
class_name ArchivadoDesorden3D
extends RefCounted

const NOMBRE := "DesordenArchivado965"
const MAX_VISIBLES := 3
const COLOR_CARPETA := Color(0.68, 0.51, 0.24)


static func aplicar(archivador: Node3D, cantidad: int) -> void:
	if archivador == null:
		return
	var existente := archivador.get_node_or_null(NOMBRE)
	if existente != null:
		archivador.remove_child(existente)
		existente.queue_free()

	var total := maxi(0, cantidad)
	archivador.set_meta("archivado_desorden", total)
	if total == 0:
		return

	var raiz := Node3D.new()
	raiz.name = NOMBRE
	raiz.set_meta("cantidad_desorden", total)
	archivador.add_child(raiz)

	for i in mini(total, MAX_VISIBLES):
		var carpeta := MeshInstance3D.new()
		carpeta.name = "CarpetaDesorden%d" % (i + 1)
		var malla := BoxMesh.new()
		malla.size = Vector3(0.42, 0.025, 0.3)
		carpeta.mesh = malla
		var material := StandardMaterial3D.new()
		material.albedo_color = COLOR_CARPETA.lightened(float(i) * 0.035)
		material.roughness = 0.92
		carpeta.material_override = material
		carpeta.position = Vector3(-0.54 - i * 0.025, -0.58 + i * 0.03, 0.28 + i * 0.018)
		carpeta.rotation_degrees = Vector3(2.0 * i, -4.0 + 5.0 * i, 3.0 - 4.0 * i)
		raiz.add_child(carpeta)
