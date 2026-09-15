## Utilería doméstica procedural para dar lectura 3D a la casa (#133, #282, #400).
##
## Los objetos siguen construidos con primitivas simples y sin assets externos.
## La composición separa usos domésticos reconocibles antes de añadir más props:
## estar frente a la tele, cocina/servicio, descanso ya declarado en el catálogo
## y almacenamiento. La lámpara, el televisor, las consolas y el cajón conservan
## la interacción común de #283 sin introducir persistencia ni reglas de jornada.
##
## Desde #399 la forma procedural también recibe MATERIA: madera, tejido y acero
## domésticos usan la misma canalización PSX que los modelos importados, evitando
## que la casa vuelva a parecer un conjunto de cajas de colores planos.
class_name CasaUtileria
extends RefCounted

const MADERA := "madera_domestica"
const TEJIDO := "tejido_domestico"
const ACERO := "acero_cocina"


static func montar(raiz: Node3D) -> void:
	montar_zonas_domesticas(raiz)
	# Mesita de noche junto al cabecero, con la portátil encima; la consola de
	# sobremesa va sobre el mueble de la tele y la lámpara de pie, tras el sofá.
	_montar_mesita(raiz, Vector3(-1.1, 0.0, -3.05))
	_montar_portatil(raiz, Vector3(-1.1, 0.68, -3.05))
	_montar_consola_sobremesa(raiz, Vector3(-3.6, 0.54, 1.95))
	_montar_lampara_pie(raiz, Vector3(-1.0, 0.0, 2.85))
	_montar_almacenamiento(raiz, Vector3(0.0, 0.0, -3.05))
	_montar_televisor_interactivo(raiz)
	CasaHogarCC0.montar(raiz)


## Vertical espacial de #133/#282. Se mantiene separado de las interacciones para
## poder probar que la casa se lee por zonas aunque consola, compras o gato no
## estén activos. Cama y cuenco toman sus anclas del catálogo: no duplican la
## posición de la salida a sueño ni el punto al que camina el gato.
static func montar_zonas_domesticas(raiz: Node3D) -> void:
	_montar_cama(raiz, _ancla_salida("sueño", Vector3(-2.4, 0.0, -2.0)))
	_montar_cuenco_gato(raiz, _ancla_cuenco(Vector3(2.8, 0.0, 1.5)))
	_montar_sofa(raiz, Vector3(-0.95, 0.0, 1.4), 90.0)
	_montar_cocina(raiz, Vector3(3.30, 0.0, -0.15))
	_montar_ventana(raiz, Vector3(-2.10, 1.65, -3.42))
	_montar_estanteria_compras(raiz, Vector3(1.25, 0.0, -3.22))


static func _ancla_salida(destino: String, fallback: Vector3) -> Vector3:
	for salida in EspaciosCatalogo.CASA.get("salidas", []):
		if String(salida.get("destino", "")) != destino:
			continue
		var pos: Vector3 = salida.get("pos", fallback)
		return Vector3(pos.x, 0.0, pos.z)
	return fallback


static func _ancla_cuenco(fallback: Vector3) -> Vector3:
	var sitios: Array = EspaciosCatalogo.CASA.get("sitios_gato", [])
	if sitios.is_empty():
		return fallback
	var pos: Vector3 = sitios[0]
	return Vector3(pos.x, 0.0, pos.z)


static func _montar_cama(raiz: Node3D, pos: Vector3) -> void:
	var cama := Node3D.new()
	cama.name = "CamaCasa"
	cama.position = pos
	raiz.add_child(cama)

	# El prisma histórico queda integrado como colchón/volumen de salida. Marco,
	# cabecero, patas, almohada y manta le dan una silueta de cama desde frente,
	# lateral y 3/4 sin tocar el trigger que inicia el sueño.
	var madera := Color(0.30, 0.21, 0.16)
	var tela := Color(0.55, 0.46, 0.40)
	var tela_clara := Color(0.70, 0.64, 0.56)
	_agregar_caja(cama, Vector3(0, 0.20, 0), Vector3(1.56, 0.20, 2.34), madera, MADERA)
	_agregar_caja(cama, Vector3(0, 0.72, -1.14), Vector3(1.58, 1.18, 0.12), madera, MADERA)
	_agregar_caja(cama, Vector3(0, 0.36, 1.14), Vector3(1.58, 0.48, 0.10), madera, MADERA)
	_agregar_caja(cama, Vector3(0, 0.61, -0.67), Vector3(0.92, 0.16, 0.42), tela_clara, TEJIDO)
	_agregar_caja(cama, Vector3(0, 0.60, 0.34), Vector3(1.30, 0.08, 1.06), tela, TEJIDO)
	for x in [-0.66, 0.66]:
		for z in [-0.96, 0.96]:
			_agregar_caja(
				cama,
				Vector3(x, 0.09, z),
				Vector3(0.10, 0.18, 0.10),
				Color(0.24, 0.17, 0.13),
				MADERA
			)


