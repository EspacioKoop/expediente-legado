## Utilería doméstica procedural para dar lectura 3D a la casa (#133, #282, #400).
##
## Los objetos siguen construidos con primitivas simples y sin assets externos.
## La composición separa usos domésticos reconocibles antes de añadir más props:
## estar frente a la tele, cocina/servicio, descanso ya declarado en el catálogo
## y almacenamiento. La lámpara, el televisor, la portátil y el cajón conservan
## la interacción común de #283 sin introducir persistencia ni reglas de jornada.
##
## La materia no es un segundo sistema: estas primitivas usan el mismo shader PSX
## y la misma biblioteca TexturaProcedural que los espacios y muebles importados.
## Así un sofá, una encimera o una estantería dejan de ser cajas de color plano
## sin introducir binarios ni una biblioteca paralela para la casa (#398, #399).
class_name CasaUtileria
extends RefCounted


static func montar(raiz: Node3D) -> void:
	montar_zonas_domesticas(raiz)
	_montar_mesita(raiz, Vector3(-2.45, 0.0, 0.35))
	_montar_portatil(raiz, Vector3(-2.45, 0.68, 0.35))
	_montar_lampara_pie(raiz, Vector3(-0.65, 0.0, 0.55))
	_montar_almacenamiento(raiz, Vector3(0.0, 0.0, -3.05))
	_montar_televisor_interactivo(raiz)


## Vertical espacial de #133. Se mantiene separado de las interacciones para
## poder probar que la casa se lee por zonas aunque consola, compras o gato no
## estén activos.
static func montar_zonas_domesticas(raiz: Node3D) -> void:
	_montar_sofa(raiz, Vector3(-1.65, 0.0, 1.35), 90.0)
	_montar_cocina(raiz, Vector3(3.30, 0.0, -0.15))
	_montar_ventana(raiz, Vector3(-2.10, 1.65, -3.42))
	_montar_estanteria_compras(raiz, Vector3(1.25, 0.0, -3.22))


static func _montar_sofa(raiz: Node3D, pos: Vector3, giro_y: float) -> void:
	var sofa := Node3D.new()
	sofa.name = "SofaCasa"
	sofa.position = pos
	sofa.rotation_degrees.y = giro_y
	raiz.add_child(sofa)

	# La trama regular de la moqueta sirve aquí como tejido basto: mantiene una
	# escala reconocible y separa el sofá de madera/metal sin asset adicional.
	var tela := Color(0.31, 0.25, 0.23)
	var tela_oscura := Color(0.24, 0.19, 0.18)
	_agregar_caja(sofa, Vector3(0, 0.34, 0), Vector3(1.80, 0.34, 0.72), tela, "moqueta")
	_agregar_caja(
		sofa, Vector3(0, 0.78, 0.30), Vector3(1.80, 0.88, 0.18), tela_oscura, "moqueta"
	)
	_agregar_caja(
		sofa, Vector3(-0.87, 0.52, 0), Vector3(0.16, 0.52, 0.72), tela_oscura, "moqueta"
	)
	_agregar_caja(
		sofa, Vector3(0.87, 0.52, 0), Vector3(0.16, 0.52, 0.72), tela_oscura, "moqueta"
	)


