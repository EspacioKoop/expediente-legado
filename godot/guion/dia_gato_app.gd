## Capa de presentación del gato compartido entre casa, SIGA y sueño (#92).
##
## Conserva la herencia histórica directa desde alquiler y compone aquí el
## primer vertical de objetivos oníricos (#299), evitando alterar el contrato
## estructural comprobado por las regresiones existentes.
extends "res://guion/dia_trabajillos_app.gd"

const TAM_OBJETIVO := Vector3(2.8, 2.4, 2.8)
const DEMORA_RESOLUCION := 0.35

## Margen que se deja entre el conjunto y el primer botón de acción del visor
## al calcular si el anclaje por defecto (#285) invade la barra de acciones.
const MARGEN_BOTONES_ASISTENTE := 12.0

## Clave de #285: la posición elegida por el jugador arrastrando al gato
## persiste en preferencias, no en la partida, porque es presentación pura.
const CLAVE_POSICION_ASISTENTE := "posicion_asistente_gato"

var _gato_guia: Gato
var _entrada_guia := Vector3.ZERO
var _salida_guia := Vector3.ZERO
var _hay_rumbo_guia := false
var _objetivos_espacio: Array = []
var _objetivo_escena := ""
var _resolviendo_objetivos := false
var _asistente_siga_caja: VBoxContainer
var _asistente_siga_conjunto: Control
var _arrastrando_asistente := false
var _arrastre_asistente_offset := Vector2.ZERO


func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	_hay_rumbo_guia = false
	_objetivos_espacio = []
	_objetivo_escena = ""
	if fase != "sueño":
		return espacio

	# Mantener esta lectura conserva el contrato histórico de la guía (#92),
	# aunque la salida deje de ser el mecanismo normal de progreso en #299.
	var salidas: Array = espacio.get("salidas", [])
	if jornada.get("sueno_escenas", []).is_empty():
		return espacio

	_objetivo_escena = String(jornada["sueno_escenas"][0])
	var foco: Vector3 = espacio.get("entrada", Vector3.ZERO)
	if not salidas.is_empty():
		foco = salidas[0].get("pos", foco)
	espacio["salidas"] = []

	var posiciones: Array = _posiciones_objetivo(espacio, foco)
	for i in SuenoObjetivos.POSIBLES_PRIMER_CORTE:
		(
			_objetivos_espacio
			. append(
				{
					"id": "%s:%d" % [_objetivo_escena, i],
					"pos": posiciones[i],
				}
			)
		)

	if not _objetivos_espacio.is_empty():
		_entrada_guia = espacio.get("entrada", Vector3.ZERO)
		_salida_guia = _objetivos_espacio[0].get("pos", _entrada_guia)
		_hay_rumbo_guia = true
	return espacio


func _entrar_en(fase: String) -> void:
	# Cada entrada arranca fuera de una transición. Los callbacks retrasados de
	# la escena anterior solo podrán actuar si el nuevo estado vuelve a cumplir
	# el contrato de resolución, nunca por arrastrar un cerrojo viejo.
	_resolviendo_objetivos = false
	super._entrar_en(fase)
	_gato_guia = null
	if fase == "casa" and is_instance_valid(_gato):
		_gato.actualizar_hambre(int(jornada.get("gato", {}).get("dias_sin_comer", 0)))
		_gato.configurar_reduccion_movimiento(_reduccion_movimiento_gato())
		_gato.activado.connect(_al_activar_gato.bind(_gato))
	if fase == "sueño":
		_montar_objetivos_sueno()
		_montar_guia_sueno()


func _reduccion_movimiento_gato() -> bool:
	return bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))


## La interacción 3D del gato deja una huella concreta del día: se guarda qué
## gesto ocurrió para que el sueño pueda recordarlo sin convertirlo en puntos.
func _al_activar_gato(_actor: Node, gato: Gato) -> void:
	if jornada.get("fase", "") != "casa":
		return
	if gato.verbo == Interactuable3D.Verbo.DAR:
		_dar_de_comer()
		gato.actualizar_hambre(int(jornada.get("gato", {}).get("dias_sin_comer", 0)))
		return
	var accion := GatoEcoSueno.accion_de_verbo(gato.verbo)
	GatoEcoSueno.registrar(jornada.get("gato", {}), int(jornada.get("dia", 0)), accion)


