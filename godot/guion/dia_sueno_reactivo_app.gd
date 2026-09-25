## Controller hijo para el corte onírico de #400 / #149 / #87.
##
## Observa el mundo ya construido por Dia y añade dressing solo cuando la fase
## activa es sueño. No cambia la cadena de herencia y no toca el diccionario
## espacial que usa #281. El reconocimiento de una anomalía registra su ID y, si
## existe, el folio ya leído que originó esa aparición.
##
## Tampoco decide el contrato de objetivos: cuando una deformación procede de un
## folio leído hoy, se limita a ofrecerla a la capa de #299, que es quien sabe
## si queda plaza puntuable libre y quién la posee.
extends Node

const IDEOLOGIA_SUENO := preload("res://guion/ideologia_sueno_923.gd")

var _mundo_vestido_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_vestido_id:
		return

	_mundo_vestido_id = mundo_id
	if String(dia.jornada.get("fase", "")) != "sueño":
		return
	var escenas: Array = dia.jornada.get("sueno_escenas", [])
	if escenas.is_empty():
		return

	var cartas_recogidas := []
	var partida_actual = dia.get("partida")
	if partida_actual is Partida:
		for carta in partida_actual.estado.get("tarot", []):
			if not bool(carta.get("recogida", false)):
				continue
			var carta_id := String(carta.get("id", "")).strip_edges()
			if not carta_id.is_empty() and not cartas_recogidas.has(carta_id):
				cartas_recogidas.append(carta_id)

	var modificadores_ideologicos := []
	if partida_actual is Partida:
		var reduccion_movimiento: bool = (
			PreferenciasSiga.cargar().get("reduccion_movimiento", false) == true
		)
		modificadores_ideologicos = (
			IDEOLOGIA_SUENO
			. modificadores(
				partida_actual.estado,
				int(dia.jornada.get("dia", 1)),
				dia._raiz(),
				reduccion_movimiento,
			)
		)

	var anomalias := (
		SuenoUtileria
		. montar(
			mundo,
			String(escenas[0]),
			int(dia.jornada.get("dia", 1)),
			dia._raiz(),
			dia.jornada.get("leido_hoy", []),
			ObjetosOniricos.del_dia(dia.jornada),
			cartas_recogidas,
			modificadores_ideologicos,
		)
	)
	(
		SuenoAtencionDocumental
		. montar(
			mundo,
			String(escenas[0]),
			int(dia.jornada.get("dia", 1)),
			dia._raiz(),
			Meticulosidad.motivos_oniricos(dia.jornada),
		)
	)

	var opciones: Dictionary = dia._opciones_sueno()
	var total_escenas := clampi(
		int(opciones.get("cantidad", Sueno.ESCENAS_POR_NOCHE)),
		1,
		SuenoFormas.ids().size(),
	)
	var indice_escena := MitologiasNoche.indice_escena_actual(total_escenas, escenas.size())
	(
		SuenoRecurrenciaSimbolica
		. montar(
			mundo,
			anomalias,
			indice_escena,
			total_escenas,
			dia._raiz(),
			int(dia.jornada.get("dia", 1)),
		)
	)
	for anomalia in anomalias:
		var documento_origen := String(anomalia.get_meta("documento_origen", ""))
		anomalia.observada.connect(_al_observar_anomalia.bind(documento_origen))

	# La primera deformación que venga de un folio leído hoy ocupa una plaza
	# puntuable de la escena (#299). Si esta noche no hay material documental,
	# la escena conserva sus tres rutas espaciales y aquí no cambia nada.
	for anomalia in anomalias:
		if String(anomalia.get_meta("documento_origen", "")).strip_edges().is_empty():
			continue
		if dia.registrar_objetivo_anomalia_documental(anomalia):
			break


func _al_observar_anomalia(
	anomalia_id: String, _actor: Node, documento_origen: String = ""
) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var partida_actual = dia.get("partida")
	if not partida_actual is Partida:
		return

	var registro := CatalogoAnomalias.registrar(partida_actual.estado, anomalia_id)
	var variante := CatalogoAnomalias.registrar_variante(
		partida_actual.estado, anomalia_id, documento_origen
	)
	var cambio := String(registro.get("resultado", "")) in ["registrada", "reencontrada"]
	cambio = cambio or String(variante.get("resultado", "")) == "variante-registrada"
	# Reconocer la anomalía es también la condición de su plaza onírica cuando
	# nació de un folio: el progreso viaja en el mismo guardado que el catálogo.
	cambio = dia.completar_objetivo_anomalia_documental(anomalia_id, documento_origen) or cambio
	if cambio:
		# Se escribe una sola vez aunque el vistazo descubra a la vez la
		# anomalía base y su variante documental. Repetir ambas no toca disco.
		dia._guardar_o_avisar("")