static func _montar_cocina(raiz: Node3D, pos: Vector3) -> void:
	var cocina := Node3D.new()
	cocina.name = "CocinaCasa"
	cocina.position = pos
	raiz.add_child(cocina)

	var mueble := Color(0.38, 0.31, 0.25)
	var encimera := Color(0.24, 0.23, 0.22)
	var metal := Color(0.44, 0.46, 0.45)
	_agregar_caja(
		cocina, Vector3(0, 0.45, 0), Vector3(0.56, 0.90, 1.80), mueble, "melamina"
	)
	_agregar_caja(
		cocina, Vector3(-0.02, 0.93, 0), Vector3(0.64, 0.08, 1.92), encimera, "melamina"
	)

	var fregadero := Node3D.new()
	fregadero.name = "FregaderoCasa"
	fregadero.position = Vector3(-0.03, 0.99, 0.30)
	cocina.add_child(fregadero)
	_agregar_caja(
		fregadero, Vector3.ZERO, Vector3(0.44, 0.035, 0.58), metal, "metal_pintado"
	)
	_agregar_cilindro(
		fregadero, Vector3(0.12, 0.20, 0.12), 0.025, 0.36, metal, "metal_pintado"
	)
	_agregar_caja(
		fregadero,
		Vector3(0.08, 0.36, 0.12),
		Vector3(0.22, 0.04, 0.04),
		metal,
		"metal_pintado"
	)

	var nevera := Node3D.new()
	nevera.name = "NeveraCasa"
	nevera.position = Vector3(0, 0, -1.48)
	cocina.add_child(nevera)
	_agregar_caja(
		nevera,
		Vector3(0, 0.91, 0),
		Vector3(0.72, 1.82, 0.72),
		Color(0.55, 0.54, 0.50),
		"metal_pintado"
	)
	_agregar_caja(
		nevera,
		Vector3(-0.37, 1.16, -0.23),
		Vector3(0.035, 0.52, 0.07),
		metal,
		"metal_pintado"
	)
	_agregar_caja(
		nevera,
		Vector3(-0.37, 0.55, -0.23),
		Vector3(0.035, 0.34, 0.07),
		metal,
		"metal_pintado"
	)


static func _montar_ventana(raiz: Node3D, pos: Vector3) -> void:
	var ventana := Node3D.new()
	ventana.name = "VentanaCasa"
	ventana.position = pos
	raiz.add_child(ventana)

	var marco := Color(0.31, 0.27, 0.23)
	var cristal := Color(0.10, 0.14, 0.18)
	# El vidrio queda intencionadamente liso; el marco sí lleva una veta que lo
	# diferencia del hueco oscuro y evita que toda la ventana sea un bloque plano.
	_agregar_caja(ventana, Vector3.ZERO, Vector3(1.80, 1.10, 0.035), cristal)
	_agregar_caja(
		ventana, Vector3(0, 0.58, 0), Vector3(1.94, 0.10, 0.08), marco, "melamina"
	)
	_agregar_caja(
		ventana, Vector3(0, -0.58, 0), Vector3(1.94, 0.10, 0.08), marco, "melamina"
	)
	_agregar_caja(
		ventana, Vector3(-0.92, 0, 0), Vector3(0.10, 1.18, 0.08), marco, "melamina"
	)
	_agregar_caja(
		ventana, Vector3(0.92, 0, 0), Vector3(0.10, 1.18, 0.08), marco, "melamina"
	)
	_agregar_caja(
		ventana, Vector3(0, 0, 0), Vector3(0.07, 1.08, 0.075), marco, "melamina"
	)


static func _montar_estanteria_compras(raiz: Node3D, pos: Vector3) -> void:
	var estanteria := Node3D.new()
	estanteria.name = "EstanteriaComprasCasa"
	estanteria.position = pos
	raiz.add_child(estanteria)

	var madera := Color(0.32, 0.23, 0.17)
	_agregar_caja(
		estanteria, Vector3(-0.48, 0.82, 0), Vector3(0.10, 1.64, 0.34), madera, "melamina"
	)
	_agregar_caja(
		estanteria, Vector3(0.48, 0.82, 0), Vector3(0.10, 1.64, 0.34), madera, "melamina"
	)
	for y in [0.08, 0.58, 1.08, 1.58]:
		_agregar_caja(
			estanteria, Vector3(0, y, 0), Vector3(1.02, 0.09, 0.36), madera, "melamina"
		)


static func _montar_mesita(raiz: Node3D, pos: Vector3) -> void:
	var mesa := Node3D.new()
	mesa.name = "MesitaCasa"
	mesa.position = pos
	raiz.add_child(mesa)

	_agregar_caja(
		mesa,
		Vector3(0, 0.55, 0),
		Vector3(0.82, 0.12, 0.62),
		Color(0.32, 0.23, 0.17),
		"melamina"
	)
	for x in [-0.31, 0.31]:
		for z in [-0.21, 0.21]:
			_agregar_caja(
				mesa,
				Vector3(x, 0.28, z),
				Vector3(0.10, 0.56, 0.10),
				Color(0.27, 0.19, 0.14),
				"melamina"
			)