## Intercepta también el cuenco histórico: alimentar desde el gato o pisando el
## cuenco es la misma acción y solo se registra si el hambre realmente pasa a 0.
func _dar_de_comer() -> void:
	var hambre_antes := int(jornada.get("gato", {}).get("dias_sin_comer", 0))
	super._dar_de_comer()
	var hambre_despues := int(jornada.get("gato", {}).get("dias_sin_comer", 0))
	if hambre_antes > 0 and hambre_despues == 0:
		GatoEcoSueno.registrar(
			jornada.get("gato", {}), int(jornada.get("dia", 0)), GatoEcoSueno.ALIMENTAR
		)


func _posiciones_objetivo(espacio: Dictionary, foco: Vector3) -> Array:
	var posiciones: Array = []
	var bloques: Array = espacio.get("planta", [])
	if not bloques.is_empty():
		for celda in Planta.repartidas(bloques, SuenoObjetivos.POSIBLES_PRIMER_CORTE, []):
			posiciones.append(Planta.centro_en_metros(bloques, celda) + Vector3(0, 1.0, 0))
	while posiciones.size() < SuenoObjetivos.POSIBLES_PRIMER_CORTE:
		posiciones.append(foco)

	var figuras: Array = espacio.get("figuras", [])
	if not figuras.is_empty():
		posiciones[0] = figuras[0].get("pos", posiciones[0]) + Vector3(0, 1.0, 0)
	var carteles: Array = espacio.get("carteles", [])
	if not carteles.is_empty():
		posiciones[1] = carteles[0].get("pos", posiciones[1]) + Vector3(0, 1.0, 0)
	posiciones[2] = foco
	return posiciones


func _clave_objetivos_actual() -> String:
	return "%d:%s" % [int(jornada.get("dia", 0)), _objetivo_escena]


func _estado_objetivos_actual() -> Dictionary:
	if not jornada.has("sueno_objetivos"):
		jornada["sueno_objetivos"] = {}
	var estados: Dictionary = jornada["sueno_objetivos"]
	var clave: String = _clave_objetivos_actual()
	if not estados.has(clave):
		var ids: Array = _objetivos_espacio.map(func(objetivo): return objetivo["id"])
		estados[clave] = SuenoObjetivos.nuevo(ids)
	return estados[clave]


func _montar_objetivos_sueno() -> void:
	if _objetivos_espacio.is_empty():
		return
	var estado: Dictionary = _estado_objetivos_actual()
	var completados: Array = estado.get("completados", [])
	_actualizar_feedback_objetivos(SuenoObjetivos.progreso(estado))
	_actualizar_rumbo_guia_pendiente(estado)
	for objetivo in _objetivos_espacio:
		var objetivo_id := String(objetivo.get("id", ""))
		if completados.has(objetivo_id) or not _objetivo_puntuable(estado, objetivo_id):
			continue
		# Una plaza de solo guía se completa por su propia interacción, no por
		# pisarla: montarle una zona daría dos condiciones al mismo objetivo.
		if bool(objetivo.get("solo_guia", false)):
			continue
		var zona := Area3D.new()
		zona.name = "ObjetivoSueno_%s" % objetivo_id
		zona.position = objetivo["pos"]
		zona.set_meta("objetivo", objetivo_id)
		var colision := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = TAM_OBJETIVO
		colision.shape = caja
		zona.add_child(colision)
		_mundo.add_child(zona)
		zona.body_entered.connect(_al_pisar_objetivo.bind(zona))
	if SuenoObjetivos.resuelto(estado):
		call_deferred("_resolver_objetivos_sueno")


func _al_pisar_objetivo(cuerpo: Node3D, zona: Area3D) -> void:
	if cuerpo != _caminante or jornada.get("fase", "") != "sueño" or _pantalla != null:
		return
	var estado: Dictionary = _estado_objetivos_actual()
	var id := String(zona.get_meta("objetivo", ""))
	if not SuenoObjetivos.completar(estado, id):
		return
	# body_entered se emite durante físicas; diferir permite desactivar la zona.
	zona.set_deferred("monitoring", false)

	_tras_cambio_objetivo(estado, true)