static func _montar_cuenco_gato(raiz: Node3D, pos: Vector3) -> void:
	var cuenco := Node3D.new()
	cuenco.name = "CuencoGato3D"
	cuenco.position = pos
	raiz.add_child(cuenco)

	# Un tronco de cono bajo con centro oscuro hace legible el recipiente abierto
	# sin añadir estado propio: lleno/vacío sigue perteneciendo a la lógica del gato.
	_agregar_cilindro_truncado(
		cuenco, Vector3(0, 0.07, 0), 0.18, 0.11, 0.11, Color(0.48, 0.46, 0.42), ACERO
	)
	_agregar_cilindro(cuenco, Vector3(0, 0.132, 0), 0.13, 0.012, Color(0.10, 0.09, 0.08))


static func _montar_sofa(raiz: Node3D, pos: Vector3, giro_y: float) -> void:
	var sofa := Node3D.new()
	sofa.name = "SofaCasa"
	sofa.position = pos
	sofa.rotation_degrees.y = giro_y
	raiz.add_child(sofa)

	var tela := Color(0.31, 0.25, 0.23)
	var tela_oscura := Color(0.24, 0.19, 0.18)
	_agregar_caja(sofa, Vector3(0, 0.34, 0), Vector3(1.80, 0.34, 0.72), tela, TEJIDO)
	_agregar_caja(sofa, Vector3(0, 0.78, 0.30), Vector3(1.80, 0.88, 0.18), tela_oscura, TEJIDO)
	_agregar_caja(sofa, Vector3(-0.87, 0.52, 0), Vector3(0.16, 0.52, 0.72), tela_oscura, TEJIDO)
	_agregar_caja(sofa, Vector3(0.87, 0.52, 0), Vector3(0.16, 0.52, 0.72), tela_oscura, TEJIDO)


static func _montar_cocina(raiz: Node3D, pos: Vector3) -> void:
	var cocina := Node3D.new()
	cocina.name = "CocinaCasa"
	cocina.position = pos
	raiz.add_child(cocina)

	var mueble := Color(0.38, 0.31, 0.25)
	var encimera := Color(0.24, 0.23, 0.22)
	var metal := Color(0.44, 0.46, 0.45)
	_agregar_caja(cocina, Vector3(0, 0.45, 0), Vector3(0.56, 0.90, 1.80), mueble, MADERA)
	_agregar_caja(cocina, Vector3(-0.02, 0.93, 0), Vector3(0.64, 0.08, 1.92), encimera, MADERA)

	var fregadero := Node3D.new()
	fregadero.name = "FregaderoCasa"
	fregadero.position = Vector3(-0.03, 0.99, 0.30)
	cocina.add_child(fregadero)
	_agregar_caja(fregadero, Vector3.ZERO, Vector3(0.44, 0.035, 0.58), metal, ACERO)
	_agregar_cilindro(fregadero, Vector3(0.12, 0.20, 0.12), 0.025, 0.36, metal, ACERO)
	_agregar_caja(fregadero, Vector3(0.08, 0.36, 0.12), Vector3(0.22, 0.04, 0.04), metal, ACERO)

	var nevera := Node3D.new()
	nevera.name = "NeveraCasa"
	nevera.position = Vector3(0, 0, -1.48)
	cocina.add_child(nevera)
	_agregar_caja(
		nevera, Vector3(0, 0.91, 0), Vector3(0.72, 1.82, 0.72), Color(0.55, 0.54, 0.50), ACERO
	)
	_agregar_caja(nevera, Vector3(-0.37, 1.16, -0.23), Vector3(0.035, 0.52, 0.07), metal, ACERO)
	_agregar_caja(nevera, Vector3(-0.37, 0.55, -0.23), Vector3(0.035, 0.34, 0.07), metal, ACERO)


