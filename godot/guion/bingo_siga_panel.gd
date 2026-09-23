## Superficie de la tarjeta diaria del Bingo SIGA (#151).
##
## Presenta el estado canónico que ya vive en Jornada. No mantiene una copia
## local del progreso ni concede recompensas: las tres decisiones se delegan en
## BingoSiga y el owner decide cuándo persistir Partida.
class_name BingoSigaPanel
extends VBoxContainer

signal decision_cambiada(decision: String)

var _estado_partida: Dictionary = {}
var _firma_estado := ""

var _decision: Label
var _objetivos: VBoxContainer
var _aceptar: Button
var _descartar: Button
var _ignorar: Button


func configurar_estado(estado_partida: Dictionary) -> void:
	_estado_partida = estado_partida
	_firma_estado = ""
	if is_node_ready():
		_refrescar()


func _ready() -> void:
	custom_minimum_size = Vector2(500, 300)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	_construir()
	_refrescar()


func _process(_delta: float) -> void:
	var firma := _firma_actual()
	if firma != _firma_estado:
		_refrescar()


func _construir() -> void:
	var cabecera := Label.new()
	cabecera.name = "CabeceraBingoSiga"
	cabecera.text = tr("BINGO_SIGA_CABECERA")
	cabecera.add_theme_font_size_override("font_size", 16)
	add_child(cabecera)

	var ayuda := Label.new()
	ayuda.name = "AyudaBingoSiga"
	ayuda.text = tr("BINGO_SIGA_AYUDA")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(ayuda)

	_decision = Label.new()
	_decision.name = "DecisionBingoSiga"
	_decision.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_decision)

	add_child(HSeparator.new())

	_objetivos = VBoxContainer.new()
	_objetivos.name = "ObjetivosBingoSiga"
	_objetivos.add_theme_constant_override("separation", 6)
	_objetivos.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_objetivos)

	add_child(HSeparator.new())

	var acciones := HBoxContainer.new()
	acciones.name = "DecisionesBingoSiga"
	acciones.add_theme_constant_override("separation", 8)
	add_child(acciones)

	_aceptar = Button.new()
	_aceptar.name = "AceptarBingoSiga"
	_aceptar.text = tr("BINGO_SIGA_ACEPTAR")
	_aceptar.pressed.connect(_al_aceptar)
	acciones.add_child(_aceptar)

	_descartar = Button.new()
	_descartar.name = "DescartarBingoSiga"
	_descartar.text = tr("BINGO_SIGA_DESCARTAR")
	_descartar.pressed.connect(_al_descartar)
	acciones.add_child(_descartar)

	_ignorar = Button.new()
	_ignorar.name = "IgnorarBingoSiga"
	_ignorar.text = tr("BINGO_SIGA_IGNORAR")
	_ignorar.pressed.connect(_al_ignorar)
	acciones.add_child(_ignorar)


func _refrescar() -> void:
	if _decision == null or _objetivos == null:
		return
	if _estado_partida.is_empty():
		_decision.text = tr("BINGO_SIGA_SIN_PARTIDA")
		_limpiar_objetivos()
		_actualizar_botones(true)
		_firma_estado = _firma_actual()
		return

	var actual := BingoSiga.tarjeta_diaria(_estado_partida)
	_decision.text = (
		tr("BINGO_SIGA_DECISION")
		% tr(_clave_decision(String(actual.get("decision", BingoSiga.DECISION_PENDIENTE))))
	)

	_limpiar_objetivos()
	for objetivo in BingoSiga.estado_tarjeta(_estado_partida):
		if not objetivo is Dictionary:
			continue
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_objetivos.add_child(fila)

		var check := CheckBox.new()
		check.disabled = true
		check.button_pressed = bool((objetivo as Dictionary).get("completado", false))
		check.focus_mode = Control.FOCUS_NONE
		fila.add_child(check)

		var texto := Label.new()
		texto.text = String((objetivo as Dictionary).get("texto", ""))
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(texto)

	var cerrada := bool(actual.get("cerrada", false))
	_actualizar_botones(cerrada)
	if not cerrada and String(actual.get("decision", "")) == BingoSiga.DECISION_PENDIENTE:
		_aceptar.call_deferred("grab_focus")
	_firma_estado = _firma_actual()


func _limpiar_objetivos() -> void:
	if _objetivos == null:
		return
	for hijo in _objetivos.get_children():
		_objetivos.remove_child(hijo)
		hijo.queue_free()


func _actualizar_botones(cerrada: bool) -> void:
	for boton in [_aceptar, _descartar, _ignorar]:
		if boton != null:
			boton.disabled = cerrada


func _al_aceptar() -> void:
	_decidir(BingoSiga.DECISION_ACEPTAR)


func _al_descartar() -> void:
	_decidir(BingoSiga.DECISION_DESCARTAR)


func _al_ignorar() -> void:
	_decidir(BingoSiga.DECISION_IGNORAR)


func _decidir(decision: String) -> void:
	if BingoSiga.decidir(_estado_partida, decision):
		decision_cambiada.emit(decision)
		_refrescar()


func _clave_decision(decision: String) -> String:
	match decision:
		BingoSiga.DECISION_ACEPTAR:
			return "BINGO_SIGA_DECISION_ACEPTADA"
		BingoSiga.DECISION_DESCARTAR:
			return "BINGO_SIGA_DECISION_DESCARTADA"
		BingoSiga.DECISION_IGNORAR:
			return "BINGO_SIGA_DECISION_IGNORADA"
		_:
			return "BINGO_SIGA_DECISION_PENDIENTE"


func _firma_actual() -> String:
	if _estado_partida.is_empty():
		return ""
	var jornada: Variant = _estado_partida.get("jornada", {})
	if not jornada is Dictionary:
		return ""
	var datos := {
		"dia": int((jornada as Dictionary).get("dia", 1)),
		"bingo": (jornada as Dictionary).get(BingoSiga.CLAVE_ESTADO, {}),
		"leido_hoy": (jornada as Dictionary).get("leido_hoy", []),
		"cerrados_hoy": int((jornada as Dictionary).get("cerrados_hoy", 0)),
		"acciones": int((jornada as Dictionary).get("acciones", 0)),
		"gato": (jornada as Dictionary).get("gato", {}),
		"alquiler": (jornada as Dictionary).get("alquiler", {}),
	}
	return JSON.stringify(datos)