func _tras_cambio_objetivo(estado: Dictionary, guardar_si_pendiente: bool) -> void:
	var progreso: Vector2i = SuenoObjetivos.progreso(estado)
	if _ambiente != null:
		_ambiente.ambient_light_energy = minf(_ambiente.ambient_light_energy + 0.14, 1.5)
	_actualizar_feedback_objetivos(progreso)
	_actualizar_rumbo_guia_pendiente(estado)
	_orientar_gato_guia()
	if not SuenoObjetivos.resuelto(estado):
		if guardar_si_pendiente:
			_guardar_o_avisar("")
		return

	if is_instance_valid(_caminante):
		_caminante.set_physics_process(false)
	get_tree().create_timer(DEMORA_RESOLUCION).timeout.connect(_resolver_objetivos_sueno)


func _actualizar_feedback_objetivos(progreso: Vector2i) -> void:
	var marcas := []
	for i in progreso.y:
		marcas.append("◆" if i < progreso.x else "◇")
	_rotulo.text = "  ".join(marcas)


func _actualizar_rumbo_guia_pendiente(estado: Dictionary) -> void:
	var completados: Array = estado.get("completados", [])
	_hay_rumbo_guia = false
	for objetivo in _objetivos_espacio:
		var objetivo_id := String(objetivo.get("id", ""))
		if completados.has(objetivo_id) or not _objetivo_puntuable(estado, objetivo_id):
			continue
		_salida_guia = objetivo.get("pos", _entrada_guia)
		_hay_rumbo_guia = true
		return


func _objetivo_puntuable(estado: Dictionary, objetivo_id: String) -> bool:
	for objetivo in estado.get("objetivos", []):
		if String(objetivo.get("id", "")) == objetivo_id:
			return bool(objetivo.get("cuenta", true))
	return true


func _orientar_gato_guia() -> void:
	if not is_instance_valid(_gato_guia) or not _hay_rumbo_guia:
		return
	var rumbo := _salida_guia - _entrada_guia
	rumbo.y = 0.0
	if rumbo.length() < 0.01:
		return
	var direccion := rumbo.normalized()
	if GatoAyuda.guia_orienta(jornada.get("gato", {})):
		_gato_guia.rotation.y = atan2(direccion.x, direccion.z) + PI


func _resolver_objetivos_sueno() -> void:
	# Un timer y un call_deferred pueden coincidir tras recargar una escena ya
	# resuelta. Solo el primer callback puede consumir la cola de escenas.
	if _resolviendo_objetivos:
		return
	if jornada.get("fase", "") != "sueño" or _objetivo_escena.is_empty():
		return
	var estado: Dictionary = _estado_objetivos_actual()
	if not SuenoObjetivos.resuelto(estado):
		return

	_resolviendo_objetivos = true
	# Resolver cambia varias piezas a la vez (cola, fase y día). Si el guardado
	# falla, restauramos exactamente el estado anterior: quedarse visualmente en
	# la escena vieja con la cola ya consumida haría que un reintento saltase una
	# segunda escena y es precisamente el softlock que #299 quiere evitar.
	var jornada_antes := jornada.duplicate(true)
	jornada["sueno_escenas"].pop_front()
	var destino := "sueño"
	var dia_nuevo := -1
	if jornada["sueno_escenas"].is_empty():
		_registrar_despertar_reglamentario()
		dia_nuevo = Jornada.despertar(jornada)
		destino = "archivo"
	if not _guardar_o_avisar(destino):
		jornada.clear()
		jornada.merge(jornada_antes, true)
		_resolviendo_objetivos = false
		_caminante.set_physics_process(true)
		return
	if dia_nuevo >= 0:
		_hablando = false
		_nomina.text = tr("DIA_NUEVO") % dia_nuevo
	_entrar_en(destino)
	_caminante.set_physics_process(true)


## Integra un puzzle ya montado en la progresión normal de #281. Sustituye una
## de las tres plazas espaciales por el puzzle, manteniendo el umbral 2/3. Si
## falla o se abandona, quedan dos rutas espaciales puntuables y nunca bloquea.
func registrar_objetivo_puzzle_onirico(nucleo) -> bool:
	if nucleo == null or String(jornada.get("fase", "")) != "sueño" or _objetivo_escena.is_empty():
		return false
	var puzzle_id := String(nucleo.puzzle_id)
	var reward_id := String(nucleo.reward_id)
	if puzzle_id.is_empty() or reward_id.is_empty() or _objetivos_espacio.is_empty():
		return false

	var estado: Dictionary = _estado_objetivos_actual()
	var objetivo_id := _id_objetivo_puzzle_onirico(puzzle_id, reward_id)
	for indice in range(_objetivos_espacio.size() - 1, -1, -1):
		var reemplazo_id := String(_objetivos_espacio[indice].get("id", ""))
		if reemplazo_id.is_empty():
			continue
		if not (
			SuenoObjetivos
			. sustituir_puntuable(
				estado,
				{
					"id": objetivo_id,
					"tipo": "pista_onirica",
					"condicion": "resolver",
					"feedback": "pista",
					"cuenta": true,
				},
				reemplazo_id,
			)
		):
			continue
		_retirar_objetivo_espacial(reemplazo_id)
		_actualizar_feedback_objetivos(SuenoObjetivos.progreso(estado))
		_actualizar_rumbo_guia_pendiente(estado)
		_orientar_gato_guia()
		return true
	return false


