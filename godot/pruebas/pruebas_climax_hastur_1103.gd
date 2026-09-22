## Regresión ejecutable del primer vertical del clímax de Hastur (#1103).
extends SceneTree

var _pasadas := 0
var _fallos := 0


class HandoffDoble:
	extends Node
	signal climax_hastur_pendiente(contexto: Dictionary)


class DiaDoble:
	extends Node

	var partida := Partida.new()
	var jornada: Dictionary = {}
	var historias := Historias.new()
	var guardados := 0
	var _pantalla = null
	var _caminante = null

	func _init() -> void:
		partida.estado = Partida.nueva()
		jornada = partida.estado["jornada"]
		jornada["raiz"] = 1103
		jornada["vuelta"] = 1

	func _guardar_o_avisar(_destino: String) -> bool:
		guardados += 1
		return true

	func _cerrar_expediente() -> void:
		_pantalla = null


func _init() -> void:
	_persistencia_y_vuelta()
	_dificultad()
	_victoria_determinista()
	_derrota_idempotente()
	_ultimo_recurso_en_climax()
	_ruta_handoff_a_panel()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _persistencia_y_vuelta() -> void:
	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	jornada["raiz"] = 41
	jornada["vuelta"] = 3
	var contexto := {"climax_hastur_pendiente": true}

	var primero := ClimaxHastur.iniciar(estado, jornada, contexto)
	_comprobar(primero["resultado"] == "iniciado", "el primer handoff inicia")
	var ronda_antes := int(estado[ClimaxHastur.CLAVE_ESTADO]["combate"]["ronda"])

	var recargado: Dictionary = JSON.parse_string(JSON.stringify(estado))
	var jornada_recargada: Dictionary = recargado["jornada"]
	var segundo := ClimaxHastur.iniciar(recargado, jornada_recargada, contexto)
	_comprobar(segundo["resultado"] == "reanudado", "recargar no duplica el clímax")
	_comprobar(
		int(recargado[ClimaxHastur.CLAVE_ESTADO]["combate"]["ronda"]) == ronda_antes,
		"recargar conserva la ronda",
	)

	jornada_recargada["vuelta"] = 4
	var nueva_vuelta := ClimaxHastur.iniciar(recargado, jornada_recargada, contexto)
	_comprobar(nueva_vuelta["resultado"] == "iniciado", "una vuelta nueva empieza limpia")
	_comprobar(
		int(recargado[ClimaxHastur.CLAVE_ESTADO]["intentos"]) == 1,
		"la vuelta nueva no hereda intentos",
	)


func _dificultad() -> void:
	for caso in [
		["facil", 2],
		["normal", 3],
		["dificil", 4],
	]:
		var estado := Partida.nueva()
		estado["dificultad"] = caso[0]
		var jornada: Dictionary = estado["jornada"]
		jornada["raiz"] = 99
		(
			ClimaxHastur
			. iniciar(
				estado,
				jornada,
				{"climax_hastur_pendiente": true},
			)
		)
		_comprobar(
			int(estado[ClimaxHastur.CLAVE_ESTADO]["combate"]["vida_rival"]) == caso[1],
			"la dificultad ajusta la resistencia: %s" % caso[0],
		)


func _victoria_determinista() -> void:
	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	jornada["raiz"] = 7
	estado["historias_cartas"] = {
		"a": "comunismo",
		"b": "comunismo",
		"c": "centrista",
	}
	(
		ClimaxHastur
		. iniciar(
			estado,
			jornada,
			{"climax_hastur_pendiente": true},
		)
	)

	for jugada in ["insistencia", "objecion", "silencio"]:
		ClimaxHastur.jugar(estado, jornada, jugada)

	var actual := ClimaxHastur.estado_actual(estado, jornada)
	_comprobar(
		actual["fase"] == ClimaxHastur.FASE_VICTORIA,
		"la secuencia ganadora es determinista",
	)
	_comprobar(
		ClimaxHastur.confirmar_victoria(estado, jornada),
		"la victoria confirma el veredicto",
	)
	var contrato := ClimaxHastur.contrato_final(estado, jornada)
	_comprobar(bool(contrato["pendiente"]), "la victoria entrega el final político")
	_comprobar(
		contrato["veredicto"] == ClimaxHastur.VEREDICTO_HASTUR,
		"el final recibe el veredicto del clímax",
	)
	_comprobar(
		contrato["ejes_dominantes"] == ["comunismo"],
		"el final reutiliza el recuento político vigente",
	)


