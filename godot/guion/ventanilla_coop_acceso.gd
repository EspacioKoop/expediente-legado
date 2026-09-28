class_name VentanillaCoopAcceso
extends VBoxContainer

## Superficie opt-in del experimento cooperativo de #380.
##
## No recibe estado canónico de campaña. Solo prepara identidad pseudónima y
## abre una sala efímera sobre el transporte compartido. Las elecciones/rondas
## se integran en un corte posterior sobre esta misma superficie.

const IdentidadOnline = preload("res://guion/red/identidad_online.gd")
const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")
const CombateCoopServicio = preload("res://guion/red/combate_coop_servicio.gd")
const CombateCoop = preload("res://guion/combate_coop.gd")

const AJUSTE_ENDPOINT := "multiplayer/websocket_url"
const AJUSTE_ENDPOINT_LEGACY := "multiplayer/ghosts/websocket_url"
const SCENE_KEY := "ventanilla_coop"
const ENCOUNTER_ID := "ventanilla-experimental"
const MAX_SALA := 32
const INTERVALO_CONSULTA := 0.25
const RIVAL_EXPERIMENTAL := {"id": "ventanilla-coop", "ataques": []}

var identidad_ruta := IdentidadOnline.RUTA
var endpoint_override := ""
var transporte_override: RefCounted = null
var ahora_override := -1

var _identidad: IdentidadOnline
var _servicio: CombateCoopServicio
var _estado: Label
var _sala: LineEdit
var _activar: Button
var _entrar: Button
var _cerrar: Button
var _acciones: HBoxContainer
var _botones_accion: Dictionary = {}
var _sesion: Dictionary = {}
var _ronda := 0
var _eleccion_publicada := false
var _evento_propio: Dictionary = {}
var _acumulado_consulta := 0.0


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_construir()
	refrescar()


func _process(delta: float) -> void:
	if _servicio == null:
		return
	_servicio.procesar(delta)
	_acumulado_consulta += maxf(delta, 0.0)
	if _acumulado_consulta < INTERVALO_CONSULTA:
		return
	_acumulado_consulta = 0.0
	_consultar_ronda()


func _exit_tree() -> void:
	if _servicio != null:
		_servicio.cerrar()


func configurar_prueba(
	ruta_identidad: String, transporte: RefCounted, endpoint: String = "wss://fixture.invalid"
) -> void:
	identidad_ruta = ruta_identidad
	transporte_override = transporte
	endpoint_override = endpoint


func refrescar() -> void:
	_identidad = IdentidadOnline.new(identidad_ruta)
	var carga := _identidad.cargar()
	var endpoint := _endpoint()
	var identidad_activa := bool(carga.get("ok", false)) and _identidad.activa()
	var endpoint_valido := _endpoint_valido(endpoint)

	_activar.visible = not identidad_activa
	_sala.editable = identidad_activa and endpoint_valido
	_entrar.disabled = not identidad_activa or not endpoint_valido
	_cerrar.disabled = _servicio == null
	if is_instance_valid(_acciones):
		_acciones.visible = _servicio != null

	if not bool(carga.get("ok", false)):
		_estado.text = tr("VENTANILLA_COOP_IDENTIDAD_ERROR")
	elif not identidad_activa:
		_estado.text = tr("VENTANILLA_COOP_DESACTIVADO")
	elif not endpoint_valido:
		_estado.text = tr("VENTANILLA_COOP_SIN_SERVICIO")
	elif _servicio == null:
		_estado.text = tr("VENTANILLA_COOP_LISTO")