func _retirar_objetivo_espacial(objetivo_id: String) -> void:
	for indice in range(_objetivos_espacio.size() - 1, -1, -1):
		if String(_objetivos_espacio[indice].get("id", "")) == objetivo_id:
			_objetivos_espacio.remove_at(indice)
	if not is_instance_valid(_mundo):
		return
	for hijo in _mundo.get_children():
		if not (hijo is Area3D):
			continue
		if String(hijo.get_meta("objetivo", "")) != objetivo_id:
			continue
		hijo.set_deferred("monitoring", false)
		hijo.queue_free()


func _id_objetivo_puzzle_onirico(puzzle_id: String, reward_id: String) -> String:
	return "pista:%s:%s" % [puzzle_id, reward_id]


## Una anomalía deformada a partir de un folio leído ESE día (#87) ocupa una de
## las tres plazas puntuables de la escena: es el objetivo "derivado de contenido
## leído hoy" que pedía el primer vertical de #299 y que hasta ahora no existía.
##
## No inventa nada del expediente, porque el folio ya se leyó y la ficha ya está
## catalogada; lo único que cambia es qué cuenta para el umbral. Y a diferencia
## del puzzle opcional, observar una anomalía no tiene ruta de fallo, así que
## ocupar la plaza nunca puede dejar la escena sin objetivos suficientes.
func registrar_objetivo_anomalia_documental(anomalia) -> bool:
	if anomalia == null or String(jornada.get("fase", "")) != "sueño":
		return false
	if _objetivo_escena.is_empty() or _objetivos_espacio.is_empty():
		return false
	var anomalia_id := String(anomalia.id_catalogo())
	var folio := String(anomalia.get_meta("documento_origen", "")).strip_edges()
	if anomalia_id.is_empty() or folio.is_empty():
		return false

	var estado: Dictionary = _estado_objetivos_actual()
	var objetivo_id := _id_objetivo_anomalia_documental(anomalia_id, folio)
	for indice in range(_objetivos_espacio.size() - 1, -1, -1):
		var candidato: Dictionary = _objetivos_espacio[indice]
		if bool(candidato.get("solo_guia", false)):
			continue
		var reemplazo_id := String(candidato.get("id", ""))
		if reemplazo_id.is_empty():
			continue
		if not (
			SuenoObjetivos
			. sustituir_puntuable(
				estado,
				{
					"id": objetivo_id,
					"tipo": "anomalia",
					"condicion": "observar",
					"feedback": "ambiente",
					"cuenta": true,
				},
				reemplazo_id,
			)
		):
			continue
		_retirar_objetivo_espacial(reemplazo_id)
		_apuntar_guia_a_anomalia(objetivo_id, anomalia)
		_actualizar_feedback_objetivos(SuenoObjetivos.progreso(estado))
		_actualizar_rumbo_guia_pendiente(estado)
		_orientar_gato_guia()
		return true
	return false


## Observar la anomalía cierra su plaza una sola vez. El guardado lo decide quien
## registra el catálogo, para que reconocimiento y progreso compartan escritura.
func completar_objetivo_anomalia_documental(anomalia_id: String, documento_origen: String) -> bool:
	if String(jornada.get("fase", "")) != "sueño" or _objetivo_escena.is_empty():
		return false
	var folio := documento_origen.strip_edges()
	if anomalia_id.strip_edges().is_empty() or folio.is_empty():
		return false
	var estado: Dictionary = _estado_objetivos_actual()
	var objetivo_id := _id_objetivo_anomalia_documental(anomalia_id.strip_edges(), folio)
	if not SuenoObjetivos.completar(estado, objetivo_id):
		return false
	_retirar_objetivo_espacial(objetivo_id)
	_tras_cambio_objetivo(estado, false)
	return true


