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
]

var _estado_partida: Dictionary = {}
var _editable := false
var _firma_estado := ""

var _ayuda: Label
var _checks: Dictionary = {}
var _estados: Dictionary = {}


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


func _refrescar() -> void:
	if _ayuda == null:
		return

	_ayuda.text = tr(
		"AUDITORIAS_AYUDA_SELECCION" if _editable else "AUDITORIAS_AYUDA_CONSULTA"
	)
	var auditoria := _auditoria_actual()
	for definicion in CONDICIONES:
		var id := String(definicion["id"])
		var check: CheckBox = _checks[id]
		check.disabled = not _editable
		check.set_pressed_no_signal(auditoria.get("activas", []).has(id))

		var estado: Label = _estados[id]
		estado.text = tr(_clave_estado(Auditorias.estado(auditoria, id)))

	_firma_estado = _firma_actual()


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
