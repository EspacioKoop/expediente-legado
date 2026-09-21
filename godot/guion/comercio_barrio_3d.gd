## Superficies físicas de Quiosco Avenida y El Trastero (#676).
##
## El catálogo y la economía siguen perteneciendo a ComercioBarrio. Esta capa
## solo materializa dos puestos de calle y conecta cada producto visible con la
## compra existente. No crea interiores, stock paralelo ni semillas oníricas.
class_name ComercioBarrio3D
extends Node3D

const NOMBRE := "ComercioBarrioFisico"
const TEX_QUIOSCO: Texture2D = preload("res://arte/comercio_barrio/quiosco_avenida.svg")
const TEX_TRASTERO: Texture2D = preload("res://arte/comercio_barrio/el_trastero.svg")

const POS_QUIOSCO := Vector3(4.95, 0.0, 3.75)
const POS_TRASTERO := Vector3(-5.05, 0.0, 11.15)

const COLOR_MADERA := Color(0.34, 0.25, 0.18)
const COLOR_METAL := Color(0.17, 0.18, 0.19)
const COLOR_VERDE := Color(0.20, 0.36, 0.24)
const COLOR_LATON := Color(0.50, 0.37, 0.16)

var _dia: Node


static func montar(dia: Node, calle: Node3D) -> ComercioBarrio3D:
	if dia == null or calle == null:
		return null
	var existente := calle.get_node_or_null(NOMBRE) as ComercioBarrio3D
	if existente != null:
		return existente

	var comercio := ComercioBarrio3D.new()
	comercio.name = NOMBRE
	comercio._dia = dia
	calle.add_child(comercio)
	comercio._montar_quiosco()
	comercio._montar_trastero()
	return comercio


func _montar_quiosco() -> void:
	var puesto := Node3D.new()
	puesto.name = "QuioscoAvenida"
	puesto.position = POS_QUIOSCO
	puesto.set_meta("superficie_comercio", "quiosco")
	add_child(puesto)

	_caja(
		puesto,
		"FondoQuiosco",
		Vector3(0.0, 1.22, 0.0),
		Vector3(0.42, 2.44, 2.55),
		Color(0.22, 0.19, 0.16),
		"madera_domestica",
	)
	_caja(
		puesto,
		"MostradorQuiosco",
		Vector3(-0.31, 0.88, 0.0),
		Vector3(0.42, 0.13, 2.38),
		COLOR_MADERA,
		"madera_domestica",
	)
	_caja(
		puesto,
		"ToldoQuiosco",
		Vector3(-0.18, 2.34, 0.0),
		Vector3(0.58, 0.10, 2.72),
		Color(0.46, 0.15, 0.15),
		"tela",
	)
	_lamina(
		puesto,
		"RotuloQuioscoAvenida",
		TEX_QUIOSCO,
		Vector3(-0.225, 2.02, 0.0),
		Vector2(1.95, 0.69),
		-90.0,
	)

	_montar_ticket(puesto, Vector3(-0.58, 1.36, 1.18))

	var entradas := ComercioBarrio.listar("quiosco", _dia.jornada, _inventario())
	for indice in entradas.size():
		var entrada: Dictionary = entradas[indice]
		var z := -0.90 + float(indice) * 0.60
		_montar_producto(puesto, "quiosco", entrada, Vector3(-0.56, 1.04, z), indice)


func _montar_trastero() -> void:
	var puesto := Node3D.new()
	puesto.name = "ElTrastero"
	puesto.position = POS_TRASTERO
	puesto.set_meta("superficie_comercio", "segunda_mano")
	add_child(puesto)

	_caja(
		puesto,
		"FondoTrastero",
		Vector3(0.0, 1.20, 0.0),
		Vector3(0.42, 2.40, 3.20),
		Color(0.26, 0.25, 0.22),
		"gotele",
	)
	_caja(
		puesto,
		"MostradorTrastero",
		Vector3(0.31, 0.86, 0.0),
		Vector3(0.42, 0.16, 2.90),
		COLOR_MADERA,
		"madera_domestica",
	)
	_lamina(
		puesto,
		"RotuloElTrastero",
		TEX_TRASTERO,
		Vector3(0.225, 2.02, 0.0),
		Vector2(2.05, 0.82),
		90.0,
	)

	_montar_ticket(puesto, Vector3(0.58, 1.36, 1.42))

	var entradas := (
		ComercioBarrio
		. listar(
			"segunda_mano",
			_dia.jornada,
			_inventario(),
		)
	)
	for indice in entradas.size():
		var entrada: Dictionary = entradas[indice]
		var z := -0.58 + float(indice) * 1.16
		_montar_producto(
			puesto,
			"segunda_mano",
			entrada,
			Vector3(0.56, 1.06, z),
			indice,
		)
	_montar_reventa(puesto)