## La plaza documental no monta zona pisable, pero sí deja una entrada de solo
## guía: así el gato de #92 sigue orientando hacia un objetivo pendiente real en
## lugar de hacia una plaza que acaba de dejar de puntuar.
func _apuntar_guia_a_anomalia(objetivo_id: String, anomalia: Node3D) -> void:
	for objetivo in _objetivos_espacio:
		if String(objetivo.get("id", "")) == objetivo_id:
			return
	(
		_objetivos_espacio
		. append(
			{
				"id": objetivo_id,
				"pos": anomalia.global_position,
				"solo_guia": true,
			}
		)
	)


## El folio forma parte del id: la misma noche reconstruye la misma plaza y dos
## documentos distintos no comparten objetivo aunque deformen el mismo objeto.
func _id_objetivo_anomalia_documental(anomalia_id: String, folio: String) -> String:
	return "anomalia:%s:%s" % [anomalia_id, folio]


func _actualizar_objetivo_puzzle_onirico(resultado: Dictionary) -> bool:
	if String(jornada.get("fase", "")) != "sueño" or _objetivo_escena.is_empty():
		return false
	var puzzle_id := String(resultado.get("puzzle_id", ""))
	var reward_id := String(resultado.get("reward_id", ""))
	if puzzle_id.is_empty() or reward_id.is_empty():
		return false
	var estado: Dictionary = _estado_objetivos_actual()
	var objetivo_id := _id_objetivo_puzzle_onirico(puzzle_id, reward_id)
	var resultado_estado := String(resultado.get("state", ""))
	if resultado_estado == PuzzleOnirico.ESTADO_COMPLETADO:
		if not SuenoObjetivos.completar(estado, objetivo_id):
			return false
		_tras_cambio_objetivo(estado, false)
		return true
	if (
		resultado_estado == PuzzleOnirico.ESTADO_FALLADO
		or resultado_estado == PuzzleOnirico.ESTADO_ABANDONADO
	):
		return SuenoObjetivos.fallar(estado, objetivo_id)
	return false


## Enlaza un núcleo de puzzle concreto con la recompensa persistente de #89.
## La UI decide cuándo crear/mostrar el puzzle; esta capa solo posee el estado y
## el guardado. Conectar dos veces el mismo núcleo no duplica el callback.
func conectar_recompensa_onirica(nucleo, caso: Dictionary) -> bool:
	if nucleo == null or not nucleo.has_signal("resultado"):
		return false
	var callback := _al_resultado_puzzle_onirico.bind(caso)
	if nucleo.resultado.is_connected(callback):
		return true
	nucleo.resultado.connect(callback)
	return true


## Solo un resultado completado y catalogado puede llegar a persistencia.
## `registrar()` muta primero memoria de forma idempotente; si el disco falla,
## `_guardar_o_avisar` deja el mismo estado pendiente para que el mecanismo
## normal de reintento lo escriba sin volver a conceder la pista.
func _al_resultado_puzzle_onirico(resultado: Dictionary, caso: Dictionary) -> void:
	var resultado_estado := String(resultado.get("state", ""))
	if resultado_estado != PuzzleOnirico.ESTADO_COMPLETADO:
		if _actualizar_objetivo_puzzle_onirico(resultado):
			_guardar_o_avisar("")
		return

	var pista := PistaOnirica.resolver(caso, resultado)
	if pista.is_empty():
		return
	var progreso_nuevo := _actualizar_objetivo_puzzle_onirico(resultado)
	var pista_nueva := PistaOnirica.registrar(partida.estado, pista)
	# La recompensa física pertenece al mismo guardado que la pista, pero no
	# sustituye su función: es una herramienta contextual y no información.
	var objeto_nuevo := RecompensaOnirica.conceder(partida.estado)
	if progreso_nuevo or pista_nueva or objeto_nuevo:
		_guardar_o_avisar("")


func _abrir_expediente() -> void:
	super._abrir_expediente()
	if _pantalla == null:
		return
	_montar_asistente_siga()


