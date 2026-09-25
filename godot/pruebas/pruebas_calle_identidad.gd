## La calle se lee: oficina, tiendas, ventanillas y casa en el trayecto real (#398).
extends SceneTree

const DIA := preload("res://escenas/dia.tscn")
const VENTANILLA := preload("res://escenas/ventanilla.tscn")
const GRUPOS := [
	"EdificioOficina",
	"BloqueCasa",
	"VentanillaReclamaciones",
	"Electrodomesticos",
	"TiendaVideojuegos",
	"Alquileres",
	"Farolas",
	"PisosFachada",
]

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		printerr("Ejecuta esta prueba desde unittest con datos aislados.")
		quit(1)
		return
	_probar.call_deferred()


func _probar() -> void:
	_comprobar(CalleIdentidad.montar(null) == null, "sin mundo no hay montaje")
	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame
	dia._entrar_en("trayecto")
	await process_frame
	var mundo: Node3D = dia._mundo
	var calle := mundo.get_node_or_null("CalleIdentidad") as Node3D
	_comprobar(calle != null, "el trayecto monta la identidad de la calle")
	if calle == null:
		_terminar(dia)
		return
	_comprobar(CalleIdentidad.montar(mundo) == calle, "montaje idempotente")
	for grupo in GRUPOS:
		_comprobar(calle.get_node_or_null(grupo) != null, "existe " + grupo)

	_probar_orden_del_recorrido()
	_probar_escaparate(calle)
	_probar_cristales_psx(calle)
	_probar_rotulos(calle)
	_probar_silueta_bloque_casa(calle)
	_probar_farolas(calle)
	await _probar_tienda(dia, calle)
	await _probar_coliseo(dia, calle)

	for fase in ["archivo", "trayecto", "casa", "trayecto"]:
		dia._entrar_en(fase)
		await process_frame
		var montada = dia._mundo.get_node_or_null("CalleIdentidad")
		_comprobar((montada != null) == (fase == "trayecto"), "hook real de fase " + fase)
	await _probar_ventanilla_suelta()
	_terminar(dia)


## Se sale de la oficina a la espalda del spawn y se llega al portal del bloque de casa.
func _probar_orden_del_recorrido() -> void:
	var calle_catalogo: Dictionary = EspaciosCatalogo.CALLE
	var entrada: Vector3 = calle_catalogo["entrada"]
	var portal: Vector3 = calle_catalogo["salidas"][0]["pos"]
	_comprobar(CalleIdentidad.OFICINA_FACHADA_Z < entrada.z, "la oficina queda detrás del spawn")
	_comprobar(entrada.z - CalleIdentidad.OFICINA_FACHADA_Z < 3.0, "se sale pegado a su puerta")
	_comprobar(CalleIdentidad.CASA_FACHADA_Z > portal.z, "el portal está en la fachada de casa")
	_comprobar(absf(portal.x) < 0.5, "el portal queda centrado al fondo de la calle")


func _probar_escaparate(calle: Node3D) -> void:
	var tienda := calle.get_node("Electrodomesticos")
	var teles := []
	var pantallas := []
	for hijo in tienda.get_children():
		if str(hijo.name).begins_with("Televisor"):
			teles.append(hijo)
		elif str(hijo.name).begins_with("Pantalla"):
			pantallas.append(hijo)
	_comprobar(teles.size() == 8, "ocho televisores en el escaparate")
	_comprobar(pantallas.size() == 8, "ocho pantallas encendidas")
	var filas := {}
	for tele in teles:
		var y := snappedf(tele.position.y, 0.01)
		filas[y] = int(filas.get(y, 0)) + 1
	_comprobar(filas.size() == 2, "dos hileras de televisores")
	for y in filas:
		_comprobar(filas[y] == 4, "cuatro televisores por hilera")
	var materiales := {}
	for pantalla in pantallas:
		materiales[pantalla.material_override.get_instance_id()] = true
	_comprobar(materiales.size() == 8, "cada tele tiene su propia emisión")
	var vistas := []
	for hijo in tienda.get_children():
		if hijo is SubViewport:
			vistas.append(hijo)
	_comprobar(vistas.size() == 8, "cada emisión conserva su viewport independiente")
	var cristal := tienda.get_node_or_null("CristalEscaparate") as MeshInstance3D
	_comprobar(cristal != null, "el escaparate tiene cristal")
	if cristal != null:
		var vidrio := cristal.material_override as ShaderMaterial
		_comprobar(vidrio != null, "el cristal usa material shader")
		if vidrio != null:
			_comprobar(
				vidrio.shader.resource_path.ends_with("psx_cristal.gdshader"),
				"el cristal conserva el tratamiento PSX"
			)
			var color_base: Color = vidrio.get_shader_parameter("color_base")
			_comprobar(color_base.a < 0.5, "el cristal deja ver las teles")
		for tele in teles:
			_comprobar(
				tele.global_position.x < cristal.global_position.x, "tele detrás del cristal"
			)


