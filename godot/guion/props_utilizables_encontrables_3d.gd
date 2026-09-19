## Props de #680 que aparecen en el recorrido normal sin crear otro inventario.
##
## La palanca nace junto al almacenamiento doméstico: es una herramienta vieja
## disponible desde casa y su uso concreto pertenece a la persiana (#1061).
## Mientras Crowbar.glb no esté materializado por #1064, conserva un proxy
## procedural. La identidad, recogida y persistencia no dependen de la malla.
class_name PropsUtilizablesEncontrables3D
extends RefCounted

const Props := preload("res://guion/props_utilizables_cc0.gd")

const NOMBRE_RAIZ := "PropsUtilizablesEncontrables680"
const RUTA_MODELOS := "res://assets/modelos/street_furniture/"
const LARGOS_VISUALES := {"Crowbar": 0.72, "Flashlight": 0.26}
const SEGMENTOS_PROXY_LINTERNA := 8
const ANILLOS_PROXY_LINTERNA := 1

const DEFINICIONES := [
	{
		"id": "palanca_kkryy",
		"fase": "casa",
		"dia_min": 1,
		"ancla": "AlmacenamientoCasa",
		"offset": Vector3(0.30, 0.98, -0.08),
		"rotacion": Vector3(-8.0, 18.0, 72.0),
	},
	{
		"id": "linterna_kkryy",
		"fase": "casa",
		"dia_min": 1,
		"ancla": "AlmacenamientoCasa",
		"offset": Vector3(-0.31, 0.96, 0.02),
		"rotacion": Vector3(84.0, -12.0, -18.0),
	},
]


static func montar(mundo: Node3D, fase: String, dia: int, inventario: Dictionary) -> Node3D:
	limpiar(mundo)
	var raiz := Node3D.new()
	raiz.name = NOMBRE_RAIZ
	mundo.add_child(raiz)

	for definicion in _disponibles(fase, dia, inventario):
		var ancla := mundo.find_child(String(definicion["ancla"]), true, false) as Node3D
		if ancla == null:
			continue
		var item_id := String(definicion["id"])
		var recogible := Props.crear_recogible(item_id, inventario)
		if recogible == null:
			continue
		recogible.name = "PropEncontrable_%s" % item_id
		recogible.set_meta("ancla_prop_utilizable", String(definicion["ancla"]))
		recogible.set_meta("encontrable_680", true)
		_montar_visual(recogible, String(Props.definicion(item_id).get("modelo", "")))
		raiz.add_child(recogible)
		var offset: Vector3 = definicion["offset"]
		var rotacion: Vector3 = definicion["rotacion"]
		recogible.global_position = ancla.to_global(offset)
		recogible.global_rotation = (
			ancla.global_rotation
			+ Vector3(deg_to_rad(rotacion.x), deg_to_rad(rotacion.y), deg_to_rad(rotacion.z))
		)
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


static func _disponibles(fase: String, dia: int, inventario: Dictionary) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for valor in DEFINICIONES:
		var definicion: Dictionary = valor
		if String(definicion.get("fase", "")) != fase:
			continue
		if dia < int(definicion.get("dia_min", 1)):
			continue
		if Inventario.contiene(inventario, String(definicion.get("id", ""))):
			continue
		salida.append(definicion)
	return salida


static func _montar_visual(recogible: Recogible3D, modelo: String) -> void:
	var ruta := RUTA_MODELOS + modelo + ".glb"
	if not modelo.is_empty() and ResourceLoader.exists(ruta):
		var escena := load(ruta) as PackedScene
		if escena != null:
			var visual := escena.instantiate() as Node3D
			if visual != null:
				visual.name = "VisualStreetFurniture"
				recogible.add_child(visual)
				_encajar_visual(visual, float(LARGOS_VISUALES.get(modelo, 0.32)))
				Modelos._pintar(visual, Color(0.34, 0.35, 0.34), "metal_pintado")
				recogible.set_meta("visual_prop_utilizable", "glb")
				return
	_montar_proxy(recogible, modelo)
	recogible.set_meta("visual_prop_utilizable", "proxy")