func _montar_asistente_siga() -> void:
	_asistente_siga_caja = null
	_asistente_siga_conjunto = null
	var gato: Dictionary = jornada.get("gato", {})
	var visor := _pantalla.get_node_or_null("Visor") as Control
	if visor == null:
		return
	var contexto := ""
	if visor.has_method("contexto_asistente"):
		var estado: Dictionary = visor.call("contexto_asistente")
		contexto = GatoAyuda.contexto_siga(estado)
	var lineas := GatoAyuda.lineas_asistente(gato, contexto)
	if lineas.is_empty():
		return

	# El conjunto vive dentro del propio Visor: cuando OS98 adopta y reparenta
	# el visor dentro de Ventana_siga-98, Prometeo viaja con él en vez de quedar
	# como hermano por debajo del escritorio. El anclaje sigue siendo relativo
	# al contenido real de SIGA y no al CanvasLayer exterior (#802).
	var conjunto := HBoxContainer.new()
	conjunto.name = "AsistenteSiga"
	conjunto.theme = EstiloSiga.tema()
	conjunto.mouse_filter = Control.MOUSE_FILTER_PASS
	conjunto.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	conjunto.offset_left = -540
	conjunto.offset_top = -176
	conjunto.offset_right = -16
	conjunto.offset_bottom = -16
	conjunto.add_theme_constant_override("separation", 18)
	conjunto.gui_input.connect(_al_input_asistente_siga.bind(conjunto))
	visor.add_child(conjunto)
	_asistente_siga_conjunto = conjunto

	var burbuja := PanelContainer.new()
	burbuja.name = "BocadilloGato"
	burbuja.custom_minimum_size = Vector2(348, 118)
	burbuja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conjunto.add_child(burbuja)

	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	burbuja.add_child(margen)

	_asistente_siga_caja = VBoxContainer.new()
	_asistente_siga_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_asistente_siga_caja.add_theme_constant_override("separation", 6)
	margen.add_child(_asistente_siga_caja)
	_actualizar_lineas_asistente_siga(lineas)

	# Cola del bocadillo: un triángulo que apunta al avatar, separado del dibujo
	# del gato para que la atribución de la frase sea inequívoca.
	var puntero := Polygon2D.new()
	puntero.name = "PunteroBocadilloGato"
	puntero.polygon = PackedVector2Array([Vector2(342, 82), Vector2(370, 96), Vector2(342, 108)])
	puntero.color = Color(0.78, 0.79, 0.75)
	conjunto.add_child(puntero)

	var avatar := GatoAsistente2D.new()
	avatar.name = "GatoAsistente"
	var preferencias := PreferenciasSiga.cargar()
	avatar.configurar(GatoAyuda.nivel(gato), bool(preferencias.get("reduccion_movimiento", false)))
	conjunto.add_child(avatar)

	# Solo escuchamos la superficie pública del visor. El día no necesita saber
	# qué botones, listas o etiquetas produjeron el cambio de contexto.
	if visor.has_signal("contexto_asistente_cambiado"):
		visor.connect("contexto_asistente_cambiado", Callable(self, "_al_contexto_asistente_siga"))

	# El layout del visor (botones, traducciones) no se conoce hasta que la
	# escena termina de encuadrar en este frame; colocar un frame más tarde
	# evita medir un tamaño 0x0 tanto del conjunto como de los botones.
	call_deferred("_colocar_asistente_siga", conjunto, visor)


## Sitúa el conjunto donde el jugador lo dejó (#285); si nunca lo movió, usa el
## anclaje por defecto pero lo sube lo justo para no invadir la fila de
## acciones del visor (Relacionar/Marcar folio/Imputar), sea cual sea su altura
## real una vez traducida y en la resolución en curso.
func _colocar_asistente_siga(conjunto: Control, visor: Node) -> void:
	if not is_instance_valid(conjunto):
		return
	var preferencias := PreferenciasSiga.cargar()
	var guardada: Variant = preferencias.get(CLAVE_POSICION_ASISTENTE, null)
	if guardada is Dictionary:
		_fijar_posicion_libre_asistente(conjunto, Vector2(guardada["x"], guardada["y"]))
		return
	if visor == null:
		return
	var limite := _limite_superior_botones_visor(visor)
	if limite == INF:
		return
	var exceso: float = (
		(conjunto.global_position.y + conjunto.size.y) - (limite - MARGEN_BOTONES_ASISTENTE)
	)
	if exceso > 0.0:
		conjunto.offset_top -= exceso
		conjunto.offset_bottom -= exceso