func _montar_reventa(puesto: Node3D) -> void:
	var inventario := _inventario()
	var llevados = inventario.get(Inventario.CARRIED, [])
	if typeof(llevados) != TYPE_ARRAY:
		return

	var bandeja := Node3D.new()
	bandeja.name = "BandejaReventa"
	bandeja.set_meta("solo_carried", true)
	puesto.add_child(bandeja)
	_caja(
		bandeja,
		"BaseBandejaReventa",
		Vector3(0.58, 0.62, 0.0),
		Vector3(0.34, 0.06, 2.45),
		COLOR_METAL,
	)

	var indice := 0
	for valor in llevados:
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var objeto: Dictionary = valor
		if not bool(objeto.get("vendible", false)):
			continue
		var item_id := String(objeto.get("id", ""))
		if item_id.is_empty():
			continue
		var fila := indice / 4
		var columna := indice % 4
		var posicion := Vector3(
			0.58,
			0.73 + float(fila) * 0.25,
			-0.90 + float(columna) * 0.60,
		)
		_montar_objeto_reventa(bandeja, objeto, posicion, indice)
		indice += 1


func _montar_objeto_reventa(
	padre: Node3D,
	objeto: Dictionary,
	posicion: Vector3,
	indice: int,
) -> void:
	var item_id := String(objeto.get("id", ""))
	var venta := Interactuable3D.new()
	venta.name = "Vender_%s" % item_id
	venta.position = posicion
	venta.verbo = Interactuable3D.Verbo.USAR
	venta.sonido = Interactuable3D.SIN_SONIDO
	venta.nombre_objeto = _texto_reventa(objeto)
	venta.set_meta("reventa_fisica", true)
	venta.set_meta("item_reventa", item_id)
	venta.set_meta("indice_reventa", indice)
	padre.add_child(venta)
	_visual_reventa(venta, objeto)

	var colision := CollisionShape3D.new()
	colision.name = "VolumenReventa"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.34, 0.24, 0.44)
	colision.shape = forma
	venta.add_child(colision)
	venta.activado.connect(_vender.bind(item_id, venta))


func _visual_reventa(venta: Interactuable3D, objeto: Dictionary) -> void:
	var item_id := String(objeto.get("id", ""))
	if not Publicaciones98.por_id(item_id).is_empty():
		PublicacionFisica3D.montar(venta, item_id)
		return

	_caja(
		venta,
		"ObjetoReventa",
		Vector3.ZERO,
		Vector3(0.20, 0.14, 0.18),
		Color(0.38, 0.34, 0.28),
		"madera_domestica",
	)
	_caja(
		venta,
		"EtiquetaReventa",
		Vector3(-0.11, 0.02, 0.0),
		Vector3(0.012, 0.07, 0.12),
		Color(0.72, 0.67, 0.52),
	)


func _montar_producto(
	padre: Node3D,
	superficie: String,
	entrada: Dictionary,
	posicion: Vector3,
	indice: int,
) -> void:
	var item_id := String(entrada.get("id", ""))
	if item_id.is_empty():
		return

	var compra := Interactuable3D.new()
	compra.name = "Comprar_%s_%s" % [superficie, item_id]
	compra.position = posicion
	compra.verbo = Interactuable3D.Verbo.USAR
	compra.sonido = Interactuable3D.SIN_SONIDO
	compra.nombre_objeto = _texto_compra(entrada)
	compra.set_meta("superficie_comercio", superficie)
	compra.set_meta("item_comercio", item_id)
	compra.set_meta("indice_expositor", indice)
	padre.add_child(compra)

	if superficie == "quiosco":
		_visual_quiosco(compra, item_id)
	else:
		_visual_segunda_mano(compra, item_id)

	var colision := CollisionShape3D.new()
	colision.name = "VolumenCompra"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.42, 0.58, 0.48)
	colision.shape = forma
	compra.add_child(colision)
	compra.activado.connect(_comprar.bind(superficie, item_id, compra))


