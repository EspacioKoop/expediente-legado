## Integra el final alternativo del legado en el Dia real (#1029).
##
## Se monta como controller hijo para no convertir la cadena dia_* en un reloj
## global. El contador solo empieza cuando el Dia padre terminó de cargar la
## partida; por eso cargar una partida nunca puede conceder La Torre.
extends Node

const RUTA_TEXTOS := "res://datos/final_alternativo_textos.json"

var _reloj := InactividadPrometeo.new()
var _dialogo: AcceptDialog
var _caminante: CharacterBody3D
var _caminante_procesaba := false


func _ready() -> void:
	set_process(false)
	var dia := get_parent()
	if dia == null:
		return
	if dia.is_node_ready():
		_activar()
	else:
		dia.ready.connect(_activar, CONNECT_ONE_SHOT)


func _activar() -> void:
	var dia := get_parent()
	if dia == null:
		return
	var partida_actual = dia.get("partida")
	if not (partida_actual is Partida):
		return
	_reloj.iniciar((partida_actual as Partida).estado)
	set_process(true)


func _process(delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		set_process(false)
		return
	var partida_actual = dia.get("partida")
	if not (partida_actual is Partida):
		set_process(false)
		return
	if _reloj.avanzar((partida_actual as Partida).estado, delta):
		_mostrar_final(dia, partida_actual as Partida)


func _mostrar_final(dia: Node, partida_actual: Partida) -> void:
	var estado := partida_actual.estado
	Prometeo.desbloquear_carta_en_estado(estado, "la-torre")
	InactividadPrometeo.desbloquear_logro_final(estado)

	# La Torre puede ser la última carta válida de una partida perfecta.
	# Igual que el resto de triggers de #1029, El Mundo se reevalúa en el
	# mismo evento jugable y nunca durante carga/presentación.
	var contenido_actual = dia.get("contenido")
	if contenido_actual is Contenido:
		var casos_principales := (contenido_actual as Contenido).principales()
		Prometeo.sincronizar_tarot_mundo(estado, casos_principales)

	_guardar_evento(dia, partida_actual)
	_abrir_dialogo(dia)


func _guardar_evento(dia: Node, partida_actual: Partida) -> void:
	var guardado := false
	if dia.has_method("_guardar_o_avisar"):
		guardado = bool(dia.call("_guardar_o_avisar", ""))
	else:
		guardado = partida_actual.guardar()
	if not guardado:
		push_warning("El final alternativo quedó pendiente de persistencia")


func _abrir_dialogo(dia: Node) -> void:
	if is_instance_valid(_dialogo):
		return

	var textos := _cargar_textos()
	_dialogo = AcceptDialog.new()
	_dialogo.name = "FinalAlternativoPrometeo"
	_dialogo.title = String(textos.get("titulo", ""))
	_dialogo.dialog_text = String(textos.get("texto", ""))
	_dialogo.ok_button_text = String(textos.get("aceptar", ""))
	_dialogo.min_size = Vector2i(560, 220)
	_dialogo.exclusive = true
	_dialogo.confirmed.connect(_cerrar_dialogo)
	_dialogo.canceled.connect(_cerrar_dialogo)
	dia.add_child(_dialogo)

	_bloquear_caminante(dia)
	_dialogo.popup_centered()
	_dialogo.get_ok_button().grab_focus.call_deferred()


func _bloquear_caminante(dia: Node) -> void:
	var candidato = dia.get("_caminante")
	if not (candidato is CharacterBody3D):
		return
	_caminante = candidato as CharacterBody3D
	_caminante_procesaba = _caminante.is_physics_processing()
	_caminante.set_physics_process(false)


func _cerrar_dialogo() -> void:
	if is_instance_valid(_dialogo):
		_dialogo.queue_free()
	_dialogo = null

	if is_instance_valid(_caminante):
		_caminante.set_physics_process(_caminante_procesaba)
	_caminante = null


func _cargar_textos() -> Dictionary:
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	return datos if datos is Dictionary else {}