func _construir() -> void:
	var titulo := Label.new()
	titulo.name = "TituloCoop"
	titulo.text = tr("VENTANILLA_COOP_TITULO")
	add_child(titulo)

	_estado = Label.new()
	_estado.name = "EstadoCoop"
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_estado)

	_activar = Button.new()
	_activar.name = "ActivarCoop"
	_activar.text = tr("VENTANILLA_COOP_ACTIVAR")
	_activar.pressed.connect(_activar_online)
	add_child(_activar)

	var fila_sala := HBoxContainer.new()
	fila_sala.name = "FilaSalaCoop"
	add_child(fila_sala)

	var etiqueta_sala := Label.new()
	etiqueta_sala.text = tr("VENTANILLA_COOP_SALA")
	fila_sala.add_child(etiqueta_sala)

	_sala = LineEdit.new()
	_sala.name = "SalaCoop"
	_sala.placeholder_text = tr("VENTANILLA_COOP_SALA_EJEMPLO")
	_sala.max_length = MAX_SALA
	_sala.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sala.text_submitted.connect(func(_texto: String): _entrar_sala())
	fila_sala.add_child(_sala)

	_entrar = Button.new()
	_entrar.name = "EntrarSalaCoop"
	_entrar.text = tr("VENTANILLA_COOP_ENTRAR")
	_entrar.pressed.connect(_entrar_sala)
	fila_sala.add_child(_entrar)

	_acciones = HBoxContainer.new()
	_acciones.name = "AccionesCoop"
	_acciones.add_theme_constant_override("separation", 6)
	_acciones.visible = false
	add_child(_acciones)
	for accion in Combate.TIPOS:
		var boton := Button.new()
		boton.name = "AccionCoop_%s" % accion
		boton.text = Combate.etiqueta(accion)
		boton.pressed.connect(_elegir.bind(accion))
		_acciones.add_child(boton)
		_botones_accion[accion] = boton

	_cerrar = Button.new()
	_cerrar.name = "CerrarSalaCoop"
	_cerrar.text = tr("VENTANILLA_COOP_CERRAR")
	_cerrar.pressed.connect(_cerrar_sala)
	add_child(_cerrar)


func _activar_online() -> void:
	_identidad = IdentidadOnline.new(identidad_ruta)
	var carga := _identidad.cargar()
	if not bool(carga.get("ok", false)) and String(carga.get("status", "")) != "disabled":
		_estado.text = tr("VENTANILLA_COOP_IDENTIDAD_ERROR")
		return
	var resultado := _identidad.habilitar()
	if not bool(resultado.get("ok", false)):
		_estado.text = tr("VENTANILLA_COOP_IDENTIDAD_ERROR")
		return
	refrescar()


func _entrar_sala() -> void:
	if _identidad == null:
		refrescar()
	if _identidad == null or not _identidad.activa():
		_estado.text = tr("VENTANILLA_COOP_DESACTIVADO")
		return

	var sala := _sala.text.strip_edges()
	if not _sala_valida(sala):
		_estado.text = tr("VENTANILLA_COOP_SALA_INVALIDA")
		return

	var endpoint := _endpoint()
	if not _endpoint_valido(endpoint):
		_estado.text = tr("VENTANILLA_COOP_SIN_SERVICIO")
		return

	if _servicio != null:
		_servicio.cerrar()
	var transporte: RefCounted = (
		transporte_override if transporte_override != null else TransporteWebSocket.new(endpoint)
	)
	_servicio = CombateCoopServicio.new(transporte)
	var apertura := (
		_servicio
		. abrir(
			SCENE_KEY,
			sala,
			ENCOUNTER_ID,
			_identidad.actor_public_id(),
		)
	)
	if not bool(apertura.get("ok", false)):
		_servicio = null
		_estado.text = tr("VENTANILLA_COOP_ERROR_RED")
		_cerrar.disabled = true
		return

	_estado.text = tr("VENTANILLA_COOP_EN_SALA") % sala
	_cerrar.disabled = false
	_entrar.disabled = true
	_sala.editable = false
	_reiniciar_encuentro()


func _cerrar_sala() -> void:
	if _servicio != null:
		_servicio.cerrar()
	_servicio = null
	_reiniciar_encuentro(false)
	_estado.text = tr("VENTANILLA_COOP_LISTO")
	_cerrar.disabled = true
	_entrar.disabled = false
	_sala.editable = true


func _reiniciar_encuentro(activo: bool = true) -> void:
	_sesion.clear()
	_ronda = 0
	_eleccion_publicada = false
	_evento_propio.clear()
	_acumulado_consulta = 0.0
	if is_instance_valid(_acciones):
		_acciones.visible = activo
	_habilitar_acciones(activo)


func _elegir(accion: String) -> void:
	if _servicio == null or _eleccion_publicada or bool(_sesion.get("terminado", false)):
		return
	if not Combate.TIPOS.has(accion):
		return
	var ahora := _ahora()
	var resultado := _servicio.publicar_eleccion(_ronda, accion, _game_build(), ahora)
	if not bool(resultado.get("ok", false)):
		_estado.text = tr("VENTANILLA_COOP_ERROR_RED")
		return
	var evento = resultado.get("event", {})
	if evento is Dictionary:
		_evento_propio = evento.duplicate(true)
	_eleccion_publicada = true
	_habilitar_acciones(false)
	_actualizar_estado_ronda()


