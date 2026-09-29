## Controller hijo para llamadas internas de oficina (#1769).
##
## El núcleo decide qué llamada toca; este nodo solo materializa un teléfono
## interactivo durante unos segundos y delega una reacción ambiental opcional
## al controller de compañeros. Ignorar nunca deja un objetivo pendiente.
extends Node

const DURACION_TIMBRE := 10.0
const NOMBRE_INTERACCION := "LlamadaInternaActiva"
const NOMBRE_HABLANTE := "HablanteTelefonoInterno"

var _mundo_id := 0
var _llamada: Dictionary = {}
var _telefono: Interactuable3D
var _hablante: CompaneroInteractivo3D
var _restante := 0.0


func _process(delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia.get("_mundo") == null:
		_limpiar(dia, true)
		return
	var mundo := dia.get("_mundo") as Node3D
	var id_mundo := mundo.get_instance_id()
	if id_mundo != _mundo_id:
		_limpiar(dia, true)
		_mundo_id = id_mundo

	if String(dia.jornada.get("fase", "")) != "archivo":
		_limpiar(dia, true)
		return

	if is_instance_valid(_telefono):
		_restante -= maxf(delta, 0.0)
		if _restante <= 0.0 or Jornada.hora_minutos(dia.jornada) >= int(_llamada.get("hasta", 0)):
			_ignorar(dia)
		return

	if not _puede_sonar(dia):
		return
	var siguiente := LlamadasInternas.siguiente(dia.jornada)
	if siguiente.is_empty():
		return
	_lanzar(dia, mundo, siguiente)


func _exit_tree() -> void:
	_limpiar(get_parent(), true)


func _puede_sonar(dia: Node) -> bool:
	if dia.partida == null or dia.partida.guardado_pendiente:
		return false
	if dia.get("_pantalla") != null or dia.get("_entrada") != null:
		return false
	if is_instance_valid(dia.get("_dialogo_actual")):
		return false
	var caminante := dia.get("_caminante") as Node3D
	return is_instance_valid(caminante) and caminante.is_physics_processing()


func _lanzar(dia: Node, mundo: Node3D, llamada: Dictionary) -> bool:
	var puesto := mundo.get_node_or_null("PuestoUtileria2") as Node3D
	if puesto == null:
		return false
	var visual := puesto.get_node_or_null("TelefonoBase") as Node3D
	if visual == null:
		return false

	var telefono := Interactuable3D.new()
	telefono.name = NOMBRE_INTERACCION
	telefono.position = visual.position + Vector3(0.0, 0.16, 0.0)
	telefono.verbo = Interactuable3D.Verbo.USAR
	telefono.sonido = "marcar"
	telefono.nombre_objeto = String(llamada.get("prompt", "teléfono interno"))
	puesto.add_child(telefono)

	var colision := CollisionShape3D.new()
	colision.name = "VolumenLlamada"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.58, 0.42, 0.58)
	colision.shape = forma
	telefono.add_child(colision)

	var hablante := CompaneroInteractivo3D.new()
	hablante.name = NOMBRE_HABLANTE
	hablante.nombre_visible = "Teléfono interno"
	hablante.habilitado = false
	hablante.collision_layer = 0
	hablante.collision_mask = 0
	hablante.position = Vector3.ZERO
	telefono.add_child(hablante)

	if not LlamadasInternas.iniciar(dia.jornada, llamada):
		telefono.queue_free()
		return false

	_llamada = llamada.duplicate(true)
	_telefono = telefono
	_hablante = hablante
	_restante = DURACION_TIMBRE
	telefono.activado.connect(_atender.bind(dia))
	return true


func _atender(actor: Node, dia: Node) -> void:
	if not is_instance_valid(_telefono):
		return
	var resultado := LlamadasInternas.resolver(dia.jornada, _llamada, "atender")
	if not bool(resultado.get("ok", false)):
		_retirar_telefono()
		return

	if bool(resultado.get("reaccion_companero", false)):
		var companeros := dia.get_node_or_null("CompanerosIdleController")
		if companeros != null and companeros.has_method("reaccion_llamada_interna"):
			companeros.call("reaccion_llamada_interna")

	var hud := dia.get("_hud_prioridades") as HUDLayer
	var caminante := actor as Node3D
	if caminante == null:
		caminante = dia.get("_caminante") as Node3D
	if hud != null and caminante != null and is_instance_valid(_hablante):
		var panel := (
			DialogoDiegetico
			. mostrar(
				hud,
				caminante,
				_hablante,
				String(resultado.get("respuesta", "")),
			)
		)
		dia.set("_dialogo_actual", panel)
	_retirar_telefono()


func _ignorar(dia: Node) -> void:
	if not _llamada.is_empty():
		LlamadasInternas.cancelar_activa(dia.jornada, _llamada)
	_retirar_telefono()


func _limpiar(dia: Node, ignorar: bool) -> void:
	if ignorar and dia != null and not _llamada.is_empty():
		LlamadasInternas.cancelar_activa(dia.jornada, _llamada)
	_retirar_telefono()
	_mundo_id = 0


func _retirar_telefono() -> void:
	if is_instance_valid(_telefono):
		_telefono.queue_free()
	_telefono = null
	_hablante = null
	_llamada = {}
	_restante = 0.0
