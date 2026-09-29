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

const CAPACIDAD_CINTA_SEGUNDOS := 10.0
const ERROR_CAMARA_NO_ADQUIRIDA := "camara_no_adquirida"
const NOMBRE_CAMARA_MUNDO := "CamaraOniricaAdquirible"
const NOMBRE_HUD_CAMARA := "GrabacionOniricaHUD"

var _mundo_vestido_id := 0
var _grabacion_runtime := GrabacionOniricaRuntime.new()
var _anomalia_grabada: AnomaliaSueno3D
var _hud_camara: CanvasLayer
var _hud_metraje: Label


func _process(delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	_actualizar_grabacion(dia, delta)
	_actualizar_hud_camara(dia)
	if dia._mundo == null:
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
			IdeologiaSueno923
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
		if not documento_origen.strip_edges().is_empty():
			anomalia.observada.connect(_al_gestionar_grabacion.bind(anomalia, documento_origen))

	_montar_camara_si_corresponde(dia, mundo, anomalias)

	# La primera deformación que venga de un folio leído hoy ocupa una plaza
	# puntuable de la escena (#299). Si esta noche no hay material documental,
	# la escena conserva sus tres rutas espaciales y aquí no cambia nada.
	for anomalia in anomalias:
		if String(anomalia.get_meta("documento_origen", "")).strip_edges().is_empty():
			continue
		if dia.registrar_objetivo_anomalia_documental(anomalia):
			break


func iniciar_grabacion_anomalia(anomalia: AnomaliaSueno3D) -> Dictionary:
	var dia := get_parent()
	var error := _validar_inicio_grabacion(dia, anomalia)
	if not error.is_empty():
		return {"ok": false, "error": error}

	var partida_actual = dia.get("partida")
	var documento := String(anomalia.get_meta("documento_origen", "")).strip_edges()
	var contenedor := GrabacionOniricaEstado.asegurar_en_estado(partida_actual.estado)
	var cinta = contenedor.get("cinta", {})
	if typeof(cinta) != TYPE_DICTIONARY or cinta.is_empty():
		return {"ok": false, "error": GrabacionOniricaEstado.ERROR_CINTA_NO_INICIADA}

	var caminante = dia.get("_caminante")
	var camara: Camera3D = null
	if caminante != null and is_instance_valid(caminante):
		camara = caminante.get_node_or_null("Camara") as Camera3D
	var inicio := _grabacion_runtime.iniciar(camara, anomalia, documento, true)
	if bool(inicio.get("ok", false)):
		_anomalia_grabada = anomalia
	return inicio


func _validar_inicio_grabacion(dia: Node, anomalia: AnomaliaSueno3D) -> String:
	if dia == null or String(dia.jornada.get("fase", "")) != "sueño":
		return "fuera_de_sueno"
	if not dia.get("partida") is Partida:
		return "partida_no_disponible"
	if not _camara_disponible(dia):
		return ERROR_CAMARA_NO_ADQUIRIDA
	if anomalia == null or not is_instance_valid(anomalia):
		return GrabacionOniricaRuntime.ERROR_SUJETO_INVALIDO

	var documento := String(anomalia.get_meta("documento_origen", "")).strip_edges()
	var leidos = dia.jornada.get("leido_hoy", [])
	if documento.is_empty() or typeof(leidos) != TYPE_ARRAY or not leidos.has(documento):
		return GrabacionOniricaRuntime.ERROR_ORIGINAL_DESCONOCIDO
	return ""


func finalizar_grabacion(
	frase_completa: bool,
	figura_detecto_camara: bool,
) -> Dictionary:
	var dia := get_parent()
	if dia == null:
		return {"ok": false, "error": "dia_no_disponible"}
	var partida_actual = dia.get("partida")
	if not partida_actual is Partida:
		return {"ok": false, "error": "partida_no_disponible"}

	var resultado := (
		_grabacion_runtime
		. finalizar(
			partida_actual.estado,
			frase_completa,
			figura_detecto_camara,
		)
	)
	_anomalia_grabada = null
	if bool(resultado.get("ok", false)):
		dia._guardar_o_avisar("")
	return resultado


func interrumpir_grabacion() -> void:
	_grabacion_runtime.interrumpir()


func grabacion_activa() -> bool:
	return _grabacion_runtime.esta_activa()


func _actualizar_grabacion(dia: Node, delta: float) -> void:
	if not _grabacion_runtime.esta_activa():
		return
	if String(dia.jornada.get("fase", "")) != "sueño":
		_grabacion_runtime.interrumpir()
		finalizar_grabacion(false, false)
		return
	_grabacion_runtime.muestrear(delta)


func _al_gestionar_grabacion(
	_anomalia_id: String,
	_actor: Node,
	anomalia: AnomaliaSueno3D,
	_documento_origen: String,
) -> void:
	# Una anomalía documental no detecta la cámara por sí misma. El primer
	# examen inicia la medición y el segundo del mismo sujeto completa el ciclo.
	# Sin cámara física adquirida, observar sigue funcionando pero no graba.
	var dia := get_parent()
	if dia == null or not _camara_disponible(dia):
		return
	if not _grabacion_runtime.esta_activa():
		iniciar_grabacion_anomalia(anomalia)
		return
	if _anomalia_grabada == anomalia:
		finalizar_grabacion(true, false)
		return

	_grabacion_runtime.interrumpir()
	finalizar_grabacion(false, false)
	iniciar_grabacion_anomalia(anomalia)


func _montar_camara_si_corresponde(dia: Node, mundo: Node3D, anomalias: Array) -> void:
	if _camara_disponible(dia):
		_asegurar_hud_camara()
		return

	var objetivo: AnomaliaSueno3D = null
	for candidato in anomalias:
		if not candidato is AnomaliaSueno3D:
			continue
		var documento := String(candidato.get_meta("documento_origen", "")).strip_edges()
		if documento.is_empty():
			continue
		objetivo = candidato
		break
	if objetivo == null:
		return

	var existente := mundo.get_node_or_null(NOMBRE_CAMARA_MUNDO) as CamaraOnirica3D
	if existente != null:
		return

	var entrada: Vector3 = dia._espacio_actual.get("entrada", Vector3.ZERO)
	var destino := mundo.to_local(objetivo.global_position)
	var direccion := destino - entrada
	direccion.y = 0.0
	if direccion.length_squared() < 0.01:
		direccion = Vector3.RIGHT
	else:
		direccion = direccion.normalized()

	var camara := CamaraOnirica3D.new()
	camara.name = NOMBRE_CAMARA_MUNDO
	camara.position = entrada + direccion * 1.35 + Vector3.UP * 0.62
	camara.activado.connect(_al_recoger_camara.bind(dia, camara))
	mundo.add_child(camara)


func _al_recoger_camara(_actor: Node, dia: Node, camara: CamaraOnirica3D) -> void:
	if dia == null or String(dia.jornada.get("fase", "")) != "sueño":
		return
	var partida_actual = dia.get("partida")
	if not partida_actual is Partida:
		return

	var contenedor := GrabacionOniricaEstado.asegurar_en_estado(partida_actual.estado)
	var cinta = contenedor.get("cinta", {})
	var creada := false
	if typeof(cinta) != TYPE_DICTIONARY or cinta.is_empty():
		GrabacionOniricaEstado.iniciar_cinta(partida_actual.estado, CAPACIDAD_CINTA_SEGUNDOS)
		creada = true

	_asegurar_hud_camara()
	_actualizar_hud_camara(dia)
	if is_instance_valid(camara):
		camara.habilitado = false
		camara.queue_free()
	if creada:
		dia._guardar_o_avisar("")


func _camara_disponible(dia: Node) -> bool:
	if dia == null:
		return false
	var partida_actual = dia.get("partida")
	if not partida_actual is Partida:
		return false
	var contenedor := GrabacionOniricaEstado.asegurar_en_estado(partida_actual.estado)
	var cinta = contenedor.get("cinta", {})
	return typeof(cinta) == TYPE_DICTIONARY and not cinta.is_empty()


func _asegurar_hud_camara() -> void:
	if is_instance_valid(_hud_camara):
		return

	_hud_camara = CanvasLayer.new()
	_hud_camara.name = NOMBRE_HUD_CAMARA
	_hud_camara.layer = 18
	add_child(_hud_camara)

	var superficie := Control.new()
	superficie.name = "Superficie"
	superficie.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	superficie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_camara.add_child(superficie)

	for datos in [
		[Vector2(-26.0, -1.0), Vector2(52.0, 2.0)],
		[Vector2(-1.0, -26.0), Vector2(2.0, 52.0)],
	]:
		var trazo := ColorRect.new()
		trazo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trazo.position = superficie.get_viewport_rect().size * 0.5 + datos[0]
		trazo.size = datos[1]
		superficie.add_child(trazo)

	_hud_metraje = Label.new()
	_hud_metraje.name = "Metraje"
	_hud_metraje.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_hud_metraje.offset_left = -190.0
	_hud_metraje.offset_top = 28.0
	_hud_metraje.offset_right = -28.0
	_hud_metraje.offset_bottom = 70.0
	_hud_metraje.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_metraje.mouse_filter = Control.MOUSE_FILTER_IGNORE
	superficie.add_child(_hud_metraje)


func _actualizar_hud_camara(dia: Node) -> void:
	var visible := (
		dia != null and String(dia.jornada.get("fase", "")) == "sueño" and _camara_disponible(dia)
	)
	if not visible:
		if is_instance_valid(_hud_camara):
			_hud_camara.visible = false
		return

	_asegurar_hud_camara()
	_hud_camara.visible = true
	if not is_instance_valid(_hud_metraje):
		return

	var partida_actual = dia.get("partida")
	var contenedor := GrabacionOniricaEstado.asegurar_en_estado(partida_actual.estado)
	var cinta: Dictionary = contenedor.get("cinta", {})
	var restante := maxf(float(cinta.get("metraje_restante", 0.0)), 0.0)
	_hud_metraje.text = "%s %.1f s" % ["●" if grabacion_activa() else "○", restante]


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
