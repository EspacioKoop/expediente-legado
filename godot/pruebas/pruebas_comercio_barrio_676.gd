## Regresión del corte físico de Quiosco Avenida y El Trastero (#676).
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
	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame

	var inventario_pre = dia.partida.estado.get("inventario", {})
	Inventario.completar(inventario_pre)
	(
		Inventario
		. recoger(
			inventario_pre,
			{
				"id": "taza-reventa",
				"nombre": "Taza usada",
				"categoria": "hogar",
				"origen": "vida",
				"vendible": true,
				"precio": 7,
			},
		)
	)
	(
		Inventario
		. recoger(
			inventario_pre,
			{
				"id": "caja-casa-reventa",
				"nombre": "Caja guardada",
				"categoria": "hogar",
				"origen": "vida",
				"vendible": true,
				"precio": 5,
			},
		)
	)
	Inventario.guardar_en_casa(inventario_pre, "caja-casa-reventa")
	dia.partida.estado["inventario"] = inventario_pre

	dia._entrar_en("trayecto")
	await process_frame

	var calle := dia._mundo.get_node_or_null("CalleIdentidad") as Node3D
	_comprobar(calle != null, "existe la calle real")
	if calle == null:
		_terminar(dia)
		return

	var comercio := calle.get_node_or_null("ComercioBarrioFisico") as ComercioBarrio3D
	_comprobar(comercio != null, "se monta comercio de barrio fisico")
	if comercio == null:
		_terminar(dia)
		return

	var quiosco := comercio.get_node_or_null("QuioscoAvenida") as Node3D
	var trastero := comercio.get_node_or_null("ElTrastero") as Node3D
	_comprobar(quiosco != null, "Quiosco Avenida existe en calle")
	_comprobar(trastero != null, "El Trastero existe en calle")
	if quiosco == null or trastero == null:
		_terminar(dia)
		return

	_comprobar(
		quiosco.get_node_or_null("RotuloQuioscoAvenida") != null,
		"el quiosco tiene rotulo propio",
	)
	_comprobar(
		trastero.get_node_or_null("RotuloElTrastero") != null,
		"El Trastero tiene rotulo propio",
	)

	var compras_quiosco := (
		quiosco
		. find_children(
			"Comprar_quiosco_*",
			"Interactuable3D",
			true,
			false,
		)
	)
	var compras_trastero := (
		trastero
		. find_children(
			"Comprar_segunda_mano_*",
			"Interactuable3D",
			true,
			false,
		)
	)
	_comprobar(compras_quiosco.size() == 4, "quiosco expone cuatro productos reales")
	_comprobar(compras_trastero.size() == 2, "segunda mano expone dos productos reales")

	var bandeja := trastero.get_node_or_null("BandejaReventa") as Node3D
	_comprobar(bandeja != null, "El Trastero tiene bandeja fisica de reventa")
	var vender_taza: Interactuable3D = null
	if bandeja != null:
		vender_taza = bandeja.get_node_or_null("Vender_taza-reventa") as Interactuable3D
		_comprobar(vender_taza != null, "un objeto carried vendible aparece para reventa")
		_comprobar(
			bandeja.get_node_or_null("Vender_caja-casa-reventa") == null,
			"home_storage no se vende a distancia",
		)

	var fase_inicial := String(dia.jornada.get("fase", ""))
	dia.jornada["dinero"] = 200
	var semillas_antes := SemillasOniricas.familias_activas(dia.jornada)

	var revista := quiosco.get_node_or_null("Comprar_quiosco_revista_umbral_98") as Interactuable3D
	_comprobar(revista != null, "Umbral se compra desde el quiosco fisico")
	if revista != null:
		revista.interactuar(dia._caminante)
		await process_frame

	var inventario = dia.partida.estado.get("inventario", {})
	_comprobar(
		Inventario.contiene(inventario, "revista_umbral_98"),
		"la compra del quiosco entra en Inventario",
	)
	_comprobar(int(dia.jornada["dinero"]) == 192, "el quiosco usa el precio canonico")
	_comprobar(
		SemillasOniricas.familias_activas(dia.jornada) == semillas_antes,
		"comprar una publicacion no activa una semilla",
	)

	var lampara := (
		trastero.get_node_or_null("Comprar_segunda_mano_lampara_verde_usada") as Interactuable3D
	)
	_comprobar(lampara != null, "la lampara se compra desde El Trastero")
	if lampara != null:
		lampara.interactuar(dia._caminante)
		await process_frame

	inventario = dia.partida.estado.get("inventario", {})
	var en_casa := false
	for objeto in inventario.get(Inventario.HOME_STORAGE, []):
		if objeto is Dictionary and String(objeto.get("id", "")) == "lampara_verde_usada":
			en_casa = true
			break
	_comprobar(en_casa, "la lampara comprada se materializa para home_storage")
	_comprobar(int(dia.jornada["dinero"]) == 158, "El Trastero usa el precio canonico")
	_comprobar(
		String(dia.jornada.get("fase", "")) == fase_inicial,
		"comprar en la calle no crea otra fase",
	)

	if vender_taza != null:
		vender_taza.interactuar(dia._caminante)
		await process_frame
	inventario = dia.partida.estado.get("inventario", {})
	_comprobar(
		not Inventario.contiene(inventario, "taza-reventa"),
		"la reventa retira el objeto carried mediante Inventario",
	)
	_comprobar(int(dia.jornada["dinero"]) == 165, "la reventa suma el precio canonico al saldo")
	if vender_taza != null:
		_comprobar(
			not vender_taza.habilitado and not vender_taza.visible,
			"el objeto vendido desaparece de la bandeja",
		)

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
		push_error("FALLO ComercioBarrio676: " + nombre)
