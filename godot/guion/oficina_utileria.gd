## Utilería procedural y reutilizada para que los puestos del archivo parezcan
## usados antes de abrir ningún HUD (#400).
##
## No añade reglas: teclados, teléfonos, bandejas, tazas y cableado son dressing.
## Los dos puestos que aún no tenían monitor reciben el mismo modelo ya versionado
## que usa el catálogo. La única interacción de este corte es la máquina de café.
class_name OficinaUtileria
extends RefCounted

const COLOR_PERIFERICO := Color(0.64, 0.62, 0.56)
const COLOR_TELEFONO := Color(0.20, 0.20, 0.19)
const COLOR_BANDEJA := Color(0.31, 0.29, 0.25)
const COLOR_PAPEL := Color(0.82, 0.80, 0.72)
const COLOR_CAFE := Color(0.68, 0.66, 0.58)
const COLOR_CABLE := Color(0.08, 0.08, 0.08)

const PUESTOS := [
	Vector3(-4.0, 0.0, -2.0),
	Vector3(-4.0, 0.0, 1.0),
	Vector3(1.0, 0.0, -2.0),
	Vector3(1.0, 0.0, 1.0),
]


static func montar(raiz: Node3D) -> void:
	for i in PUESTOS.size():
		_montar_puesto(raiz, i, PUESTOS[i])
	_montar_maquina_cafe(raiz)


static func _montar_puesto(raiz: Node3D, indice: int, base: Vector3) -> void:
	var puesto := Node3D.new()
	puesto.name = "PuestoUtileria%d" % (indice + 1)
	puesto.position = base
	raiz.add_child(puesto)

	# El teclado está delante del monitor y hace legible el escritorio como
	# puesto de trabajo incluso desde el pasillo central.
	_agregar_caja(
		puesto,
		"Teclado",
		Vector3(0.18, 0.79, 0.20),
		Vector3(0.58, 0.055, 0.22),
		COLOR_PERIFERICO
	)
	_agregar_caja(
		puesto,
		"CableTeclado",
		Vector3(0.18, 0.785, -0.02),
		Vector3(0.035, 0.025, 0.28),
		COLOR_CABLE
	)

	# El teléfono cambia de lado entre puestos para romper la repetición de la
	# planta sin fingir que cada mesa pertenece a un personaje concreto.
	var lado := -0.70 if indice % 2 == 0 else 0.70
	_agregar_caja(
		puesto,
		"TelefonoBase",
		Vector3(lado, 0.82, 0.12),
		Vector3(0.36, 0.10, 0.28),
		COLOR_TELEFONO
	)
	_agregar_caja(
		puesto,
		"Auricular",
		Vector3(lado, 0.91, 0.12),
		Vector3(0.42, 0.08, 0.10),
		COLOR_TELEFONO
	)

	# Alterna bandejas y taza: cuatro escritorios idénticos siguen pareciendo
	# un decorado aunque tengan muchos polígonos.
	if indice % 2 == 0:
		_agregar_bandeja(puesto, Vector3(-0.62, 0.81, -0.24))
	else:
		_agregar_taza(puesto, Vector3(-0.58, 0.86, -0.22))

	# Los dos puestos de la derecha eran los únicos sin CRT reconocible. Se usa
	# el modelo ya versionado; no se introduce otro asset ni una caja sustituta.
	if indice >= 2:
		var monitor := Node3D.new()
		monitor.name = "MonitorCRT"
		monitor.position = Vector3(-0.22, 0.97, -0.18)
		puesto.add_child(monitor)
		Modelos.mueble(
			monitor,
			"computerScreen",
			Vector3(0.50, 0.45, 0.40),
			Color(0.52, 0.54, 0.50)
		)


static func _agregar_bandeja(raiz: Node3D, pos: Vector3) -> void:
	var bandeja := Node3D.new()
	bandeja.name = "BandejaEntrada"
	bandeja.position = pos
	raiz.add_child(bandeja)
	_agregar_caja(
		bandeja, "BaseBandeja", Vector3.ZERO, Vector3(0.44, 0.045, 0.32), COLOR_BANDEJA
	)
	_agregar_caja(
		bandeja, "PapelBandeja", Vector3(0, 0.035, 0), Vector3(0.36, 0.025, 0.25), COLOR_PAPEL
	)


static func _agregar_taza(raiz: Node3D, pos: Vector3) -> void:
	var taza := MeshInstance3D.new()
	taza.name = "TazaPuesto"
	var malla := CylinderMesh.new()
	malla.top_radius = 0.085
	malla.bottom_radius = 0.075
	malla.height = 0.18
	taza.mesh = malla
	taza.position = pos
	_aplicar_material(taza, COLOR_CAFE)
	raiz.add_child(taza)


static func _montar_maquina_cafe(raiz: Node3D) -> void:
	var maquina := MaquinaCafeInteractiva3D.new()
	maquina.name = "MaquinaCafeInteractuable"
	# Coincide con el bulto de la máquina ya declarado en EspaciosCatalogo.
	maquina.position = Vector3(-6.0, 0.75, 4.2)
	raiz.add_child(maquina)
	maquina.configurar()


static func _agregar_caja(
	raiz: Node3D, nombre: String, pos: Vector3, tam: Vector3, color: Color
) -> void:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	_aplicar_material(malla, color)
	raiz.add_child(malla)


static func _aplicar_material(malla: MeshInstance3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	malla.material_override = material
