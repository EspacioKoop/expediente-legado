## Selección inicial y consulta de condiciones extraordinarias de auditoría (#152).
##
## La misma superficie sirve en dos contextos: durante el alta inicial permite
## preparar la selección que se guardará al aceptar la ficha; dentro de SIGA es
## estrictamente de consulta. Pulsar una casilla nunca toca Partida por sí solo:
## el owner del alta decide cuándo persistirla.
class_name AuditoriasSiga
extends VBoxContainer

const CONDICIONES := [
	{
		"id": Auditorias.ACCION_SOBRANTE,
		"titulo": "AUDITORIAS_ACCION_SOBRANTE",
		"descripcion": "AUDITORIAS_ACCION_SOBRANTE_DESC",
	},
	{
		"id": Auditorias.GATO_DIARIO,
		"titulo": "AUDITORIAS_GATO_DIARIO",
		"descripcion": "AUDITORIAS_GATO_DIARIO_DESC",
	},
]

var _estado_partida: Dictionary = {}
var _editable := false
var _firma_estado := ""

var _ayuda: Label
var _checks: Dictionary = {}
var _estados: Dictionary = {}
var _historial_seccion: VBoxContainer
var _historial_lista: VBoxContainer


func configurar_estado(estado_partida: Dictionary, editable: bool = false) -> void:
	_estado_partida = estado_partida
	_editable = editable
	_firma_estado = ""
	if is_node_ready():
		_refrescar()


func seleccion() -> Array:
	var ids := []
	if not _editable:
		return ids
	for definicion in CONDICIONES:
		var id := String(definicion["id"])
		var check: CheckBox = _checks.get(id)
		if check != null and check.button_pressed:
			ids.append(id)
	ids.sort()
	return ids


func _ready() -> void:
	custom_minimum_size = Vector2(500, 190)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	_construir()
	_refrescar()


func _process(_delta: float) -> void:
	if _firma_actual() != _firma_estado:
		_refrescar()


func _construir() -> void:
	var cabecera := Label.new()
	cabecera.name = "CabeceraAuditorias"
	cabecera.text = tr("AUDITORIAS_CABECERA")
	cabecera.add_theme_font_size_override("font_size", 16)
	add_child(cabecera)

	_ayuda = Label.new()
	_ayuda.name = "AyudaAuditorias"
	_ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_ayuda)

	add_child(HSeparator.new())

	for definicion in CONDICIONES:
		var id := String(definicion["id"])
		var bloque := VBoxContainer.new()
		bloque.name = "Bloque_%s" % id
		bloque.add_theme_constant_override("separation", 3)
		add_child(bloque)

		var check := CheckBox.new()
		check.name = "Condicion_%s" % id
		check.text = tr(String(definicion["titulo"]))
		check.tooltip_text = tr(String(definicion["descripcion"]))
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bloque.add_child(check)
		_checks[id] = check

		var descripcion := Label.new()
		descripcion.name = "Descripcion_%s" % id
		descripcion.text = tr(String(definicion["descripcion"]))
		descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bloque.add_child(descripcion)

		var estado := Label.new()
		estado.name = "Estado_%s" % id
		bloque.add_child(estado)
		_estados[id] = estado

	_historial_seccion = VBoxContainer.new()
	_historial_seccion.name = "HistorialAuditorias"
	_historial_seccion.add_theme_constant_override("separation", 5)
	add_child(_historial_seccion)

	_historial_seccion.add_child(HSeparator.new())

	var historial_titulo := Label.new()
	historial_titulo.name = "TituloHistorial"
	historial_titulo.text = tr("AUDITORIAS_HISTORIAL_TITULO")
	historial_titulo.add_theme_font_size_override("font_size", 16)
	_historial_seccion.add_child(historial_titulo)

	var historial_ayuda := Label.new()
	historial_ayuda.name = "AyudaHistorial"
	historial_ayuda.text = tr("AUDITORIAS_HISTORIAL_AYUDA")
	historial_ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_historial_seccion.add_child(historial_ayuda)

	_historial_lista = VBoxContainer.new()
	_historial_lista.name = "VidasCerradas"
	_historial_lista.add_theme_constant_override("separation", 8)
	_historial_seccion.add_child(_historial_lista)


