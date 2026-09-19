## Interiores físicos de los dos comercios ancla del trayecto (#676).
##
## Electrodomésticos y Bit 98 siguen perteneciendo a `trayecto`: entrar en un
## local no crea una fase de Jornada ni otra economía. Los interiores se montan
## lejos de la planta de la calle y las puertas usan la interacción 3D común
## para mover al mismo Caminante. Así el primer corte es aislado y reversible
## sin reabrir la geometría base del recorrido.
class_name CalleLocalesComerciales3D
extends Node3D

const NOMBRE := "LocalesComerciales"
const POS_ELECTRODOMESTICOS := Vector3(-48.0, 0.0, -2.0)
const POS_BIT98 := Vector3(48.0, 0.0, -6.0)
const ENTRADA_INTERIOR := Vector3(0.0, 0.0, 2.65)
const REGRESO_ELECTRODOMESTICOS := Vector3(-4.75, 0.0, 2.45)
const REGRESO_BIT98 := Vector3(4.75, 0.0, -5.15)

const COLOR_PARED_ELECTRO := Color(0.52, 0.50, 0.47)
const COLOR_SUELO_ELECTRO := Color(0.32, 0.31, 0.30)
const COLOR_PARED_BIT98 := Color(0.10, 0.10, 0.13)
const COLOR_SUELO_BIT98 := Color(0.16, 0.15, 0.18)
const COLOR_METAL := Color(0.20, 0.21, 0.22)
const COLOR_MADERA := Color(0.34, 0.25, 0.18)

var _dia: Node
var _interior_electrodomesticos: Node3D
var _interior_bit98: Node3D


static func montar(dia: Node, calle: Node3D) -> CalleLocalesComerciales3D:
	if dia == null or calle == null:
		return null
	var existente := calle.get_node_or_null(NOMBRE) as CalleLocalesComerciales3D
	if existente != null:
		return existente
	var locales := CalleLocalesComerciales3D.new()
	locales.name = NOMBRE
	calle.add_child(locales)
	locales._configurar(dia, calle)
	return locales


func _configurar(dia: Node, calle: Node3D) -> void:
	_dia = dia
	_interior_electrodomesticos = _montar_electrodomesticos()
	_interior_bit98 = _montar_bit98()
	_interior_electrodomesticos.visible = false
	_interior_bit98.visible = false

	var puerta_electro := (
		calle.find_child("EntrarElectrodomesticos", true, false) as Interactuable3D
	)
	if puerta_electro != null:
		puerta_electro.activado.connect(_entrar_electrodomesticos)

	var puerta_bit98 := calle.find_child("EntrarTiendaVideojuegos", true, false) as Interactuable3D
	if puerta_bit98 != null:
		puerta_bit98.activado.connect(_entrar_bit98)


func _montar_electrodomesticos() -> Node3D:
	var interior := Node3D.new()
	interior.name = "InteriorElectrodomesticos"
	interior.position = POS_ELECTRODOMESTICOS
	add_child(interior)
	(
		Espacio3D
		. construir(
			interior,
			{
				"suelo": Vector2(7.0, 8.0),
				"color_suelo": COLOR_SUELO_ELECTRO,
				"color_muro": COLOR_PARED_ELECTRO,
				"color_techo": Color(0.68, 0.67, 0.63),
				"textura_suelo": "linoleo",
				"textura_muro": "gotele",
				"textura_techo": "techo",
				"bultos": [],
				"luces":
				[
					{
						"pos": Vector3(-1.8, 2.65, -1.2),
						"color": Color(0.90, 0.92, 0.88),
						"energia": 1.9,
						"alcance": 7.0,
					},
					{
						"pos": Vector3(1.8, 2.65, 1.0),
						"color": Color(0.90, 0.92, 0.88),
						"energia": 1.9,
						"alcance": 7.0,
					},
				],
				"salidas": [],
			},
		)
	)

	_caja_fisica(
		interior,
		"MostradorElectro",
		Vector3(-2.45, 0.52, -2.55),
		Vector3(1.15, 1.04, 2.3),
		COLOR_MADERA,
		"madera_domestica",
	)
	for i in 4:
		var z := -2.55 + float(i) * 1.55
		_montar_televisor_interior(interior, i, Vector3(2.35, 0.48, z))
	for i in 2:
		_montar_frigorifico(interior, i, Vector3(-2.55, 0.0, -0.55 + i * 1.55))
		_montar_lavadora(interior, i, Vector3(0.35, 0.0, -1.1 + i * 1.85))

	var salida := _interactuable(
		interior,
		"SalirElectrodomesticos",
		Vector3(0.0, 1.1, 3.25),
		Vector3(1.5, 2.2, 1.0),
		Interactuable3D.Verbo.ABRIR,
		_tr("CALLE_PUERTA_SALIDA"),
	)
	salida.activado.connect(_salir_electrodomesticos)
	return interior


