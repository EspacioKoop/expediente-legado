class_name MinijuegoSalaPanel
extends PanelContainer

## UI reutilizable de salas privadas para minijuegos sociales (#383).
##
## Solo recoge intención del jugador y muestra estado. No activa red, no conoce
## Partida y no crea progreso. El controlador decide qué transporte usar.

signal crear_sala_solicitada(codigo: String)
signal unirse_sala_solicitada(codigo: String)
signal cancelar_solicitado

const RUTA_TEXTOS := "res://datos/minijuego_sala_textos.json"
const CODIGO_LONGITUD := 6
const ALFABETO := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var _textos: Dictionary = {}
var _titulo: Label
var _reglas: Label
var _ayuda: Label
var _codigo: LineEdit
var _estado: Label
var _crear: Button
var _unirse: Button
var _volver: Button
var _rules_version := 0
var _normalizando := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloSiga.tema()
	custom_minimum_size = Vector2(560, 360)
	_textos = _cargar_textos()
	_montar()
	visible = false


func abrir(nombre_minijuego: String, rules_version: int, codigo_inicial: String = "") -> void:
	_rules_version = maxi(rules_version, 0)
	_titulo.text = _texto("titulo") % nombre_minijuego
	_reglas.text = _texto("reglas") % _rules_version
	_codigo.text = normalizar_codigo(codigo_inicial)
	_estado.text = _texto("ayuda")
	visible = true
	_crear.grab_focus.call_deferred()


func cerrar() -> void:
	visible = false
	_estado.text = ""


func mostrar_estado(status: String, detalles: Dictionary = {}) -> void:
	match status:
		"connecting":
			_estado.text = _texto("conectando")
		"reconnecting":
			_estado.text = _texto("reconectando")
		"online":
			_estado.text = _texto("online") % String(detalles.get("room_id", _codigo.text))
		"timeout":
			_estado.text = _texto("timeout")
		"incompatible_rules":
			_estado.text = (
				_texto("reglas_incompatibles")
				% [
					int(detalles.get("local", _rules_version)),
					int(detalles.get("remote", 0)),
				]
			)
		"closed":
			_estado.text = _texto("cerrada")
		_:
			_estado.text = _texto("error")


func codigo_actual() -> String:
	return normalizar_codigo(_codigo.text)


static func normalizar_codigo(valor: String) -> String:
	var mayusculas := valor.strip_edges().to_upper()
	var salida := ""
	for indice in range(mayusculas.length()):
		var caracter := mayusculas.substr(indice, 1)
		if ALFABETO.contains(caracter):
			salida += caracter
			if salida.length() >= CODIGO_LONGITUD:
				break
	return salida


static func codigo_valido(valor: String) -> bool:
	var codigo := normalizar_codigo(valor)
	return codigo.length() == CODIGO_LONGITUD and codigo == valor.strip_edges().to_upper()


static func generar_codigo() -> String:
	var crypto := Crypto.new()
	var bytes := crypto.generate_random_bytes(CODIGO_LONGITUD)
	var salida := ""
	for byte in bytes:
		salida += ALFABETO.substr(int(byte) % ALFABETO.length(), 1)
	return salida


func _unhandled_input(evento: InputEvent) -> void:
	if not visible or not evento.is_pressed() or evento.is_echo():
		return
	var cancelar := evento.is_action("ui_cancel")
	if InputMap.has_action("cancelar"):
		cancelar = cancelar or evento.is_action("cancelar")
	if not cancelar:
		return
	get_viewport().set_input_as_handled()
	cancelar_solicitado.emit()


func _montar() -> void:
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	margen.add_child(caja)

	_titulo = Label.new()
	_titulo.name = "TituloSala"
	caja.add_child(_titulo)

	_reglas = Label.new()
	_reglas.name = "ReglasSala"
	caja.add_child(_reglas)

	_ayuda = Label.new()
	_ayuda.name = "AyudaSala"
	_ayuda.text = _texto("descripcion")
	_ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_ayuda)

	var fila_codigo := HBoxContainer.new()
	fila_codigo.add_theme_constant_override("separation", 10)
	caja.add_child(fila_codigo)

	var etiqueta := Label.new()
	etiqueta.text = _texto("codigo")
	fila_codigo.add_child(etiqueta)

	_codigo = LineEdit.new()
	_codigo.name = "CodigoSala"
	# Deja margen al pegar códigos con espacios/guiones: text_changed normaliza
	# antes de limitar a los seis caracteres útiles.
	_codigo.max_length = CODIGO_LONGITUD * 2
	_codigo.placeholder_text = _texto("placeholder")
	_codigo.accessibility_name = _texto("codigo")
	_codigo.focus_mode = Control.FOCUS_ALL
	_codigo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_codigo.text_changed.connect(_al_codigo_cambiado)
	_codigo.text_submitted.connect(func(_texto_enviado: String): _unirse_sala())
	fila_codigo.add_child(_codigo)

	_estado = Label.new()
	_estado.name = "EstadoSala"
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.accessibility_live = AccessibilityServer.LIVE_POLITE
	caja.add_child(_estado)

	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_END
	botones.add_theme_constant_override("separation", 8)
	caja.add_child(botones)

	_volver = _boton("VolverSala", _texto("volver"))
	_volver.pressed.connect(func(): cancelar_solicitado.emit())
	botones.add_child(_volver)

	_unirse = _boton("UnirseSala", _texto("unirse"))
	_unirse.pressed.connect(_unirse_sala)
	botones.add_child(_unirse)

	_crear = _boton("CrearSala", _texto("crear"))
	_crear.pressed.connect(_crear_sala)
	botones.add_child(_crear)


func _boton(nombre: String, texto: String) -> Button:
	var boton := Button.new()
	boton.name = nombre
	boton.text = texto
	boton.accessibility_name = texto
	boton.focus_mode = Control.FOCUS_ALL
	return boton


func _crear_sala() -> void:
	var codigo := generar_codigo()
	_codigo.text = codigo
	_estado.text = _texto("codigo_listo") % codigo
	crear_sala_solicitada.emit(codigo)


func _unirse_sala() -> void:
	var codigo := normalizar_codigo(_codigo.text)
	_codigo.text = codigo
	if not codigo_valido(codigo):
		_estado.text = _texto("codigo_invalido")
		_codigo.grab_focus.call_deferred()
		return
	_estado.text = _texto("conectando")
	unirse_sala_solicitada.emit(codigo)


func _al_codigo_cambiado(valor: String) -> void:
	if _normalizando:
		return
	var normalizado := normalizar_codigo(valor)
	if normalizado == valor:
		return
	_normalizando = true
	_codigo.text = normalizado
	_codigo.caret_column = normalizado.length()
	_normalizando = false


func _cargar_textos() -> Dictionary:
	if not FileAccess.file_exists(RUTA_TEXTOS):
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	return datos if datos is Dictionary else {}


func _texto(clave: String) -> String:
	return String(_textos.get(clave, clave))