func _visual_quiosco(compra: Interactuable3D, item_id: String) -> void:
	if not Publicaciones98.por_id(item_id).is_empty():
		PublicacionFisica3D.montar(compra, item_id)
		return

	_caja(
		compra,
		"PaqueteConsumo",
		Vector3.ZERO,
		Vector3(0.13, 0.20, 0.06),
		Color(0.72, 0.66, 0.50),
	)
	_caja(
		compra,
		"FranjaPaquete",
		Vector3(0.0, 0.04, -0.035),
		Vector3(0.12, 0.045, 0.01),
		Color(0.42, 0.16, 0.15),
	)


func _visual_segunda_mano(compra: Interactuable3D, item_id: String) -> void:
	if "lampara" in item_id:
		_cilindro(
			compra,
			"BaseLampara",
			Vector3(0.0, -0.08, 0.0),
			0.085,
			0.05,
			COLOR_VERDE,
		)
		_cilindro(
			compra,
			"PieLampara",
			Vector3(0.0, 0.04, 0.0),
			0.018,
			0.22,
			COLOR_METAL,
		)
		var pantalla := MeshInstance3D.new()
		pantalla.name = "PantallaLampara"
		var cono := CylinderMesh.new()
		cono.top_radius = 0.065
		cono.bottom_radius = 0.13
		cono.height = 0.13
		pantalla.mesh = cono
		pantalla.position = Vector3(0.0, 0.18, 0.0)
		Modelos._pintar(pantalla, COLOR_VERDE)
		compra.add_child(pantalla)
		return

	_caja(
		compra,
		"MarcoLaton",
		Vector3.ZERO,
		Vector3(0.24, 0.31, 0.035),
		COLOR_LATON,
	)
	_caja(
		compra,
		"InteriorMarco",
		Vector3(0.0, 0.0, -0.022),
		Vector3(0.18, 0.24, 0.012),
		Color(0.15, 0.13, 0.11),
	)


func _comprar(
	_actor: Node,
	superficie: String,
	item_id: String,
	compra: Interactuable3D,
) -> void:
	if _dia == null:
		return
	var inventario := _inventario()
	var resultado := (
		ComercioBarrio
		. comprar(
			_dia.jornada,
			inventario,
			superficie,
			item_id,
		)
	)
	var entrada := _buscar_entrada(superficie, item_id, inventario)
	_mostrar_ticket(superficie, resultado, "compra")
	if bool(resultado.get("ok", false)):
		compra.nombre_objeto = _texto_compra(entrada)
		if not bool(resultado.get("repetible", false)):
			compra.nombre_objeto = "%s · comprado" % String(entrada.get("nombre", item_id))
		if _dia.has_method("_guardar_o_avisar"):
			_dia.call("_guardar_o_avisar", "")
		return

	var motivo := String(resultado.get("motivo", "fallo"))
	var nombre := String(entrada.get("nombre", item_id))
	if motivo == "sin_dinero":
		compra.nombre_objeto = "%s · sin dinero" % nombre
	else:
		compra.nombre_objeto = "%s · no disponible" % nombre


func _vender(_actor: Node, item_id: String, venta: Interactuable3D) -> void:
	if _dia == null:
		return
	var inventario := _inventario()
	var resultado := (
		ComercioBarrio
		. vender(
			_dia.jornada,
			inventario,
			"segunda_mano",
			item_id,
		)
	)
	_mostrar_ticket("segunda_mano", resultado, "venta")
	if bool(resultado.get("ok", false)):
		venta.habilitado = false
		venta.visible = false
		if _dia.has_method("_guardar_o_avisar"):
			_dia.call("_guardar_o_avisar", "")
		return

	var motivo := String(resultado.get("motivo", "reventa_rechazada"))
	venta.nombre_objeto = "%s · %s" % [venta.nombre_objeto.get_slice(" · ", 0), motivo]