func _probar_cristales_psx(calle: Node3D) -> void:
	for ruta in [
		"EdificioOficina/Vestibulo",
		"EdificioOficina/PuertaIzquierda",
		"EdificioOficina/PuertaDerecha",
		"BloqueCasa/CristalPortal",
		"VentanillaReclamaciones/PuertaCristal",
		"VentanillaReclamaciones/Mostrador",
		"Electrodomesticos/CristalEscaparate",
		"TiendaVideojuegos/Escaparate",
		"TiendaVideojuegos/Puerta",
		"Alquileres/VentanillaPago",
		"Alquileres/Puerta",
	]:
		var cristal := calle.get_node_or_null(ruta) as MeshInstance3D
		_comprobar(cristal != null, "existe vidrio PSX " + ruta)
		if cristal == null:
			continue
		var vidrio := cristal.material_override as ShaderMaterial
		_comprobar(vidrio != null, "el vidrio usa ShaderMaterial " + ruta)
		if vidrio == null:
			continue
		_comprobar(
			vidrio.shader.resource_path.ends_with("psx_cristal.gdshader"),
			"el vidrio conserva shader PSX " + ruta
		)
		var color_base: Color = vidrio.get_shader_parameter("color_base")
		_comprobar(color_base.a < 0.5, "el vidrio deja leer el interior " + ruta)


func _probar_rotulos(calle: Node3D) -> void:
	var textos := []
	for rotulo in calle.find_children("*", "Label3D", true, false):
		textos.append(rotulo.text)
		_comprobar(not rotulo.text.begins_with("CALLE_"), "rótulo traducido: " + rotulo.text)
	for clave in [
		"CALLE_ROTULO_OFICINA",
		"CALLE_ROTULO_RECLAMACIONES",
		"CALLE_ROTULO_ELECTRODOMESTICOS",
		"CALLE_ROTULO_VIDEOJUEGOS",
		"CALLE_ROTULO_ALQUILERES",
	]:
		_comprobar(textos.has(TranslationServer.translate(clave)), "rótulo visible: " + clave)


func _probar_silueta_bloque_casa(calle: Node3D) -> void:
	var bloque := calle.get_node("BloqueCasa") as Node3D
	var oeste := bloque.get_node_or_null("AlaOeste") as MeshInstance3D
	var centro := bloque.get_node_or_null("TorreCentral") as MeshInstance3D
	var este := bloque.get_node_or_null("AlaEste") as MeshInstance3D
	_comprobar(
		oeste != null and centro != null and este != null,
		"el bloque final tiene silueta escalonada"
	)
	_comprobar(
		bloque.get_node_or_null("Volumen") == null,
		"no vuelve el prisma monolítico del bloque final"
	)
	if oeste != null and centro != null and este != null:
		var malla_oeste := oeste.mesh as BoxMesh
		var malla_centro := centro.mesh as BoxMesh
		var malla_este := este.mesh as BoxMesh
		_comprobar(
			(
				malla_oeste != null
				and malla_centro != null
				and malla_este != null
				and malla_oeste.size.y < malla_centro.size.y
				and malla_este.size.y < malla_centro.size.y
			),
			"las alas dejan cielo a ambos lados de la torre central"
		)
	_comprobar(
		(
			bloque.get_node_or_null("Ventana2_0") == null
			and bloque.get_node_or_null("Ventana2_3") != null
			and bloque.get_node_or_null("Ventana2_6") == null
		),
		"la tercera planta se concentra en el cuerpo central"
	)
	_comprobar(bloque.get_node_or_null("PuertaPortal") != null, "el portal de casa se conserva")


func _probar_farolas(calle: Node3D) -> void:
	var farolas := calle.get_node("Farolas")
	for luz in EspaciosCatalogo.CALLE["luces"]:
		var z := "%.0f" % luz["pos"].z
		_comprobar(farolas.get_node_or_null("Cable" + z) != null, "la luz cuelga de un cable " + z)


