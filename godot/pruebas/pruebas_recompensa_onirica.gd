extends SceneTree

const RUTA := "user://prueba_recompensa_onirica_61_97.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar()
	call_deferred("_probar")


func _probar() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var jornada: Dictionary = partida.estado["jornada"]
	var dinero_antes := int(jornada["dinero"])
	var acciones_antes := int(jornada["acciones"])

	_comprobar(
		RecompensaOnirica.conceder(partida.estado),
		"un puzzle válido puede materializar la recompensa física",
	)
	var inventario: Dictionary = partida.estado["inventario"]
	_comprobar(
		Inventario.contiene(inventario, RecompensaOnirica.ID),
		"la recompensa aparece en el inventario real",
	)
	_comprobar(
		inventario[Inventario.CARRIED].size() == 1,
		"la recompensa sale del sueño directamente a carried",
	)
	var objeto := _buscar(inventario, RecompensaOnirica.ID)
	_comprobar(String(objeto.get("origen", "")) == "sueno", "conserva origen onírico")
	_comprobar(not bool(objeto.get("vendible", true)), "la recompensa no se declara vendible")
	_comprobar(int(objeto.get("precio", -1)) == 0, "la recompensa no tiene valor monetario")
	_comprobar(
		objeto.get("usos", []).has("forzar"),
		"la recompensa aporta un uso semántico jugable",
	)
	_comprobar(
		not RecompensaOnirica.conceder(partida.estado),
		"resolver otra vez no duplica la recompensa",
	)
	_comprobar(
		inventario[Inventario.CARRIED].size() == 1,
		"la idempotencia conserva una única instancia",
	)

	var venta := Inventario.vender(inventario, RecompensaOnirica.ID)
	_comprobar(not bool(venta.get("vendido", true)), "el objeto onírico no se puede vender")
	_comprobar(String(venta.get("motivo", "")) == "onirico", "la venta explica el bloqueo onírico")
	_comprobar(int(venta.get("dinero", -1)) == 0, "rechazar la venta nunca concede dinero")
	_comprobar(
		Inventario.contiene(inventario, RecompensaOnirica.ID),
		"la venta rechazada conserva la recompensa",
	)
	_comprobar(int(jornada["dinero"]) == dinero_antes, "conceder no modifica el saldo")
	_comprobar(int(jornada["acciones"]) == acciones_antes, "conceder no regala acciones")

	_comprobar(partida.guardar(RUTA), "la partida con recompensa onírica se guarda")
	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA)
	_comprobar(carga.get("resultado", "") == "cargada", "la partida con recompensa recarga")
	var inventario_recargado: Dictionary = recargada.estado["inventario"]
	_comprobar(
		Inventario.contiene(inventario_recargado, RecompensaOnirica.ID),
		"la recompensa sobrevive al guardado y recarga",
	)
	var objeto_recargado := _buscar(inventario_recargado, RecompensaOnirica.ID)
	_comprobar(
		objeto_recargado.get("usos", []).has("forzar"),
		"la recarga conserva el beneficio semántico",
	)

	# Beneficio real: la misma persiana de #680 busca el uso, no un ID concreto.
	# La cuña puede resolverla como alternativa a la palanca CC0.
	var jornada_recargada: Dictionary = recargada.estado["jornada"]
	var estado_imprevistos := Imprevistos.completar(jornada_recargada)
	estado_imprevistos["consecuencias"] = [PersianaAtascada3D.CONSECUENCIA]
	var saldo_previo := int(jornada_recargada["dinero"])
	var acciones_previas := int(jornada_recargada["acciones"])

	var persiana := PersianaAtascada3D.new()
	root.add_child(persiana)
	persiana.configurar(jornada_recargada, inventario_recargado)
	var herramienta := persiana.herramienta_disponible()
	_comprobar(
		String(herramienta.get("id", "")) == RecompensaOnirica.ID,
		"una interacción existente reconoce la recompensa por su uso",
	)
	_comprobar(persiana.interactuar(root), "la recompensa permite forzar la persiana")
	_comprobar(
		not Imprevistos.consecuencias(jornada_recargada).has(PersianaAtascada3D.CONSECUENCIA),
		"el beneficio resuelve una consecuencia real",
	)
	_comprobar(
		Inventario.contiene(inventario_recargado, RecompensaOnirica.ID),
		"usar la herramienta onírica no la consume implícitamente",
	)
	_comprobar(
		int(jornada_recargada["dinero"]) == saldo_previo,
		"el beneficio contextual no modifica dinero",
	)
	_comprobar(
		int(jornada_recargada["acciones"]) == acciones_previas,
		"el beneficio contextual no modifica acciones",
	)

	persiana.queue_free()
	await process_frame
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _buscar(inventario: Dictionary, objeto_id: String) -> Dictionary:
	for objeto in Inventario.visibles(inventario, true):
		if objeto is Dictionary and String(objeto.get("id", "")) == objeto_id:
			return objeto
	return {}


func _limpiar() -> void:
	for ruta in [RUTA, RUTA + ".nuevo", RUTA + ".roto"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO RecompensaOnirica: " + nombre)
