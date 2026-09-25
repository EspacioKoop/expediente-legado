## Tres GLB originales de jamesdev / MilkAndBanana (CC0-1.0).
## El atlas conserva sus UV; los materiales se comparten solo dentro del lote.
class_name TraficoVialCC0
extends RefCounted

const CARPETA := "res://assets/modelos/traffic_road/"
const HOLGURA_TAPA := 0.0015
const PIEZAS := [
	["TapaSur", "Manhole_Cover", Vector3(-2.0, 0.0, -5.0), 0.70, 0.0],
	["TapaNorte", "Manhole_Cover", Vector3(2.0, 0.0, 11.0), 0.70, 0.0],
	["Barrera", "Road_Block", Vector3(3.25, 0.0, 6.0), 1.10, 90.0],
	["ConoSur", "Traffic_Cone", Vector3(3.25, 0.0, 4.7), 0.65, 0.0],
	["ConoNorte", "Traffic_Cone", Vector3(3.25, 0.0, 7.3), 0.65, 0.0],
]


static func montar(mundo: Node3D) -> Node3D:
	if mundo == null:
		return null
	var existente := mundo.get_node_or_null("TraficoVialCC0") as Node3D
	if existente != null:
		return existente
	var lote := Node3D.new()
	lote.name = "TraficoVialCC0"
	var materiales: Dictionary = {}
	for ficha in PIEZAS:
		var pieza := _crear_pieza(ficha, materiales)
		lote.add_child(pieza)
	mundo.add_child(lote)
	return lote


static func _crear_pieza(ficha: Array, materiales: Dictionary) -> Node3D:
	var pieza := Node3D.new()
	pieza.name = ficha[0]
	pieza.position = ficha[2]
	pieza.rotation_degrees.y = ficha[4]
	var escena := load(CARPETA + ficha[1] + ".glb") as PackedScene
	var modelo := escena.instantiate() as Node3D
	pieza.add_child(modelo)
	var caja := AABB()
	for malla in modelo.find_children("*", "MeshInstance3D", true, false):
		var local: AABB = _transformacion_hasta(malla, modelo) * malla.get_aabb()
		caja = local if caja.size == Vector3.ZERO else caja.merge(local)
		# Dressing secundario: la calle ya tiene iluminación/sombras propias y
		# estas cinco piezas no justifican una pasada de sombras adicional.
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_apagar_materiales(malla, materiales)
	# Apoyar la base real sobre el asfalto, no el origen desplazado del GLB.
	var medida: float = (
		maxf(caja.size.x, caja.size.z) if ficha[1] == "Manhole_Cover" else caja.size.y
	)
	var factor: float = ficha[3] / medida
	modelo.scale = Vector3.ONE * factor
	modelo.position = -Vector3(caja.get_center().x, caja.position.y, caja.get_center().z) * factor
	if ficha[1] == "Manhole_Cover":
		# La tapa tiene grosor real: se empotra en el asfalto y solo se deja
		# una holgura mínima en la cara superior para evitar z-fighting.
		modelo.position.y -= caja.size.y * factor - HOLGURA_TAPA
	if ficha[1] == "Road_Block":
		# La barrera alcanza la calzada: una caja evita atravesarla sin
		# introducir física de vehículo ni colisión por triángulo.
		var cuerpo := StaticBody3D.new()
		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = caja.size * factor
		colision.shape = forma
		colision.position.y = forma.size.y / 2.0
		cuerpo.add_child(colision)
		pieza.add_child(cuerpo)
	return pieza


static func _transformacion_hasta(nodo: Node3D, raiz: Node3D) -> Transform3D:
	var resultado := nodo.transform
	var padre := nodo.get_parent()
	while padre != raiz:
		resultado = (padre as Node3D).transform * resultado
		padre = padre.get_parent()
	return resultado


static func _apagar_materiales(malla: MeshInstance3D, materiales: Dictionary) -> void:
	for indice in malla.mesh.get_surface_count():
		var original := malla.get_active_material(indice) as StandardMaterial3D
		if not materiales.has(original):
			var mate := original.duplicate() as StandardMaterial3D
			mate.albedo_color = Color(0.72, 0.72, 0.72)
			mate.metallic = 0.0
			mate.roughness = 1.0
			mate.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			mate.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			mate.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			materiales[original] = mate
		malla.set_surface_override_material(indice, materiales[original])