## La pared de la casa sigue siendo maciza; por eso la vista funciona como un
## pequeño diorama embebido delante del muro. Las capas están separadas unos
## centímetros en Z: cielo -> edificios -> luces -> reflejos -> marco. Desde el
## dormitorio se lee profundidad y exterior sin abrir geometría ni introducir
## una textura externa/LFS solo para este primer corte de #566.
static func _montar_ventana(raiz: Node3D, pos: Vector3) -> void:
	var ventana := Node3D.new()
	ventana.name = "VentanaCasa"
	ventana.position = pos
	raiz.add_child(ventana)

	var vista := Node3D.new()
	vista.name = "VistaExteriorCasa"
	ventana.add_child(vista)

	# Fondo frío de noche. Está por delante del muro físico y por detrás del
	# resto de capas, así nunca vuelve a verse el gotelé a través del hueco.
	var cielo := Node3D.new()
	cielo.name = "CieloExteriorCasa"
	vista.add_child(cielo)
	_agregar_caja(
		cielo, Vector3(0, 0, -0.045), Vector3(1.80, 1.10, 0.016), Color(0.12, 0.18, 0.30)
	)

	# Skyline deliberadamente asimétrico: varias alturas hacen que la ventana
	# parezca mirar a una manzana real y no a otra placa de color.
	var edificios := Node3D.new()
	edificios.name = "PerfilUrbanoCasa"
	vista.add_child(edificios)
	_agregar_caja(
		edificios, Vector3(-0.62, -0.18, -0.027), Vector3(0.54, 0.72, 0.018), Color(0.08, 0.08, 0.11)
	)
	_agregar_caja(
		edificios, Vector3(-0.16, -0.27, -0.026), Vector3(0.34, 0.54, 0.020), Color(0.10, 0.09, 0.12)
	)
	_agregar_caja(
		edificios, Vector3(0.25, -0.10, -0.025), Vector3(0.44, 0.88, 0.022), Color(0.07, 0.08, 0.10)
	)
	_agregar_caja(
		edificios, Vector3(0.69, -0.23, -0.024), Vector3(0.36, 0.62, 0.024), Color(0.11, 0.10, 0.12)
	)

	# Ventanas lejanas: pocos puntos cálidos, irregulares y sin texto. Son lo
	# bastante pequeños para que el dithering/temblor PSX los integre en la vista.
	var luces := Node3D.new()
	luces.name = "LucesExteriorCasa"
	vista.add_child(luces)
	var luz := Color(0.90, 0.62, 0.30)
	_agregar_caja(luces, Vector3(-0.72, -0.06, -0.012), Vector3(0.10, 0.09, 0.010), luz)
	_agregar_caja(luces, Vector3(-0.51, -0.29, -0.011), Vector3(0.09, 0.08, 0.010), luz)
	_agregar_caja(luces, Vector3(-0.16, -0.20, -0.010), Vector3(0.08, 0.08, 0.010), luz)
	_agregar_caja(luces, Vector3(0.18, 0.06, -0.009), Vector3(0.09, 0.09, 0.010), luz)
	_agregar_caja(luces, Vector3(0.34, -0.26, -0.008), Vector3(0.08, 0.08, 0.010), luz)
	_agregar_caja(luces, Vector3(0.70, -0.12, -0.007), Vector3(0.09, 0.08, 0.010), luz)

	# Dos reflejos finos sugieren cristal sin volver a tapar el exterior. La
	# transparencia real exigiría un segundo shader; aquí se conserva el shader
	# PSX común y se deja casi todo el paño visualmente abierto.
	var reflejos := Node3D.new()
	reflejos.name = "ReflejosCristalCasa"
	vista.add_child(reflejos)
	_agregar_caja(
		reflejos, Vector3(-0.45, 0.34, 0.004), Vector3(0.48, 0.025, 0.008), Color(0.38, 0.48, 0.58)
	)
	_agregar_caja(
		reflejos, Vector3(0.52, 0.19, 0.005), Vector3(0.30, 0.018, 0.008), Color(0.31, 0.40, 0.50)
	)

	var marco := Color(0.31, 0.27, 0.23)
	_agregar_caja(ventana, Vector3(0, 0.58, 0.018), Vector3(1.94, 0.10, 0.08), marco, MADERA)
	_agregar_caja(ventana, Vector3(0, -0.58, 0.018), Vector3(1.94, 0.10, 0.08), marco, MADERA)
	_agregar_caja(ventana, Vector3(-0.92, 0, 0.018), Vector3(0.10, 1.18, 0.08), marco, MADERA)
	_agregar_caja(ventana, Vector3(0.92, 0, 0.018), Vector3(0.10, 1.18, 0.08), marco, MADERA)
	_agregar_caja(ventana, Vector3(0, 0, 0.020), Vector3(0.07, 1.08, 0.075), marco, MADERA)