static func _montar_portatil(raiz: Node3D, pos: Vector3) -> void:
	var portatil := ConsolaPortatil98.new()
	portatil.name = "ConsolaPortatil98"
	portatil.position = pos
	portatil.rotation_degrees = Vector3(-12.0, 18.0, 0.0)
	raiz.add_child(portatil)
	portatil.configurar()


static func _montar_almacenamiento(raiz: Node3D, pos: Vector3) -> void:
	var almacenamiento := AlmacenamientoCasaInteractivo3D.new()
	almacenamiento.name = "AlmacenamientoCasa"
	almacenamiento.position = pos
	# Está contra el muro del fondo; el cajón debe abrir hacia el interior.
	almacenamiento.rotation_degrees.y = 180.0
	raiz.add_child(almacenamiento)
	almacenamiento.configurar()


## El catálogo sigue siendo dueño de la posición y el tamaño del televisor.
## Aquí solo se superpone un volumen enfocable y el feedback luminoso local.
static func _montar_televisor_interactivo(raiz: Node3D) -> void:
	for bulto in EspaciosCatalogo.CASA.get("bultos", []):
		if String(bulto.get("modelo", "")) != "televisionVintage":
			continue
		var televisor := TelevisionInteractiva3D.new()
		televisor.name = "TelevisorCasaInteractuable"
		televisor.position = bulto["pos"]
		raiz.add_child(televisor)
		televisor.configurar(bulto["tam"])
		return


static func _montar_lampara_pie(raiz: Node3D, pos: Vector3) -> void:
	var lampara := LamparaInteractiva3D.new()
	lampara.name = "LamparaPieCasa"
	lampara.position = pos
	raiz.add_child(lampara)
	lampara.configurar()

	_agregar_cilindro(
		lampara,
		Vector3(0, 0.05, 0),
		0.28,
		0.10,
		Color(0.18, 0.17, 0.16),
		"metal_pintado"
	)
	_agregar_cilindro(
		lampara,
		Vector3(0, 0.82, 0),
		0.045,
		1.55,
		Color(0.26, 0.24, 0.22),
		"metal_pintado"
	)
	_agregar_pantalla(lampara, Vector3(0, 1.62, 0))


static func _agregar_pantalla(raiz: Node3D, pos: Vector3) -> void:
	var malla := MeshInstance3D.new()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.22
	cono.bottom_radius = 0.38
	cono.height = 0.46
	malla.mesh = cono
	malla.position = pos
	malla.material_override = _material(Color(0.72, 0.61, 0.43), "moqueta")
	raiz.add_child(malla)


static func _agregar_caja(
	raiz: Node3D, pos: Vector3, tam: Vector3, color: Color, textura: String = ""
) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	malla.material_override = _material(color, textura)
	raiz.add_child(malla)


static func _agregar_cilindro(
	raiz: Node3D,
	pos: Vector3,
	radio: float,
	alto: float,
	color: Color,
	textura: String = ""
) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	malla.material_override = _material(color, textura)
	raiz.add_child(malla)


## Misma ruta de material que `Espacio3D`/`Modelos`: shader PSX común y textura
## triplanar por nombre. Al usar coordenadas de mundo, dos piezas del mismo
## material mantienen la misma escala aunque sus cajas tengan tamaños distintos.
static func _material(color: Color, textura: String = "") -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ResourceLoader.load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	if not textura.is_empty():
		var imagen := TexturaProcedural.por_nombre(textura, color, hash(textura))
		if imagen != null:
			material.set_shader_parameter("textura", imagen)
			material.set_shader_parameter("con_textura", true)
			material.set_shader_parameter("escala_textura", 1.2)
	return material
