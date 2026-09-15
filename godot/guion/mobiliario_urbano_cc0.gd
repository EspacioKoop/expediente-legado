## Basura de calle y aparatos de aire de Kkryy / Street Furniture (CC0-1.0, #222).
## Los FBX del pack no comparten escala: cada ficha fija su medida real y el
## factor se calcula sobre la malla importada.
class_name MobiliarioUrbanoCC0
extends RefCounted

const CARPETA := "res://assets/modelos/street_furniture/"
const ACERA_Y := 0.14

# nombre, modelo, posición (base apoyada, o centro de la cara trasera si va en
# fachada), medida real (alto; en el cartón, lado mayor), giro Y en grados.
# En los aparatos de aire la rejilla está en +X local: 180° en la fachada
# derecha (x > 0) y 0° en la izquierda.
const PIEZAS := [
	# Contenedor en la calzada junto al bordillo, con la basura desbordada en la acera.
	["Contenedor", "TrashCan", Vector3(3.35, 0.0, 10.0), 1.35, 90.0],
	["BolsaContenedorA", "GarbageBag", Vector3(4.35, ACERA_Y, 9.35), 0.55, 0.0],
	["BolsaContenedorB", "GarbageBag", Vector3(4.55, ACERA_Y, 10.05), 0.48, 70.0],
	["BolsaContenedorC", "GarbageBag", Vector3(4.30, ACERA_Y, 10.75), 0.42, 150.0],
	["CartonContenedor", "Cardboard", Vector3(4.75, ACERA_Y + 0.01, 11.35), 0.95, 25.0],
	# Aparatos de aire colgados de las fachadas, por encima de las ventanas.
	["AireFachadaSur", "Conditioner", Vector3(5.50, 3.35, -7.20), 0.62, 180.0],
	["AireFachadaNorte", "Conditioner", Vector3(5.55, 2.75, 11.60), 0.62, 180.0],
	["AireFachadaOeste", "Conditioner", Vector3(-5.50, 3.40, 12.20), 0.62, 0.0],
]
const EN_FACHADA := ["Conditioner"]
const CON_COLISION := ["TrashCan"]


static func montar(mundo: Node3D) -> Node3D:
	if mundo == null:
		return null
	var existente := mundo.get_node_or_null("MobiliarioUrbanoCC0") as Node3D
	if existente != null:
		return existente
	var lote := Node3D.new()
	lote.name = "MobiliarioUrbanoCC0"
	var materiales: Dictionary = {}
	for ficha in PIEZAS:
		lote.add_child(_crear_pieza(ficha, materiales))
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
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_apagar_materiales(malla, materiales)
	var medida: float = maxf(caja.size.x, caja.size.z) if ficha[1] == "Cardboard" else caja.size.y
	var factor: float = ficha[3] / medida
	modelo.scale = Vector3.ONE * factor
	if ficha[1] in EN_FACHADA:
		# La rejilla mira a +X local: la cara opuesta toca la fachada.
		modelo.position = (
			-Vector3(caja.position.x, caja.get_center().y, caja.get_center().z) * factor
		)
	else:
		modelo.position = (
			-Vector3(caja.get_center().x, caja.position.y, caja.get_center().z) * factor
		)
	if ficha[1] in CON_COLISION:
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
			mate.metallic = 0.0
			mate.roughness = 1.0
			mate.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			mate.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			mate.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			if ficha_transparente(original):
				mate.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				mate.alpha_scissor_threshold = 0.3
			# Bolsas y cartón son láminas finas: se ven por las dos caras.
			mate.cull_mode = BaseMaterial3D.CULL_DISABLED
			materiales[original] = mate
		malla.set_surface_override_material(indice, materiales[original])


## Bolsas, cartón y basura usan recortes con alfa en su textura.
static func ficha_transparente(material: StandardMaterial3D) -> bool:
	var textura := material.albedo_texture
	return (
		textura != null and textura.get_image() != null and textura.get_image().detect_alpha() != 0
	)
