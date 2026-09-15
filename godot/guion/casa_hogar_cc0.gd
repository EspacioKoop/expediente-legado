## Mobiliario CC0 de «Low poly household goods» (samusaa / mastjie, #227).
##
## La casa se ordena por zonas que se leen desde la puerta:
## - dormitorio al fondo izquierda: cama bajo la ventana, mesita y armario;
## - estar delante a la izquierda: mueble de TV, mesa baja y sofá mirando a la tele;
## - cocina-comedor a la derecha: encimera y nevera, horno, lavadora, mesa con sillas;
## - entrada: aparador con lámpara junto a la puerta.
## CasaUtileria sigue siendo dueña de las piezas interactivas; aquí solo entra
## mobiliario estático y el visual CC0 del sofá.
class_name CasaHogarCC0
extends RefCounted

const CARPETA := "household_goods/"
const SOFA := "2_seat_sofa_01"
const TAM_SOFA := Vector3(1.9, 0.86, 0.87)

# nombre, modelo, base en el suelo o superficie, caja de encaje (ejes del
# modelo), giro Y (0 = frente hacia +Z), con colisión.
const PIEZAS := [
	# Estar
	[
		"MuebleTVHogar",
		"tv_cabinet_01",
		Vector3(-3.60, 0.0, 1.45),
		Vector3(1.5, 0.52, 0.5),
		90.0,
		true
	],
	[
		"MesaBajaHogar",
		"coffee_table_01",
		Vector3(-2.25, 0.0, 1.40),
		Vector3(1.1, 0.3, 0.55),
		90.0,
		true
	],
	# Dormitorio
	[
		"ArmarioHogar",
		"wardrobe_01",
		Vector3(-3.66, 0.0, 0.10),
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
	["HornoHogar", "stove_01", Vector3(3.33, 0.0, 2.25), Vector3(0.92, 1.01, 0.66), -90.0, true],
	[
		"LavadoraHogar",
		"washing_machine_01",
		Vector3(3.40, 0.0, -2.45),
		Vector3(0.69, 0.87, 0.77),
		-90.0,
		true
	],
	[
		"MicroondasHogar",
		"microwave_01",
		Vector3(3.42, 0.97, -0.75),
		Vector3(0.48, 0.28, 0.27),
		-90.0,
		false
	],
	[
		"TostadoraHogar",
		"toaster_01",
		Vector3(3.40, 0.97, -0.30),
		Vector3(0.15, 0.19, 0.32),
		-90.0,
		false
	],
	[
		"HervidorHogar",
		"kettle_01",
		Vector3(3.38, 0.97, 0.62),
		Vector3(0.28, 0.32, 0.21),
		-90.0,
		false
	],
	# Entrada
	[
		"AparadorHogar",
		"cupboard_01",
		Vector3(1.40, 0.0, 3.22),
		Vector3(0.9, 0.93, 0.45),
		180.0,
		true
	],
	[
		"LamparaMesaHogar",
		"table_lamp_01",
		Vector3(1.62, 0.93, 3.22),
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
		return existente
	var lote := Node3D.new()
	lote.name = "CasaHogarCC0"
	raiz.add_child(lote)
	for ficha in PIEZAS:
		_crear_pieza(lote, ficha)
	vestir_sofa(raiz.get_node_or_null("SofaCasa") as Node3D)
	return lote


## El sofá conserva nodo, posición y giro de CasaUtileria; solo cambia lo que
## se ve. Si el GLB faltara, la versión procedural sigue visible.
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
