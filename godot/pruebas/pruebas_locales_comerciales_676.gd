## Regresión del primer corte físico de comercio de barrio (#676).
extends SceneTree

const DIA := preload("res://escenas/dia.tscn")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		printerr("Ejecuta esta prueba desde unittest con datos aislados.")
		quit(1)
		return
	_probar.call_deferred()


func _probar() -> void:
	TranslationServer.set_locale("es")
	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame
	dia._entrar_en("trayecto")
	await process_frame

	var calle := dia._mundo.get_node_or_null("CalleIdentidad") as Node3D
	_comprobar(calle != null, "existe CalleIdentidad")
	if calle == null:
		_terminar(dia)
		return

	var locales := calle.get_node_or_null("LocalesComerciales") as CalleLocalesComerciales3D
	_comprobar(locales != null, "los locales se montan dentro del trayecto")
	if locales == null:
		_terminar(dia)
		return

	var electro := locales.get_node_or_null("InteriorElectrodomesticos") as Node3D
	var bit98 := locales.get_node_or_null("InteriorBit98") as Node3D
	_comprobar(electro != null, "existe interior de Electrodomesticos")
	_comprobar(bit98 != null, "existe interior de Bit 98")
	if electro == null or bit98 == null:
		_terminar(dia)
		return
	_comprobar(not electro.visible and not bit98.visible, "los interiores empiezan ocultos")
	var arte_bit98 := calle.get_node_or_null("ArteBit98") as Node3D
	_comprobar(arte_bit98 != null, "Bit 98 monta su capa visual propia")

	var fachada_electro := calle.get_node("Electrodomesticos")
	var fachada_bit98 := calle.get_node("TiendaVideojuegos")
	var entrar_electro := (
		fachada_electro.find_child("EntrarElectrodomesticos", true, false) as Interactuable3D
	)
	var entrar_bit98 := fachada_bit98.get_node_or_null("EntrarTiendaVideojuegos") as Interactuable3D
	var identidad_fachada := fachada_bit98.get_node_or_null("IdentidadBit98") as Node3D
	_comprobar(identidad_fachada != null, "la fachada de Bit 98 tiene identidad propia")
	if identidad_fachada != null:
		_comprobar(
			identidad_fachada.get_node_or_null("RotuloBit98Exterior") != null,
			"el rotulo Bit 98 existe en fachada",
		)
		var texto_exterior := (
			identidad_fachada.get_node_or_null("TextoRotuloBit98Exterior") as Label3D
		)
		_comprobar(
			texto_exterior != null and texto_exterior.text == "BIT 98",
			"la fachada de Bit 98 conserva texto legible en runtime",
		)
	_comprobar(entrar_electro != null, "Electrodomesticos tiene puerta interactuable")
	_comprobar(entrar_bit98 != null, "Bit 98 tiene puerta interactuable")
	_comprobar(
		fachada_bit98.get_node_or_null("ComprarCartuchos") == null,
		"la calle ya no compra cartuchos desde la acera"
	)
	if entrar_electro == null or entrar_bit98 == null:
		_terminar(dia)
		return
	_comprobar(
		entrar_electro.verbo == Interactuable3D.Verbo.ABRIR,
		"la puerta de Electrodomesticos usa el verbo Abrir"
	)
	_comprobar(
		entrar_bit98.verbo == Interactuable3D.Verbo.ABRIR, "la puerta de Bit 98 usa el verbo Abrir"
	)

	var fase_inicial := String(dia.jornada["fase"])
	var dinero_inicial := int(dia.jornada["dinero"])

	entrar_electro.interactuar(dia._caminante)
	await process_frame
	_comprobar(electro.visible and not bit98.visible, "entrar activa solo Electrodomesticos")
	_comprobar(dia._caminante.global_position.x < -40.0, "el caminante entra fisicamente al local")
	_comprobar(String(dia.jornada["fase"]) == fase_inicial, "entrar no crea otra fase")
	_comprobar(int(dia.jornada["dinero"]) == dinero_inicial, "entrar no cobra")

	var salir_electro := electro.get_node_or_null("SalirElectrodomesticos") as Interactuable3D
	_comprobar(salir_electro != null, "Electrodomesticos tiene salida")
	if salir_electro != null:
		salir_electro.interactuar(dia._caminante)
		await process_frame
		_comprobar(
			not electro.visible and not bit98.visible,
			"salir de Electrodomesticos oculta los microinteriores"
		)
		_comprobar(absf(dia._caminante.global_position.x) < 10.0, "se vuelve a la calle")

	entrar_bit98.interactuar(dia._caminante)
	await process_frame
	_comprobar(bit98.visible and not electro.visible, "entrar activa solo Bit 98")
	_comprobar(dia._caminante.global_position.x > 40.0, "el caminante entra fisicamente en Bit 98")
	_comprobar(String(dia.jornada["fase"]) == fase_inicial, "Bit 98 sigue en trayecto")
	_comprobar(int(dia.jornada["dinero"]) == dinero_inicial, "entrar en Bit 98 no cobra")

	var compra := bit98.get_node_or_null("ComprarCartuchos") as Interactuable3D
	_comprobar(compra != null, "la compra vive en el mostrador interior de Bit 98")
	if compra != null:
		_comprobar(
			compra.activado.get_connections().size() > 0,
			"el mostrador interior conserva el contrato de compra"
		)

	var identidad_interior := bit98.get_node_or_null("IdentidadBit98") as Node3D
	_comprobar(identidad_interior != null, "el interior de Bit 98 tiene identidad propia")
	if identidad_interior != null:
		_comprobar(
			identidad_interior.get_node_or_null("RotuloBit98Interior") != null,
			"el rotulo interior de Bit 98 existe",
		)
		var texto_interior := (
			identidad_interior.get_node_or_null("TextoRotuloBit98Interior") as Label3D
		)
		_comprobar(
			texto_interior != null and texto_interior.text == "BIT 98",
			"el interior conserva identidad textual legible",
		)
		var portadas := identidad_interior.find_children(
			"PortadaPropia_*", "MeshInstance3D", true, false
		)
		_comprobar(portadas.size() == 6, "se reutilizan seis portadas propias en expositor")

	var cajas_juego := bit98.find_children("CajaJuego_*", "MeshInstance3D", true, false)
	_comprobar(cajas_juego.size() == 30, "Bit 98 expone treinta cajas 3D en baldas")
	_comprobar(
		(
			electro.get_node_or_null("Frigorifico0") != null
			and electro.get_node_or_null("Frigorifico1") != null
		),
		"Electrodomesticos expone frigorificos"
	)
	_comprobar(
		(
			electro.get_node_or_null("Lavadora0") != null
			and electro.get_node_or_null("Lavadora1") != null
		),
		"Electrodomesticos expone lavadoras"
	)

	var salir_bit98 := bit98.get_node_or_null("SalirTiendaVideojuegos") as Interactuable3D
	_comprobar(salir_bit98 != null, "Bit 98 tiene salida")
	if salir_bit98 != null:
		salir_bit98.interactuar(dia._caminante)
		await process_frame
	_comprobar(String(dia.jornada["fase"]) == fase_inicial, "salir conserva trayecto")
	_comprobar(int(dia.jornada["dinero"]) == dinero_inicial, "entrar y salir no altera economia")

	_terminar(dia)


func _terminar(dia) -> void:
	dia.queue_free()
	await process_frame
	await create_timer(0.20).timeout
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO LocalesComerciales676: " + nombre)
