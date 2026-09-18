## Tres coches aparcados y un cruce lejano de GGBotNet / PSX Style Cars (CC0-1.0, #230).
## El autor avisa de que la escala no es coherente entre modelos: cada ficha
## fija su propio largo real y el factor se calcula sobre la malla importada.
class_name CochesPsxCC0
extends RefCounted

const CARPETA := "res://assets/modelos/psx_cars/"
# nombre, modelo, posición, largo en metros, giro Y en grados. Circulación por
# la derecha: en la acera izquierda (x<0) el morro apunta a +Z; en la derecha, a -Z.
const COCHES := [
	["RancheraSur", "Car01", Vector3(-3.0, 0.0, -11.0), 4.60, 0.0],
	["MonovolumenCentro", "Car04", Vector3(2.8, 0.0, -3.5), 4.30, 180.0],
	["UtilitarioNorte", "Car03", Vector3(-3.0, 0.0, 9.5), 4.00, 0.0],
]
# Reutiliza Car03 detrás del cierre norte. No ocupa la zona jugable: cruza de
# izquierda a derecha en z=16,8, sin cuerpo físico, y reaparece fuera de plano.
const TRAFICO_FONDO := ["TraficoFondo", "Car03", Vector3(-7.0, 0.0, 16.8), 4.00, 90.0]
const DESPLAZAMIENTO_FONDO := 14.0
const DURACION_CRUCE := 7.0
const PAUSA_CRUCE := 5.0


static func montar(mundo: Node3D) -> Node3D:
	if mundo == null:
		return null
	var existente := mundo.get_node_or_null("CochesPsxCC0") as Node3D
	if existente != null:
		return existente
	var lote := Node3D.new()
	lote.name = "CochesPsxCC0"
	var materiales: Dictionary = {}
	for ficha in COCHES:
		lote.add_child(_crear_coche(ficha, materiales, true))
	var trafico := _crear_coche(TRAFICO_FONDO, materiales, false)
	lote.add_child(trafico)
	mundo.add_child(lote)
	_animar_trafico_fondo(trafico)
	return lote


static func _crear_coche(ficha: Array, materiales: Dictionary, con_colision: bool) -> Node3D:
	var coche := Node3D.new()
	coche.name = ficha[0]
	coche.position = ficha[2]
	coche.rotation_degrees.y = ficha[4]
	var escena := load(CARPETA + ficha[1] + ".glb") as PackedScene
	var modelo := escena.instantiate() as Node3D
	coche.add_child(modelo)
	var caja := AABB()
	for malla in modelo.find_children("*", "MeshInstance3D", true, false):
		var local: AABB = _transformacion_hasta(malla, modelo) * malla.get_aabb()
		caja = local if caja.size == Vector3.ZERO else caja.merge(local)
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_apagar_materiales(malla, materiales)
	# Largo sobre Z antes de aplicar el giro del nodo; se apoya la base real de
	# las ruedas en el asfalto tanto para aparcados como para el coche lejano.
	var factor: float = ficha[3] / caja.size.z
	modelo.scale = Vector3.ONE * factor
	modelo.position = -Vector3(caja.get_center().x, caja.position.y, caja.get_center().z) * factor
	if con_colision:
		# Los coches aparcados sí son volumen urbano alcanzable: una envolvente
		# simple impide atravesar la carrocería sin física de vehículo.
		var cuerpo := StaticBody3D.new()
		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = caja.size * factor
		colision.shape = forma
		colision.position.y = forma.size.y / 2.0
		cuerpo.add_child(colision)
		coche.add_child(cuerpo)
	return coche


static func _animar_trafico_fondo(coche: Node3D) -> void:
	# Un solo Tween ligado al nodo: sin NavigationAgent, VehicleBody ni _process
	# propio. El salto de vuelta sucede fuera del encuadre lateral.
	var tween := coche.create_tween().set_loops()
	tween.tween_property(coche, "position:x", DESPLAZAMIENTO_FONDO, DURACION_CRUCE).as_relative()
	tween.tween_interval(PAUSA_CRUCE)
	tween.tween_callback(func() -> void: coche.position.x -= DESPLAZAMIENTO_FONDO)


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
			mate.metallic = 0.0
			mate.roughness = 1.0
			mate.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			mate.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			mate.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			materiales[original] = mate
		malla.set_surface_override_material(indice, materiales[original])