func _refrescar() -> void:
	if _ayuda == null:
		return

	_ayuda.text = tr("AUDITORIAS_AYUDA_SELECCION" if _editable else "AUDITORIAS_AYUDA_CONSULTA")
	var auditoria := _auditoria_actual()
	for definicion in CONDICIONES:
		var id := String(definicion["id"])
		var check: CheckBox = _checks[id]
		check.disabled = not _editable
		check.set_pressed_no_signal(auditoria.get("activas", []).has(id))

		var estado: Label = _estados[id]
		estado.text = tr(_clave_estado(Auditorias.estado(auditoria, id)))

	_refrescar_historial(auditoria)
	_firma_estado = _firma_actual()


func _refrescar_historial(auditoria: Dictionary) -> void:
	if _historial_seccion == null or _historial_lista == null:
		return
	_historial_seccion.visible = not _editable
	for hijo in _historial_lista.get_children():
		_historial_lista.remove_child(hijo)
		hijo.queue_free()
	if _editable:
		return

	var historial: Array = auditoria.get(Auditorias.CLAVE_HISTORIAL, [])
	if historial.is_empty():
		var vacio := Label.new()
		vacio.name = "HistorialVacio"
		vacio.text = tr("AUDITORIAS_HISTORIAL_VACIO")
		_historial_lista.add_child(vacio)
		return

	for indice in range(historial.size() - 1, -1, -1):
		var registro = historial[indice]
		if not registro is Dictionary:
			continue
		var bloque := VBoxContainer.new()
		bloque.name = "Vida_%d" % int((registro as Dictionary).get("vuelta", 0))
		bloque.add_theme_constant_override("separation", 2)
		_historial_lista.add_child(bloque)

		var cabecera := Label.new()
		cabecera.text = (
			tr("AUDITORIAS_HISTORIAL_VIDA")
			% [
				int((registro as Dictionary).get("vuelta", 0)),
				_texto_motivo(String((registro as Dictionary).get("motivo", "otro"))),
			]
		)
		bloque.add_child(cabecera)

		var completadas: Array = (registro as Dictionary).get("completadas", [])
		var fallidas: Dictionary = (registro as Dictionary).get("fallidas", {})
		for valor in (registro as Dictionary).get("activas", []):
			var id := String(valor)
			var resultado := "AUDITORIAS_HISTORIAL_RESULTADO_PENDIENTE"
			if completadas.has(id):
				resultado = "AUDITORIAS_HISTORIAL_RESULTADO_COMPLETADA"
			elif fallidas.has(id):
				resultado = "AUDITORIAS_HISTORIAL_RESULTADO_FALLIDA"
			var linea := Label.new()
			linea.text = tr("AUDITORIAS_HISTORIAL_LINEA") % [_titulo_condicion(id), tr(resultado)]
			linea.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			bloque.add_child(linea)


func _titulo_condicion(id: String) -> String:
	for definicion in CONDICIONES:
		if String(definicion["id"]) == id:
			return tr(String(definicion["titulo"]))
	return id


func _texto_motivo(motivo: String) -> String:
	match motivo:
		"reasignacion":
			return tr("AUDITORIAS_HISTORIAL_MOTIVO_REASIGNACION")
		"final_narrativo":
			return tr("AUDITORIAS_HISTORIAL_MOTIVO_FINAL")
		_:
			return tr("AUDITORIAS_HISTORIAL_MOTIVO_OTRO")


func _auditoria_actual() -> Dictionary:
	var valor: Variant = _estado_partida.get(Auditorias.CLAVE_ESTADO, {})
	return valor if valor is Dictionary else {}


func _clave_estado(valor: String) -> String:
	match valor:
		"activa":
			return "AUDITORIAS_ESTADO_ACTIVA"
		"fallida":
			return "AUDITORIAS_ESTADO_FALLIDA"
		"completada":
			return "AUDITORIAS_ESTADO_COMPLETADA"
		_:
			return "AUDITORIAS_ESTADO_INACTIVA"


func _firma_actual() -> String:
	return JSON.stringify(_estado_partida.get(Auditorias.CLAVE_ESTADO, {}))