func _montar_ticket(puesto: Node3D, posicion: Vector3) -> void:
	var ticket := Node3D.new()
	ticket.name = "TicketTransaccion"
	ticket.position = posicion
	ticket.visible = false
	puesto.add_child(ticket)

	_caja(
		ticket,
		"PapelTicket",
		Vector3.ZERO,
		Vector3(0.018, 0.30, 0.42),
		Color(0.79, 0.76, 0.66),
	)

	var texto := Label3D.new()
	texto.name = "TextoTicket"
	texto.position = Vector3(-0.02, 0.0, 0.0)
	texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texto.font = EstiloSiga.fuente_mono()
	texto.font_size = 30
	texto.pixel_size = 0.0022
	texto.outline_size = 5
	texto.modulate = Color(0.16, 0.15, 0.13)
	texto.text = ""
	ticket.add_child(texto)


func _mostrar_ticket(superficie: String, resultado: Dictionary, operacion: String) -> void:
	var puesto := (
		get_node_or_null("QuioscoAvenida")
		if superficie == "quiosco"
		else get_node_or_null("ElTrastero")
	) as Node3D
	if puesto == null:
		return
	var ticket := puesto.get_node_or_null("TicketTransaccion") as Node3D
	if ticket == null:
		return
	var texto := ticket.get_node_or_null("TextoTicket") as Label3D
	if texto == null:
		return
	texto.text = _texto_ticket(resultado, operacion)
	texto.modulate = (
		Color(0.18, 0.35, 0.22)
		if bool(resultado.get("ok", false))
		else Color(0.52, 0.16, 0.15)
	)
	ticket.visible = true


func _texto_ticket(resultado: Dictionary, operacion: String) -> String:
	if bool(resultado.get("ok", false)):
		if operacion == "compra" and bool(resultado.get("ya_comprado", false)):
			return "YA COMPRADO"
		var importe := maxi(0, int(resultado.get("importe", 0)))
		return "REVENTA · +%d" % importe if operacion == "venta" else "PAGO · -%d" % importe

	match String(resultado.get("motivo", "fallo")):
		"sin_dinero":
			return "NO LLEGA EL DINERO"
		"no_llevado":
			return "NO LO LLEVAS"
		"onirico", "no_vendible":
			return "NO SE VENDE"
		_:
			return "NO DISPONIBLE"


func _buscar_entrada(
	superficie: String,
	item_id: String,
	inventario: Dictionary,
) -> Dictionary:
	for entrada in ComercioBarrio.listar(superficie, _dia.jornada, inventario):
		if String(entrada.get("id", "")) == item_id:
			return entrada
	return {"id": item_id, "nombre": item_id, "precio": 0}


func _inventario() -> Dictionary:
	var inventario = _dia.partida.estado.get("inventario", null)
	if typeof(inventario) != TYPE_DICTIONARY:
		inventario = Inventario.nuevo()
		_dia.partida.estado["inventario"] = inventario
	Inventario.completar(inventario)
	return inventario


func _texto_compra(entrada: Dictionary) -> String:
	var nombre := String(entrada.get("nombre", "objeto"))
	if bool(entrada.get("comprada", false)):
		return "%s · comprado" % nombre
	return "%s · %d" % [nombre, int(entrada.get("precio", 0))]


func _texto_reventa(objeto: Dictionary) -> String:
	var nombre := String(objeto.get("nombre", objeto.get("id", "objeto")))
	return "vender %s · +%d" % [nombre, maxi(0, int(objeto.get("precio", 0)))]


func _lamina(
	padre: Node3D,
	nombre: String,
	textura: Texture2D,
	posicion: Vector3,
	tam: Vector2,
	giro_y: float,
) -> void:
	var lamina := MeshInstance3D.new()
	lamina.name = nombre
	lamina.position = posicion
	lamina.rotation_degrees.y = giro_y
	lamina.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plano := QuadMesh.new()
	plano.size = tam
	lamina.mesh = plano
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = (BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC)
	lamina.material_override = material
	padre.add_child(lamina)


func _caja(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	tam: Vector3,
	color: Color,
	textura: String = "",
) -> void:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	malla.position = posicion
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	Modelos._pintar(malla, color, textura)
	padre.add_child(malla)


func _cilindro(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	radio: float,
	alto: float,
	color: Color,
) -> void:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	malla.position = posicion
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	Modelos._pintar(malla, color)
	padre.add_child(malla)