static func _montar_estanteria_compras(raiz: Node3D, pos: Vector3) -> void:
	var estanteria := Node3D.new()
	estanteria.name = "EstanteriaComprasCasa"
	estanteria.position = pos
	raiz.add_child(estanteria)

	var madera := Color(0.32, 0.23, 0.17)
	_agregar_caja(estanteria, Vector3(-0.48, 0.82, 0), Vector3(0.10, 1.64, 0.34), madera, MADERA)
	_agregar_caja(estanteria, Vector3(0.48, 0.82, 0), Vector3(0.10, 1.64, 0.34), madera, MADERA)
	for y in [0.08, 0.58, 1.08, 1.58]:
		_agregar_caja(estanteria, Vector3(0, y, 0), Vector3(1.02, 0.09, 0.36), madera, MADERA)


static func _montar_mesita(raiz: Node3D, pos: Vector3) -> void:
	var mesa := Node3D.new()
	mesa.name = "MesitaCasa"
	mesa.position = pos
	raiz.add_child(mesa)

	_agregar_caja(
		mesa, Vector3(0, 0.55, 0), Vector3(0.82, 0.12, 0.62), Color(0.32, 0.23, 0.17), MADERA
	)
	for x in [-0.31, 0.31]:
		for z in [-0.21, 0.21]:
			_agregar_caja(
				mesa,
				Vector3(x, 0.28, z),
				Vector3(0.10, 0.56, 0.10),
				Color(0.27, 0.19, 0.14),
				MADERA
			)


static func _montar_portatil(raiz: Node3D, pos: Vector3) -> void:
	var portatil := ConsolaPortatil98.new()
	portatil.name = "ConsolaPortatil98"
	portatil.position = pos
	portatil.rotation_degrees = Vector3(-12.0, 18.0, 0.0)
	raiz.add_child(portatil)
	portatil.configurar()


static func _montar_consola_sobremesa(raiz: Node3D, pos: Vector3) -> void:
	var consola := ConsolaSobremesa98.new()
	consola.name = "ConsolaSobremesa98"
	consola.position = pos
	consola.rotation_degrees.y = 180.0
	raiz.add_child(consola)
	consola.configurar()


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

	_agregar_cilindro(lampara, Vector3(0, 0.05, 0), 0.28, 0.10, Color(0.18, 0.17, 0.16), ACERO)
	_agregar_cilindro(lampara, Vector3(0, 0.82, 0), 0.045, 1.55, Color(0.26, 0.24, 0.22), ACERO)
	_agregar_pantalla(lampara, Vector3(0, 1.62, 0))


static func _agregar_pantalla(raiz: Node3D, pos: Vector3) -> void:
	var malla := MeshInstance3D.new()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.22
	cono.bottom_radius = 0.38
	cono.height = 0.46
	malla.mesh = cono
	malla.position = pos
	_aplicar_materia(malla, Color(0.72, 0.61, 0.43), TEJIDO)
	raiz.add_child(malla)


static func _agregar_caja(
	raiz: Node3D, pos: Vector3, tam: Vector3, color: Color, textura: String = ""
) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	_aplicar_materia(malla, color, textura)
	raiz.add_child(malla)


static func _agregar_cilindro(
	raiz: Node3D, pos: Vector3, radio: float, alto: float, color: Color, textura: String = ""
) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	_aplicar_materia(malla, color, textura)
	raiz.add_child(malla)


static func _agregar_cilindro_truncado(
	raiz: Node3D,
	pos: Vector3,
	radio_superior: float,
	radio_inferior: float,
	alto: float,
	color: Color,
	textura: String = ""
) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio_superior
	cilindro.bottom_radius = radio_inferior
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	_aplicar_materia(malla, color, textura)
	raiz.add_child(malla)


## Reutiliza exactamente el material PSX que #399 ya aplica a modelos 3D.
## Aquí no hay segunda biblioteca ni StandardMaterial3D paralelo: la diferencia
## entre oficina y casa la da el perfil de TexturaProcedural.
static func _aplicar_materia(malla: MeshInstance3D, color: Color, textura: String = "") -> void:
	Modelos._pintar(malla, color, textura)