func _consultar_ronda() -> void:
	if _servicio == null or not _eleccion_publicada:
		return
	var consulta := _servicio.consultar_elecciones(_ronda, _ahora())
	if not bool(consulta.get("ok", false)):
		return
	var por_actor: Dictionary = {}
	if not _evento_propio.is_empty():
		por_actor[String(_evento_propio.get("actor_public_id", ""))] = _evento_propio
	for evento in consulta.get("choices", []):
		if not evento is Dictionary:
			continue
		var actor := String(evento.get("actor_public_id", ""))
		if not actor.is_empty():
			por_actor[actor] = evento
	if por_actor.size() < CombateCoop.PARTICIPANTES:
		return
	var actores := por_actor.keys()
	actores.sort()
	var elecciones: Array = []
	for actor in actores.slice(0, CombateCoop.PARTICIPANTES):
		elecciones.append(por_actor[actor])
	_resolver_elecciones(elecciones)


func _resolver_elecciones(elecciones: Array) -> void:
	if elecciones.size() != CombateCoop.PARTICIPANTES:
		return
	if _sesion.is_empty():
		var actores: Array[String] = []
		for evento in elecciones:
			actores.append(String(evento.get("actor_public_id", "")))
		actores.sort()
		_sesion = CombateCoop.nueva(RIVAL_EXPERIMENTAL.duplicate(true), actores[0], actores[1])
		if _sesion.is_empty():
			return

	var resolucion := {}
	for evento in elecciones:
		var payload: Dictionary = evento.get("payload", {})
		resolucion = CombateCoop.elegir(
			_sesion,
			String(evento.get("actor_public_id", "")),
			String(payload.get("action", "")),
			func() -> float: return 0.0,
		)
	if not bool(resolucion.get("resolved", false)):
		return
	_evento_propio.clear()
	_eleccion_publicada = false
	if bool(resolucion.get("finished", false)):
		_habilitar_acciones(false)
		_actualizar_estado_ronda()
		return
	_ronda += 1
	_habilitar_acciones(true)
	_actualizar_estado_ronda()


func _actualizar_estado_ronda() -> void:
	var sala := _sala.text.strip_edges()
	var mostrada := mini(_ronda + 1, CombateCoop.MAX_RONDAS)
	if bool(_sesion.get("terminado", false)):
		mostrada = CombateCoop.MAX_RONDAS
	_estado.text = "%s · %d/%d" % [
		tr("VENTANILLA_COOP_EN_SALA") % sala,
		mostrada,
		CombateCoop.MAX_RONDAS,
	]


func _habilitar_acciones(habilitadas: bool) -> void:
	for boton in _botones_accion.values():
		if boton is Button:
			boton.disabled = not habilitadas


func _ahora() -> int:
	if ahora_override >= 0:
		return ahora_override
	return int(Time.get_unix_time_from_system())


func _game_build() -> String:
	var version := String(ProjectSettings.get_setting("application/config/version", "dev")).strip_edges()
	return version if not version.is_empty() else "dev"


func _endpoint() -> String:
	if not endpoint_override.strip_edges().is_empty():
		return endpoint_override.strip_edges()
	var endpoint := String(ProjectSettings.get_setting(AJUSTE_ENDPOINT, "")).strip_edges()
	if endpoint.is_empty():
		endpoint = String(ProjectSettings.get_setting(AJUSTE_ENDPOINT_LEGACY, "")).strip_edges()
	return endpoint


func _endpoint_valido(endpoint: String) -> bool:
	return endpoint.begins_with("ws://") or endpoint.begins_with("wss://")


func _sala_valida(valor: String) -> bool:
	if valor.is_empty() or valor.length() > MAX_SALA:
		return false
	for indice in range(valor.length()):
		var codigo := valor.unicode_at(indice)
		var numero := codigo >= 48 and codigo <= 57
		var mayuscula := codigo >= 65 and codigo <= 90
		var minuscula := codigo >= 97 and codigo <= 122
		if not numero and not mayuscula and not minuscula and codigo != 45 and codigo != 95:
			return false
	return true