static func _montar_proxy(recogible: Node3D, modelo: String) -> void:
	if modelo == "Flashlight":
		_montar_proxy_linterna(recogible)
		return
	_montar_proxy_palanca(recogible)


static func _montar_proxy_palanca(recogible: Node3D) -> void:
	var proxy := Node3D.new()
	proxy.name = "ProxyPalanca"
	recogible.add_child(proxy)
	_barra(proxy, Vector3.ZERO, Vector3(0.055, 0.055, 0.58), Vector3.ZERO)
	_barra(
		proxy,
		Vector3(0.0, 0.055, -0.315),
		Vector3(0.055, 0.055, 0.16),
		Vector3(deg_to_rad(38.0), 0.0, 0.0)
	)
	_barra(
		proxy,
		Vector3(0.0, -0.035, 0.315),
		Vector3(0.055, 0.055, 0.15),
		Vector3(deg_to_rad(-24.0), 0.0, 0.0)
	)


static func _montar_proxy_linterna(recogible: Node3D) -> void:
	var proxy := Node3D.new()
	proxy.name = "ProxyLinterna"
	recogible.add_child(proxy)

	var cuerpo := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.045
	cilindro.bottom_radius = 0.045
	cilindro.height = 0.19
	cilindro.radial_segments = SEGMENTOS_PROXY_LINTERNA
	cilindro.rings = ANILLOS_PROXY_LINTERNA
	cuerpo.mesh = cilindro
	proxy.add_child(cuerpo)
	Modelos._pintar(cuerpo, Color(0.16, 0.17, 0.17), "metal_pintado")

	var cabeza := MeshInstance3D.new()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.07
	cono.bottom_radius = 0.048
	cono.height = 0.07
	cono.radial_segments = SEGMENTOS_PROXY_LINTERNA
	cono.rings = ANILLOS_PROXY_LINTERNA
	cabeza.mesh = cono
	cabeza.position.y = 0.13
	proxy.add_child(cabeza)
	Modelos._pintar(cabeza, Color(0.29, 0.30, 0.29), "metal_pintado")

	var lente := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.058
	disco.bottom_radius = 0.058
	disco.height = 0.012
	disco.radial_segments = SEGMENTOS_PROXY_LINTERNA
	disco.rings = ANILLOS_PROXY_LINTERNA
	lente.mesh = disco
	lente.position.y = 0.171
	proxy.add_child(lente)
	Modelos._pintar(lente, Color(0.68, 0.67, 0.52))


static func _barra(padre: Node3D, posicion: Vector3, tam: Vector3, rotacion: Vector3) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = posicion
	malla.rotation = rotacion
	padre.add_child(malla)
	Modelos._pintar(malla, Color(0.34, 0.35, 0.34), "metal_pintado")


static func _encajar_visual(visual: Node3D, largo_objetivo: float) -> void:
	var limites := _limites(visual)
	if limites.size == Vector3.ZERO:
		return
	var mayor := maxf(limites.size.x, maxf(limites.size.y, limites.size.z))
	if mayor <= 0.0:
		return
	var escala := largo_objetivo / mayor
	visual.scale = Vector3.ONE * escala
	visual.position = -limites.get_center() * escala


static func _limites(nodo: Node3D) -> AABB:
	var total := AABB()
	var primero := true
	for malla in _mallas(nodo):
		var caja := malla.get_aabb()
		var transformacion := nodo.global_transform.affine_inverse() * malla.global_transform
		caja = transformacion * caja
		if primero:
			total = caja
			primero = false
		else:
			total = total.merge(caja)
	return total


static func _mallas(nodo: Node) -> Array[MeshInstance3D]:
	var salida: Array[MeshInstance3D] = []
	if nodo is MeshInstance3D:
		salida.append(nodo)
	for hijo in nodo.get_children():
		salida.append_array(_mallas(hijo))
	return salida
