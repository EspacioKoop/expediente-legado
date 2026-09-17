## Mobiliario CC0 de «Low poly household goods» (samusaa / mastjie, #227).
##
## La casa se ordena por zonas que se leen desde la puerta:
## - dormitorio cerrado al fondo izquierda: cama bajo la ventana, mesita y armario;
## - estar delante a la izquierda: mueble de TV, mesa baja y sofá mirando a la tele;
## - cocina-comedor abierta a la derecha: encimera y nevera, horno, lavadora, mesa con sillas;
## - entrada: aparador con lámpara junto a la puerta.
## CasaUtileria sigue siendo dueña de las piezas interactivas; aquí entra
## mobiliario estático, el visual CC0 del sofá y los tabiques domésticos de #133.
class_name CasaHogarCC0
extends RefCounted

const CARPETA := "household_goods/"
const SOFA := "2_seat_sofa_01"
const ARMARIO := "wardrobe_01"
const ARMARIO_OBJETO_ONIRICO := "armario_hogar"
const TAM_SOFA := Vector3(1.9, 0.86, 0.87)
const ALTO_TABIQUE := 2.8
const GROSOR_TABIQUE := 0.18
const NOMBRE_HABITACIONES := "HabitacionesCasa"
const NOMBRE_TRANSICIONES := "TransicionesCasa"

# El dormitorio ocupa el fondo izquierdo. La puerta queda centrada en el paso
# histórico hacia la cama, de modo que la nueva arquitectura no invalida el
# recorrido ni mueve el trigger de sueño. El lateral separa el dormitorio de la
# cocina-comedor; el resto permanece abierto como un piso pequeño de 1998.
const TABIQUES := [
	[
		"TabiqueDormitorioFrente",
		Vector3(-2.275, ALTO_TABIQUE / 2.0, -0.65),
		Vector3(3.45, ALTO_TABIQUE, GROSOR_TABIQUE)
	],
	[
		"TabiqueDormitorioLateral",
		Vector3(0.55, ALTO_TABIQUE / 2.0, -2.075),
		Vector3(GROSOR_TABIQUE, ALTO_TABIQUE, 2.85)
	],
	["DintelDormitorio", Vector3(0.0, 2.40, -0.65), Vector3(1.10, 0.80, GROSOR_TABIQUE)],
]

# Acabados de lectura, no colisiones nuevas. El marco hace que el hueco del
# dormitorio se entienda como puerta y no como pared incompleta. El umbral no
# estrecha el paso histórico de 1,10 m. Todos quedan unos centímetros por delante
# del tabique para evitar z-fighting con el gotelé.
const MARCO_PUERTA_DORMITORIO := [
	["JambaDormitorioIzquierda", Vector3(-0.60, 1.10, -0.55), Vector3(0.10, 2.20, 0.08)],
	["JambaDormitorioDerecha", Vector3(0.60, 1.10, -0.55), Vector3(0.10, 2.20, 0.08)],
	["MarcoSuperiorDormitorio", Vector3(0.0, 2.25, -0.55), Vector3(1.30, 0.10, 0.08)],
	["UmbralDormitorio", Vector3(0.0, 0.015, -0.55), Vector3(1.10, 0.03, 0.18)],
]
const ALFOMBRA_SALON_POS := Vector3(-2.10, 0.015, 1.35)
const ALFOMBRA_SALON_TAM := Vector3(2.85, 0.03, 1.95)