func _derrota_idempotente() -> void:
	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	jornada["raiz"] = 8
	(
		ClimaxHastur
		. iniciar(
			estado,
			jornada,
			{"climax_hastur_pendiente": true},
		)
	)

	for jugada in ["silencio", "insistencia", "objecion"]:
		ClimaxHastur.jugar(estado, jornada, jugada)

	_comprobar(
		ClimaxHastur.estado_actual(estado, jornada)["fase"] == ClimaxHastur.FASE_DERROTA,
		"la secuencia perdedora es determinista",
	)
	var vida_antes := int(estado["vida"])
	var consecuencia := ClimaxHastur.aplicar_derrota(estado, jornada)
	_comprobar(consecuencia["resultado"] == "reintento", "perder permite reintento con vida")
	_comprobar(int(estado["vida"]) == vida_antes - 1, "la derrota cobra una sola vida")
	var vida_despues := int(estado["vida"])
	ClimaxHastur.aplicar_derrota(estado, jornada)
	_comprobar(int(estado["vida"]) == vida_despues, "repetir señal no cobra dos veces")
	_comprobar(
		int(ClimaxHastur.estado_actual(estado, jornada)["intentos"]) == 2,
		"el reintento queda persistido",
	)


func _ultimo_recurso_en_climax() -> void:
	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	jornada["raiz"] = 1205
	estado["vida"] = 1
	ClimaxHastur.iniciar(
		estado,
		jornada,
		{"climax_hastur_pendiente": true},
	)
	var actual := ClimaxHastur.estado_actual(estado, jornada)
	actual["fase"] = ClimaxHastur.FASE_DERROTA

	var consecuencia := ClimaxHastur.aplicar_derrota(estado, jornada)
	_comprobar(
		consecuencia["resultado"] == "ultimo_recurso",
		"la última derrota espera una decisión",
	)
	_comprobar(int(estado["vida"]) == 0, "el clímax conserva vida cero")
	_comprobar(Acusacion.despido_pendiente(estado), "el clímax persiste la frontera")
	_comprobar(
		actual["fase"] == ClimaxHastur.FASE_INTERRUMPIDO,
		"el combate queda interrumpido mientras se decide",
	)

	var canje := Acusacion.canjear_carta_por_vida(estado, "el-loco")
	_comprobar(canje["resultado"] == "canje", "el tarot puede salvar el clímax")
	_comprobar(
		ClimaxHastur.reanudar_tras_ultimo_recurso(estado, jornada),
		"el canje rearma el mismo clímax",
	)
	_comprobar(
		actual["fase"] == ClimaxHastur.FASE_COMBATE,
		"el combate vuelve a fase jugable",
	)
	_comprobar(int(jornada["vuelta"]) == 1, "el canje no inicia otra vuelta")

	var cesado := Partida.nueva()
	var jornada_cese: Dictionary = cesado["jornada"]
	jornada_cese["raiz"] = 1206
	cesado["vida"] = 1
	ClimaxHastur.iniciar(
		cesado,
		jornada_cese,
		{"climax_hastur_pendiente": true},
	)
	ClimaxHastur.estado_actual(cesado, jornada_cese)["fase"] = ClimaxHastur.FASE_DERROTA
	ClimaxHastur.aplicar_derrota(cesado, jornada_cese)
	var cese := Acusacion.aceptar_cese(cesado, jornada_cese)
	_comprobar(bool(cese["despido"]), "aceptar el cese sí termina el clímax")
	_comprobar(int(jornada_cese["vuelta"]) == 2, "el cese abre una vuelta nueva")


func _ruta_handoff_a_panel() -> void:
	var dia := DiaDoble.new()
	get_root().add_child(dia)

	var handoff := HandoffDoble.new()
	handoff.name = "ClimaxOs98Controller"
	dia.add_child(handoff)

	var owner: Node = load("res://guion/dia_climax_hastur_app.gd").new()
	owner.name = "ClimaxHasturOwnerController"
	dia.add_child(owner)
	owner.call("_conectar_handoff")

	handoff.climax_hastur_pendiente.emit({"climax_hastur_pendiente": true})
	_comprobar(dia.guardados == 1, "el handoff persiste antes de presentar")
	_comprobar(
		dia.get_node_or_null("ClimaxHasturCapa") != null,
		"la ruta automatizada alcanza la escena de confrontación",
	)
	_comprobar(
		not ClimaxHastur.estado_actual(dia.partida.estado, dia.jornada).is_empty(),
		"la escena usa estado de campaña persistente",
	)
	dia.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		printerr("FALLO: %s" % nombre)