func _montar_bit98() -> Node3D:
	var interior := Node3D.new()
	interior.name = "InteriorBit98"
	interior.position = POS_BIT98
	add_child(interior)
	(
		Espacio3D
		. construir(
			interior,
			{
				"suelo": Vector2(6.4, 8.0),
				"color_suelo": COLOR_SUELO_BIT98,
				"color_muro": COLOR_PARED_BIT98,
				"color_techo": Color(0.24, 0.22, 0.27),
				"textura_suelo": "moqueta",
				"textura_muro": "gotele",
				"textura_techo": "techo",
				"bultos": [],
				"luces":
				[
					{
						"pos": Vector3(0.0, 2.55, -0.8),
						"color": Color(0.78, 0.62, 0.94),
						"energia": 1.8,
						"alcance": 7.0,
					},
					{
						"pos": Vector3(0.0, 2.35, 2.0),
						"color": Color(0.32, 0.78, 0.94),
						"energia": 1.2,
						"alcance": 6.0,
					},
				],
				"salidas": [],
			},
		)
	)

	_caja_fisica(
		interior,
		"MostradorBit98",
		Vector3(0.0, 0.55, -2.65),
		Vector3(4.2, 1.1, 0.8),
		Color(0.14, 0.13, 0.17),
		"plastico_domestico",
	)
	for lado in [-1.0, 1.0]:
		for balda in 3:
			var y := 0.55 + balda * 0.62
			_caja_visual(
				interior,
				"BaldaBit98_%d_%d" % [int(lado), balda],
				Vector3(lado * 2.65, y, 0.0),
				Vector3(0.20, 0.08, 4.5),
				COLOR_METAL,
				"metal_pintado",
			)
			for juego in 5:
				var z := -1.7 + juego * 0.85
				_caja_visual(
					interior,
					"CajaJuego_%d_%d_%d" % [int(lado), balda, juego],
					Vector3(lado * 2.48, y + 0.22, z),
					Vector3(0.12, 0.34, 0.24),
					_color_portada(balda * 5 + juego + (0 if lado < 0 else 3)),
					"plastico_domestico",
				)

	for x in [-1.35, 1.35]:
		var tele := Node3D.new()
		tele.name = "CRTMostrador_%d" % int(x * 10.0)
		tele.position = Vector3(x, 1.12, -2.5)
		tele.rotation_degrees.y = 180.0
		interior.add_child(tele)
		(
			Modelos
			. mueble(
				tele,
				"televisionVintage",
				Vector3(0.62, 0.56, 0.50),
				Color(0.26, 0.24, 0.28),
			)
		)

	var compra := _interactuable(
		interior,
		"ComprarCartuchos",
		Vector3(0.0, 1.15, -2.05),
		Vector3(3.6, 1.7, 0.9),
		Interactuable3D.Verbo.USAR,
		_tr("CALLE_ROTULO_CARTUCHOS"),
	)
	compra.activado.connect(CalleIdentidad._comprar_cartucho.bind(compra))

	var salida := _interactuable(
		interior,
		"SalirTiendaVideojuegos",
		Vector3(0.0, 1.1, 3.25),
		Vector3(1.5, 2.2, 1.0),
		Interactuable3D.Verbo.ABRIR,
		_tr("CALLE_PUERTA_SALIDA"),
	)
	salida.activado.connect(_salir_bit98)
	return interior


func _entrar_electrodomesticos(actor: Node) -> void:
	_activar_interiores(_interior_electrodomesticos)
	_situar(actor, _interior_electrodomesticos.global_position + ENTRADA_INTERIOR, 0.0)


func _salir_electrodomesticos(actor: Node) -> void:
	_situar(actor, REGRESO_ELECTRODOMESTICOS, 180.0)
	_activar_interiores(null)


func _entrar_bit98(actor: Node) -> void:
	_activar_interiores(_interior_bit98)
	_situar(actor, _interior_bit98.global_position + ENTRADA_INTERIOR, 0.0)


func _salir_bit98(actor: Node) -> void:
	_situar(actor, REGRESO_BIT98, 180.0)
	_activar_interiores(null)


func _activar_interiores(activo: Node3D) -> void:
	_interior_electrodomesticos.visible = activo == _interior_electrodomesticos
	_interior_bit98.visible = activo == _interior_bit98