# nombre, modelo, base en el suelo o superficie, caja de encaje (ejes del
# modelo), giro Y (0 = frente hacia +Z), con colisión.
const PIEZAS := [
	# Estar: tele, mesa baja y sofá comparten eje visual para que el rincón se
	# lea como salón y no como tres props repartidos.
	[
		"MuebleTVHogar",
		"tv_cabinet_01",
		Vector3(-3.60, 0.0, 1.35),
		Vector3(1.5, 0.52, 0.5),
		90.0,
		true
	],
	[
		"MesaBajaHogar",
		"coffee_table_01",
		Vector3(-2.25, 0.0, 1.35),
		Vector3(1.1, 0.3, 0.55),
		90.0,
		true
	],
	# Dormitorio: el armario deja de flotar en el salón y queda contra el muro
	# izquierdo, sin invadir la cama ni la puerta nueva.
	[
		"ArmarioHogar",
		ARMARIO,
		Vector3(-3.55, 0.0, -2.45),
		Vector3(0.99, 1.93, 0.63),
		90.0,
		true
	],
	# Comedor
	[
		"MesaComedorHogar",
		"dine_table_01",
		Vector3(1.70, 0.0, -0.70),
		Vector3(1.84, 0.76, 0.91),
		90.0,
		true
	],
	[
		"SillaComedorOeste",
		"chair_01",
		Vector3(0.95, 0.0, -1.15),
		Vector3(0.45, 0.94, 0.53),
		90.0,
		true
	],
	[
		"SillaComedorOesteB",
		"chair_01",
		Vector3(0.95, 0.0, -0.25),
		Vector3(0.45, 0.94, 0.53),
		90.0,
		true
	],
	[
		"SillaComedorEste",
		"chair_01",
		Vector3(2.50, 0.0, -0.70),
		Vector3(0.45, 0.94, 0.53),
		-90.0,
		true
	],
	# Cocina
	["HornoHogar", "stove_01", Vector3(4.83, 0.0, 2.25), Vector3(0.92, 1.01, 0.66), -90.0, true],
	[
		"LavadoraHogar",
		"washing_machine_01",
		Vector3(4.90, 0.0, -2.45),
		Vector3(0.69, 0.87, 0.77),
		-90.0,
		true
	],
	[
		"MicroondasHogar",
		"microwave_01",
		Vector3(4.92, 0.97, -0.75),
		Vector3(0.48, 0.28, 0.27),
		-90.0,
		false
	],
	[
		"TostadoraHogar",
		"toaster_01",
		Vector3(4.90, 0.97, -0.30),
		Vector3(0.15, 0.19, 0.32),
		-90.0,
		false
	],
	[
		"HervidorHogar",
		"kettle_01",
		Vector3(4.88, 0.97, 0.62),
		Vector3(0.28, 0.32, 0.21),
		-90.0,
		false
	],
	# Entrada
	[
		"AparadorHogar",
		"cupboard_01",
		Vector3(1.40, 0.0, 4.22),
		Vector3(0.9, 0.93, 0.45),
		180.0,
		true
	],
	[
		"LamparaMesaHogar",
		"table_lamp_01",
		Vector3(1.62, 0.93, 4.22),
		Vector3(0.3, 0.55, 0.3),
		180.0,
		false
	],
]


static func montar(raiz: Node3D) -> Node3D:
	if raiz == null:
		return null
	var existente := raiz.get_node_or_null("CasaHogarCC0") as Node3D
	if existente != null:
		_montar_habitaciones(raiz)
		_montar_transiciones_domesticas(raiz)
		_ordenar_rincon_television(raiz)
		return existente
	var lote := Node3D.new()
	lote.name = "CasaHogarCC0"
	raiz.add_child(lote)
	for ficha in PIEZAS:
		_crear_pieza(lote, ficha)
	vestir_sofa(raiz.get_node_or_null("SofaCasa") as Node3D)
	_montar_habitaciones(raiz)
	_montar_transiciones_domesticas(raiz)
	_ordenar_rincon_television(raiz)
	return lote


## El sofá conserva nodo y orientación de CasaUtileria; solo cambia lo que se
## ve. Si el GLB faltara, la versión procedural sigue visible.
static func vestir_sofa(sofa: Node3D) -> void:
	if sofa == null or sofa.has_node("VisualHogar"):
		return
	var anteriores := Modelos._mallas(sofa)
	var visual := Node3D.new()
	visual.name = "VisualHogar"
	visual.position.y = TAM_SOFA.y / 2.0
	# El procedural mira a -Z local; el modelo, a +Z.
	visual.rotation_degrees.y = 180.0
	sofa.add_child(visual)
	if not AssetCc0.sustituir(visual, CARPETA + SOFA, TAM_SOFA):
		visual.queue_free()
		return
	for malla in anteriores:
		malla.layers = 0


## #133: materializa habitaciones de verdad, no solo agrupaciones de muebles.
## Los tabiques son StaticBody3D para que la puerta importe al recorrer la casa.
static func _montar_habitaciones(raiz: Node3D) -> Node3D:
	var existente := raiz.get_node_or_null(NOMBRE_HABITACIONES) as Node3D
	if existente != null:
		return existente
	var habitaciones := Node3D.new()
	habitaciones.name = NOMBRE_HABITACIONES
	raiz.add_child(habitaciones)
	for ficha in TABIQUES:
		_crear_tabique(habitaciones, ficha)
	return habitaciones


static func _crear_tabique(habitaciones: Node3D, ficha: Array) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = ficha[0]
	cuerpo.position = ficha[1]
	habitaciones.add_child(cuerpo)

	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = ficha[2]
	malla.mesh = caja
	var color: Color = EspaciosCatalogo.CASA.get("color_muro", Color(0.52, 0.47, 0.42))
	var material := ShaderMaterial.new()
	material.shader = load("res://arte/psx.gdshader")
	material.set_shader_parameter("color_base", color)
	var textura := TexturaProcedural.por_nombre("gotele", color, hash(String(ficha[0])))
	if textura != null:
		material.set_shader_parameter("textura", textura)
		material.set_shader_parameter("con_textura", true)
		material.set_shader_parameter("escala_textura", 1.0 / 1.2)
	malla.material_override = material
	cuerpo.add_child(malla)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = ficha[2]
	colision.shape = forma
	cuerpo.add_child(colision)
	return cuerpo


