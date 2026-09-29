## Mitigación portátil de la bombilla fundida de #93 usando la linterna de #680.
##
## No repara el imprevisto ni crea un sistema global de iluminación: el haz solo
## existe en casa, mientras `casa_luz_reducida` siga activa y la linterna esté
## físicamente en `carried`. Guardarla en casa vuelve a dejar la estancia oscura.
class_name LinternaCasa680
extends RefCounted

const USO_REQUERIDO := UsosHerramienta.ILUMINAR
const CONSECUENCIA := "casa_luz_reducida"
const NOMBRE_LUZ := "HazLinterna680"
const ENERGIA := 2.2
const ALCANCE := 8.0
const ANGULO := 28.0


static func firma(estado_ambiental: Dictionary, inventario: Dictionary) -> String:
	return (
		"%d|%d"
		% [
			int(_luz_reducida(estado_ambiental)),
			int(not _herramienta(inventario).is_empty()),
		]
	)


static func activa(estado_ambiental: Dictionary, inventario: Dictionary) -> bool:
	return _luz_reducida(estado_ambiental) and not _herramienta(inventario).is_empty()


static func refrescar(
	caminante: Node3D, estado_ambiental: Dictionary, inventario: Dictionary
) -> SpotLight3D:
	limpiar(caminante)
	if not _luz_reducida(estado_ambiental):
		return null
	var herramienta := _herramienta(inventario)
	if herramienta.is_empty():
		return null

	var camara := caminante.get_node_or_null("Camara") as Camera3D
	if camara == null:
		return null

	var luz := SpotLight3D.new()
	luz.name = NOMBRE_LUZ
	luz.light_color = Color(0.92, 0.88, 0.72)
	luz.light_energy = ENERGIA
	luz.spot_range = ALCANCE
	luz.spot_angle = ANGULO
	luz.shadow_enabled = false
	luz.position = Vector3(0.08, -0.06, -0.10)
	luz.set_meta("prop_utilizable_id", String(herramienta.get("id", "")))
	luz.set_meta("uso_requerido", USO_REQUERIDO)
	luz.set_meta("mitiga_consecuencia", CONSECUENCIA)
	camara.add_child(luz)
	return luz


static func limpiar(caminante: Node3D) -> void:
	if caminante == null:
		return
	var camara := caminante.get_node_or_null("Camara") as Camera3D
	if camara == null:
		return
	var anterior := camara.get_node_or_null(NOMBRE_LUZ)
	if anterior == null:
		return
	camara.remove_child(anterior)
	anterior.queue_free()


static func _luz_reducida(estado_ambiental: Dictionary) -> bool:
	var consecuencias = estado_ambiental.get("consecuencias_casa", [])
	return typeof(consecuencias) == TYPE_ARRAY and consecuencias.has(CONSECUENCIA)


static func _herramienta(inventario: Dictionary) -> Dictionary:
	var resultado := UsosHerramienta.resolver(inventario, USO_REQUERIDO)
	if not bool(resultado.get("ok", false)):
		return {}
	var herramienta: Variant = resultado.get("herramienta", {})
	return (herramienta as Dictionary).duplicate(true) if herramienta is Dictionary else {}
