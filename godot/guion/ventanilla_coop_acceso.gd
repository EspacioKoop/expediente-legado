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

const AJUSTE_ENDPOINT := "multiplayer/websocket_url"
const AJUSTE_ENDPOINT_LEGACY := "multiplayer/ghosts/websocket_url"
const SCENE_KEY := "ventanilla_coop"
const ENCOUNTER_ID := "ventanilla-experimental"
const MAX_SALA := 32

var identidad_ruta := IdentidadOnline.RUTA
var endpoint_override := ""
var transporte_override: RefCounted = null

var _identidad: IdentidadOnline
var _servicio: CombateCoopServicio
var _estado: Label
var _sala: LineEdit
var _activar: Button
var _entrar: Button
var _cerrar: Button


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_construir()
	refrescar()


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


func _cerrar_sala() -> void:
	if _servicio != null:
		_servicio.cerrar()
	_servicio = null
	_estado.text = tr("VENTANILLA_COOP_LISTO")
	_cerrar.disabled = true
	_entrar.disabled = false
	_sala.editable = true


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