## El visor no expone sus botones como superficie pública (#455 ya fijó que
## solo se escucha su señal), así que en vez de asumir nombres o huecos en
## píxeles se pregunta al árbol real por el más alto de sus Button: cualquier
## fila de acciones que se añada o se alargue por traducción se sigue
## respetando sin tener que volver a adivinar un offset fijo.
func _limite_superior_botones_visor(visor: Node) -> float:
	var limite := INF
	var pila: Array = [visor]
	while not pila.is_empty():
		var nodo: Node = pila.pop_back()
		# Un botón oculto (p.ej. el anexo aún sin desbloquear de #.../visor_anexos_app.gd)
		# no ocupa fila real: contarlo movería el conjunto por un hueco que nadie ve.
		if nodo is Button and nodo.is_visible_in_tree() and nodo.size.y > 0.0:
			limite = minf(limite, nodo.global_position.y)
		for hijo in nodo.get_children():
			pila.append(hijo)
	return limite


func _al_input_asistente_siga(evento: InputEvent, conjunto: Control) -> void:
	if not is_instance_valid(conjunto):
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_arrastrando_asistente = true
			_arrastre_asistente_offset = (
				conjunto.get_global_mouse_position() - conjunto.global_position
			)
		elif _arrastrando_asistente:
			_arrastrando_asistente = false
			_guardar_posicion_asistente_siga(conjunto)
		conjunto.accept_event()
	elif evento is InputEventMouseMotion and _arrastrando_asistente:
		_fijar_posicion_libre_asistente(
			conjunto, conjunto.get_global_mouse_position() - _arrastre_asistente_offset
		)
		conjunto.accept_event()


## Arrastrar cambia el conjunto de un anclaje relativo (abajo a la derecha) a
## una posición libre en píxeles, acotada a la pantalla para que no se pueda
## soltar el gato fuera de la vista tras redimensionar la ventana.
func _fijar_posicion_libre_asistente(conjunto: Control, nueva: Vector2) -> void:
	var techo := conjunto.get_parent()
	var limite: Vector2 = techo.size if techo is Control else conjunto.get_viewport_rect().size
	nueva.x = clampf(nueva.x, 0.0, maxf(limite.x - conjunto.size.x, 0.0))
	nueva.y = clampf(nueva.y, 0.0, maxf(limite.y - conjunto.size.y, 0.0))
	conjunto.set_anchors_preset(Control.PRESET_TOP_LEFT)
	conjunto.position = nueva


func _guardar_posicion_asistente_siga(conjunto: Control) -> void:
	var preferencias := PreferenciasSiga.cargar()
	preferencias[CLAVE_POSICION_ASISTENTE] = {"x": conjunto.position.x, "y": conjunto.position.y}
	PreferenciasSiga.guardar(preferencias)


func _al_contexto_asistente_siga(estado: Dictionary, evento: String) -> void:
	var contexto := GatoAyuda.contexto_siga(estado, evento)
	var lineas := GatoAyuda.lineas_asistente(jornada.get("gato", {}), contexto)
	_actualizar_lineas_asistente_siga(lineas)


func _actualizar_lineas_asistente_siga(lineas: Array) -> void:
	if not is_instance_valid(_asistente_siga_caja):
		return
	for hijo in _asistente_siga_caja.get_children():
		_asistente_siga_caja.remove_child(hijo)
		hijo.queue_free()
	for clave in lineas:
		var frase := Label.new()
		frase.text = tr(String(clave))
		frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		frase.custom_minimum_size.x = 320
		frase.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_asistente_siga_caja.add_child(frase)


func _montar_guia_sueno() -> void:
	var gato: Dictionary = jornada.get("gato", {})
	if not GatoAyuda.guia_visible(gato) or not _hay_rumbo_guia:
		return

	var rumbo := _salida_guia - _entrada_guia
	rumbo.y = 0.0
	if rumbo.length() < 0.01:
		return

	var direccion := rumbo.normalized()
	var eco := GatoEcoSueno.efecto(gato, int(jornada.get("dia", 0)))
	var distancia := float(eco.get("distancia", 1.4))
	var posicion := _entrada_guia + direccion * distancia
	_gato_guia = Gato.new()
	_mundo.add_child(_gato_guia)
	_gato_guia.empezar(posicion, [posicion])
	_gato_guia.configurar_reduccion_movimiento(_reduccion_movimiento_gato())
	if not eco.is_empty():
		_gato_guia.presentar_estado(String(eco.get("estado", "parado")))

	# Bien cuidado funciona como una brújula viva hacia el primer objetivo
	# pendiente, no hacia la antigua salida física. El eco solo cambia pose y
	# cercanía: jamás el rumbo ni la selección del objetivo.
	_orientar_gato_guia()