## Acabados visuales para que la planta se entienda sin HUD. Deliberadamente no
## tienen colisión: el marco no roba centímetros al paso y la alfombra no crea
## escalón. Son agrupadores espaciales, no nuevos objetos interactivos.
static func _montar_transiciones_domesticas(raiz: Node3D) -> Node3D:
	var existente := raiz.get_node_or_null(NOMBRE_TRANSICIONES) as Node3D
	if existente != null:
		return existente
	var transiciones := Node3D.new()
	transiciones.name = NOMBRE_TRANSICIONES
	raiz.add_child(transiciones)
	for ficha in MARCO_PUERTA_DORMITORIO:
		_crear_acabado(
			transiciones,
			String(ficha[0]),
			ficha[1],
			ficha[2],
			Color(0.29, 0.21, 0.16),
			"madera_domestica"
		)
	_crear_acabado(
		transiciones,
		"AlfombraSalon",
		ALFOMBRA_SALON_POS,
		ALFOMBRA_SALON_TAM,
		Color(0.27, 0.20, 0.18),
		"tejido_domestico"
	)
	return transiciones


static func _crear_acabado(
	raiz: Node3D, nombre: String, pos: Vector3, tam: Vector3, color: Color, textura: String
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	Modelos._pintar(malla, color, textura)
	raiz.add_child(malla)
	return malla


## Tele, mesa baja y sofá quedan centrados en el mismo eje. La consola se gira
## hacia el interior de la estancia y se desplaza al extremo libre del mueble,
## de modo que pueda enfocarse sin que la propia tele la tape (#133/#95).
static func _ordenar_rincon_television(raiz: Node3D) -> void:
	var sofa := raiz.get_node_or_null("SofaCasa") as Node3D
	if sofa != null:
		sofa.position.z = 1.35
	var consola := raiz.get_node_or_null("ConsolaSobremesa98") as Node3D
	if consola != null:
		consola.position = Vector3(-3.58, 0.54, 1.82)
		consola.rotation_degrees.y = -90.0


static func _crear_pieza(lote: Node3D, ficha: Array) -> Node3D:
	var tam: Vector3 = ficha[3]
	var cuerpo: Node3D = StaticBody3D.new() if ficha[5] else Node3D.new()
	cuerpo.name = ficha[0]
	cuerpo.position = ficha[2] + Vector3(0.0, tam.y / 2.0, 0.0)
	cuerpo.rotation_degrees.y = ficha[4]
	# Modelos._encajar mide con transformaciones globales: la pieza debe estar
	# ya en el árbol antes de sustituir su visual.
	lote.add_child(cuerpo)
	if not AssetCc0.sustituir(cuerpo, CARPETA + ficha[1], tam):
		cuerpo.queue_free()
		return null
	if String(ficha[1]) == ARMARIO:
		_montar_examinable_onirico(cuerpo, tam, "armario")
	if ficha[5]:
		# Caja simple a la medida real del modelo encajado, sin colisión por triángulo.
		var modelo := cuerpo.get_node("AssetCc0") as Node3D
		var caja := Modelos._limites(modelo)
		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = caja.size * modelo.scale
		colision.shape = forma
		colision.position = modelo.position + caja.get_center() * modelo.scale
		cuerpo.add_child(colision)
	return cuerpo


## #227/#87: una pieza del pack deja de ser solo dressing. Examinar el armario
## conserva un ID canónico del original visto durante esta jornada; el sueño
## decide después si lo deforma. No hay inventario, pickup ni estado paralelo.
static func _montar_examinable_onirico(cuerpo: Node3D, tam: Vector3, nombre_objeto: String) -> void:
	if cuerpo.has_node("ExaminarArmarioHogar"):
		return
	var examinable := Interactuable3D.new()
	examinable.name = "ExaminarArmarioHogar"
	examinable.verbo = Interactuable3D.Verbo.EXAMINAR
	examinable.nombre_objeto = nombre_objeto
	examinable.set_meta("objeto_onirico_id", ARMARIO_OBJETO_ONIRICO)
	cuerpo.add_child(examinable)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam + Vector3(0.12, 0.12, 0.12)
	colision.shape = forma
	examinable.add_child(colision)
	examinable.activado.connect(_registrar_armario_onirico.bind(examinable))


static func _registrar_armario_onirico(_actor: Node, examinable: Interactuable3D) -> void:
	var nodo: Node = examinable
	while nodo != null:
		for propiedad in nodo.get_property_list():
			if String(propiedad.get("name", "")) != "jornada":
				continue
			var valor: Variant = nodo.get("jornada")
			if typeof(valor) != TYPE_DICTIONARY:
				return
			var jornada: Dictionary = valor
			if ObjetosOniricos.registrar(jornada, ARMARIO_OBJETO_ONIRICO):
				if nodo.has_method("_guardar_o_avisar"):
					nodo.call("_guardar_o_avisar", "")
			return
		nodo = nodo.get_parent()