func _probar_tienda(dia, calle: Node3D) -> void:
	var puerta := calle.find_child("ComprarCartuchos", true, false) as Interactuable3D
	_comprobar(puerta != null, "la tienda de videojuegos se puede usar")
	if puerta == null:
		return
	_comprobar(puerta.global_position.x > 4.0, "se compra desde la acera derecha")
	var catalogo := TiendaVideojuegos.catalogo()
	var gastado := 0
	for entrada in catalogo:
		gastado += int(entrada["precio"])
	# El fixture debe poder comprar todo el catálogo aunque crezca: deja 10 de margen
	# para comprobar además que el último intento no vuelve a cobrar.
	var saldo_inicial := gastado + 10
	dia.jornada["dinero"] = saldo_inicial
	var primera: Dictionary = catalogo[0]
	var hay_stock := FileAccess.file_exists(String(primera["ruta"]))
	puerta.interactuar(dia._caminante)
	await process_frame
	var compradas := TiendaVideojuegos.compras(dia.jornada)
	if hay_stock:
		_comprobar(compradas.size() == 1, "comprar añade el cartucho a la jornada")
		_comprobar(
			int(dia.jornada["dinero"]) == saldo_inicial - int(primera["precio"]), "cobra el precio"
		)
		# Cada uso compra el siguiente cartucho pendiente; cuando no queda nada,
		# se avisa y ya no se cobra.
		for i in catalogo.size():
			puerta.interactuar(dia._caminante)
		_comprobar(
			TiendaVideojuegos.compras(dia.jornada).size() == catalogo.size(),
			"se puede comprar todo el catálogo"
		)
		_comprobar(int(dia.jornada["dinero"]) == saldo_inicial - gastado, "no cobra dos veces")
		_comprobar(
			TiendaVideojuegos.consola_trucos_desbloqueada(dia.jornada),
			"completar el catálogo desbloquea el manual de servicio"
		)
		_comprobar(
			puerta.nombre_objeto == TranslationServer.translate("CALLE_TIENDA_MANUAL_SERVICIO"),
			"Bit 98 anuncia el manual de servicio"
		)
	else:
		_comprobar(compradas.is_empty(), "sin existencias no se compra")
		_comprobar(int(dia.jornada["dinero"]) == saldo_inicial, "sin existencias no cobra")
		_comprobar(
			puerta.nombre_objeto == TranslationServer.translate("CALLE_TIENDA_FALLO_SIN_STOCK"),
			"avisa de que no hay existencias"
		)


func _probar_coliseo(dia, calle: Node3D) -> void:
	var entrada := calle.find_child("EntrarVentanillaReclamaciones", true, false) as Interactuable3D
	_comprobar(entrada != null, "la ventanilla de reclamaciones se puede usar")
	if entrada == null:
		return
	_comprobar(entrada.global_position.x < -4.0, "se entra desde la acera izquierda")
	entrada.interactuar(dia._caminante)
	await process_frame
	var pantalla = dia._pantalla
	_comprobar(pantalla != null, "abre la pantalla del Coliseo encima del día")
	if pantalla == null:
		return
	var ventanilla = pantalla.get_child(0)
	_comprobar(ventanilla.partida == dia.partida, "atiende con la misma partida del día")
	_comprobar(not dia._caminante.is_physics_processing(), "el jugador no anda mientras reclama")
	var salir := ventanilla.find_child("SalirVentanilla", true, false) as Button
	_comprobar(salir != null, "la ventanilla tiene salida a la calle")
	if salir != null:
		salir.pressed.emit()
		await process_frame
	_comprobar(dia._pantalla == null, "al salir se vuelve a la calle")
	_comprobar(dia._caminante.is_physics_processing(), "se vuelve a andar")

	entrada.interactuar(dia._caminante)
	await process_frame
	pantalla = dia._pantalla
	_comprobar(pantalla != null, "se puede reabrir el Coliseo")
	if pantalla == null:
		return
	ventanilla = pantalla.get_child(0)
	var cancelar := InputEventAction.new()
	cancelar.action = "cancelar"
	cancelar.pressed = true
	ventanilla._unhandled_input(cancelar)
	await process_frame
	_comprobar(dia._pantalla == null, "cancelar cierra el Coliseo y vuelve a la calle")
	_comprobar(dia._caminante.is_physics_processing(), "cancelar devuelve el control al jugador")


func _probar_ventanilla_suelta() -> void:
	var ventanilla = VENTANILLA.instantiate()
	root.add_child(ventanilla)
	await process_frame
	var salir := ventanilla.find_child("SalirVentanilla", true, false) as Button
	_comprobar(salir != null, "la Ventanilla suelta también muestra Salir")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	ventanilla._unhandled_input(escape)
	await process_frame
	await process_frame
	_comprobar(
		current_scene != null and current_scene.name == "Inicio", "Esc vuelve al menú de inicio"
	)
	ventanilla.queue_free()


func _terminar(dia) -> void:
	dia.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO CalleIdentidad: " + nombre)
