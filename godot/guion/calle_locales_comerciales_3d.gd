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
	var puerta_electro := _mejorar_electrodomesticos(calle)
	var puerta_bit98 := _mejorar_bit98(calle)

	_interior_electrodomesticos = _montar_electrodomesticos()
	_interior_bit98 = _montar_bit98()
	_interior_electrodomesticos.visible = false
	_interior_bit98.visible = false

	if puerta_electro != null:
		puerta_electro.activado.connect(_entrar_electrodomesticos)
	if puerta_bit98 != null:
		puerta_bit98.activado.connect(_entrar_bit98)


func _mejorar_electrodomesticos(calle: Node3D) -> Interactuable3D:
	var fachada := calle.get_node_or_null("Electrodomesticos") as Node3D
	if fachada == null:
		return null
	var plano_viejo := fachada.get_node_or_null("InteriorTienda") as MeshInstance3D
	if plano_viejo != null:
		plano_viejo.visible = false

	var dressing := Node3D.new()
	dressing.name = "EscaparateProfundo"
	fachada.add_child(dressing)
	_caja_visual(
		dressing,
		"SueloExposicion",
		Vector3(-6.15, 0.16, -1.5),
		Vector3(0.92, 0.18, 6.35),
		COLOR_MADERA,
		"madera_domestica",
	)
	_caja_visual(
		dressing,
		"FondoEscaparate",
		Vector3(-6.52, 1.58, -1.5),
		Vector3(0.05, 2.65, 6.2),
		Color(0.16, 0.15, 0.16),
		"gotele",
	)
	for z_marco in [-4.55, 1.55]:
		_caja_visual(
			dressing,
			"RetornoEscaparate%.0f" % (z_marco * 10.0),
			Vector3(-6.12, 1.55, z_marco),
			Vector3(0.82, 2.75, 0.08),
			COLOR_METAL,
			"metal_pintado",
		)
	for fila in 2:
		for columna in 4:
			_caja_visual(
				dressing,
				"Cartela%d_%d" % [fila, columna],
				Vector3(-5.80, 0.56 + fila * 0.90, -3.75 + columna * 1.50),
				Vector3(0.03, 0.13, 0.42),
				Color(0.78, 0.76, 0.68),
			)

	_caja_visual(
		dressing,
		"MarcoPuertaEntrada",
		Vector3(-5.67, 2.38, 2.45),
		Vector3(0.08, 0.12, 1.05),
		COLOR_METAL,
		"metal_pintado",
	)
	_caja_visual(
		dressing,
		"TiradorPuertaEntrada",
		Vector3(-5.62, 1.12, 2.72),
		Vector3(0.06, 0.42, 0.05),
		Color(0.62, 0.59, 0.48),
		"metal_pintado",
	)
	return _interactuable(
		dressing,
		"EntrarElectrodomesticos",
		Vector3(-5.05, 1.1, 2.45),
		Vector3(1.1, 2.2, 1.05),
		Interactuable3D.Verbo.ABRIR,
		_tr("CALLE_PUERTA_ELECTRODOMESTICOS"),
	)


func _mejorar_bit98(calle: Node3D) -> Interactuable3D:
	var fachada := calle.get_node_or_null("TiendaVideojuegos") as Node3D
	if fachada == null:
		return null
	var frente := fachada.get_node_or_null("Frente") as Node3D
	if frente != null:
		frente.visible = false
	for i in 12:
		var cartucho_plano := fachada.get_node_or_null("Cartucho%d" % i) as MeshInstance3D
		if cartucho_plano != null:
			cartucho_plano.visible = false

	var dressing := Node3D.new()
	dressing.name = "EscaparateProfundo"
	fachada.add_child(dressing)
	for ficha in [
		["Zocalo", Vector3(5.46, 0.30, -6.5), Vector3(0.08, 0.60, 3.9)],
		["Dintel", Vector3(5.46, 2.72, -6.5), Vector3(0.08, 0.56, 3.9)],
		["JambaSur", Vector3(5.46, 1.50, -8.40), Vector3(0.08, 2.45, 0.12)],
		["JambaCentro", Vector3(5.46, 1.50, -5.85), Vector3(0.08, 2.45, 0.12)],
		["JambaNorte", Vector3(5.46, 1.50, -4.62), Vector3(0.08, 2.45, 0.12)],
	]:
		_caja_visual(dressing, ficha[0], ficha[1], ficha[2], Color(0.08, 0.08, 0.10))
	_caja_visual(
		dressing,
		"FondoEscaparate",
		Vector3(6.18, 1.45, -7.2),
		Vector3(0.05, 2.30, 2.25),
		Color(0.11, 0.09, 0.15),
		"gotele",
	)
	for fila in 2:
		_caja_visual(
			dressing,
			"BaldaEscaparate%d" % fila,
			Vector3(5.80, 0.78 + fila * 0.66, -7.2),
			Vector3(0.72, 0.07, 2.15),
			Color(0.17, 0.16, 0.20),
			"metal_pintado",
		)
	for i in 12:
		var fila := i / 6
		var z := -8.05 + (i % 6) * 0.34
		_caja_visual(
			dressing,
			"CajaCartucho%d" % i,
			Vector3(5.72, 0.95 + fila * 0.62, z),
			Vector3(0.16, 0.36, 0.26),
			_color_portada(i),
			"plastico_domestico",
		)

	var puerta := fachada.get_node_or_null("ComprarCartuchos") as Interactuable3D
	if puerta == null:
		return null
	for conexion in puerta.activado.get_connections():
		var llamada: Callable = conexion["callable"]
		puerta.activado.disconnect(llamada)
	puerta.name = "EntrarTiendaVideojuegos"
	puerta.verbo = Interactuable3D.Verbo.ABRIR
	puerta.nombre_objeto = _tr("CALLE_PUERTA_VIDEOJUEGOS")
	return puerta


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