func _situar(actor: Node, posicion: Vector3, mirada: float) -> void:
	if actor != null and actor.has_method("situar"):
		actor.call("situar", posicion, mirada)
	elif _dia != null and _dia.get("_caminante") != null:
		_dia._caminante.situar(posicion, mirada)


func _montar_televisor_interior(padre: Node3D, indice: int, pos: Vector3) -> void:
	var base := _caja_fisica(
		padre,
		"PeanaTele%d" % indice,
		pos + Vector3(0.0, -0.18, 0.0),
		Vector3(0.85, 0.28, 0.72),
		COLOR_MADERA,
		"madera_domestica",
	)
	var tele := Node3D.new()
	tele.name = "TeleInterior%d" % indice
	tele.position = Vector3(0.0, 0.42, 0.0)
	tele.rotation_degrees.y = -90.0
	base.add_child(tele)
	(
		Modelos
		. mueble(
			tele,
			"televisionVintage",
			Vector3(0.68, 0.58, 0.52),
			Color(0.30, 0.28, 0.26),
		)
	)


func _montar_frigorifico(padre: Node3D, indice: int, pos: Vector3) -> void:
	var raiz := Node3D.new()
	raiz.name = "Frigorifico%d" % indice
	raiz.position = pos
	padre.add_child(raiz)
	_caja_fisica(
		raiz,
		"Cuerpo",
		Vector3(0.0, 1.0, 0.0),
		Vector3(0.85, 2.0, 0.78),
		Color(0.72, 0.73, 0.70),
		"metal_pintado",
	)
	_caja_visual(
		raiz,
		"SeparacionPuertas",
		Vector3(0.0, 1.2, 0.398),
		Vector3(0.72, 0.035, 0.025),
		Color(0.18, 0.18, 0.18),
	)
	_caja_visual(
		raiz,
		"Tirador",
		Vector3(0.28, 1.15, 0.42),
		Vector3(0.055, 0.62, 0.05),
		COLOR_METAL,
	)


func _montar_lavadora(padre: Node3D, indice: int, pos: Vector3) -> void:
	var raiz := Node3D.new()
	raiz.name = "Lavadora%d" % indice
	raiz.position = pos
	padre.add_child(raiz)
	_caja_fisica(
		raiz,
		"Cuerpo",
		Vector3(0.0, 0.48, 0.0),
		Vector3(0.82, 0.96, 0.74),
		Color(0.78, 0.78, 0.75),
		"metal_pintado",
	)
	var puerta := MeshInstance3D.new()
	puerta.name = "Tambor"
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.25
	cilindro.bottom_radius = 0.25
	cilindro.height = 0.035
	puerta.mesh = cilindro
	puerta.position = Vector3(0.0, 0.50, 0.39)
	puerta.rotation_degrees.x = 90.0
	Modelos._pintar(puerta, Color(0.12, 0.15, 0.18), "cristal_urbano")
	raiz.add_child(puerta)


func _caja_fisica(
	padre: Node3D,
	nombre: String,
	pos: Vector3,
	tam: Vector3,
	color: Color,
	textura: String = "",
) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = pos
	padre.add_child(cuerpo)

	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	Modelos._pintar(malla, color, textura)
	cuerpo.add_child(malla)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	cuerpo.add_child(colision)
	return cuerpo


func _caja_visual(
	padre: Node3D,
	nombre: String,
	pos: Vector3,
	tam: Vector3,
	color: Color,
	textura: String = "",
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	malla.position = pos
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	Modelos._pintar(malla, color, textura)
	padre.add_child(malla)
	return malla


func _interactuable(
	padre: Node3D,
	nombre: String,
	pos: Vector3,
	tam: Vector3,
	verbo: int,
	objeto: String,
) -> Interactuable3D:
	var zona := Interactuable3D.new()
	zona.name = nombre
	zona.position = pos
	zona.verbo = verbo
	zona.nombre_objeto = objeto
	padre.add_child(zona)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	zona.add_child(colision)
	return zona


func _color_portada(indice: int) -> Color:
	var paleta := [
		Color(0.82, 0.18, 0.20),
		Color(0.16, 0.42, 0.82),
		Color(0.92, 0.72, 0.16),
		Color(0.22, 0.68, 0.34),
		Color(0.62, 0.24, 0.76),
		Color(0.92, 0.44, 0.14),
	]
	return paleta[posmod(indice, paleta.size())]


func _tr(clave: String) -> String:
	return TranslationServer.translate(clave)
