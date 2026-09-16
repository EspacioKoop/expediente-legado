## Wiring jugable del incidente de conducta de #209.
##
## La regla vive en `IncidentesConducta`; este controller solo coloca una pared
## interactuable en la oficina y traduce el resultado declarativo a mundo 3D,
## reacción social y transición. No ficha salida ni concede recompensas.
extends Node

const POSICION_PARED := Vector3(-6.78, 1.0, 1.15)
const TAM_PARED := Vector3(0.28, 1.85, 1.8)
const DEMORA_TRANSICION := 0.55

var _mundo_id := 0
var _resolviendo := false


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var id := mundo.get_instance_id()
	if id == _mundo_id:
		return
	_mundo_id = id
	_resolviendo = false
	if String(dia.jornada.get("fase", "")) != "archivo":
		return
	_montar_pared(dia, mundo)


func _montar_pared(dia: Node, mundo: Node3D) -> void:
	var pared := Interactuable3D.new()
	pared.name = "ParedGolpeableOficina"
	pared.position = POSICION_PARED
	pared.verbo = Interactuable3D.Verbo.GOLPEAR
	pared.nombre_objeto = "pared"
	pared.activado.connect(_al_golpear.bind(dia, pared))
	mundo.add_child(pared)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = TAM_PARED
	colision.shape = forma
	pared.add_child(colision)


func _al_golpear(_actor: Node, dia: Node, pared: Interactuable3D) -> void:
	if _resolviendo or dia._pantalla != null or dia.partida.guardado_pendiente:
		return
	if String(dia.jornada.get("fase", "")) != "archivo":
		return

	var resultado := IncidentesConducta.registrar_en_partida(
		dia.partida.estado, IncidentesConducta.GOLPE_PARED, IncidentesConducta.OFICINA
	)
	if resultado.is_empty():
		return

	_resolviendo = true
	pared.habilitado = false
	Sonido.sonar_stream(dia, Sonido.impacto_careo())
	if String(resultado.get("reaccion", "")) == "huir":
		_reaccionar_companeros(dia, pared.global_position)

	# El medio segundo existe para que la reacción sea legible antes de que el
	# mundo se desmonte. Durante él no se puede caminar ni volver a interactuar.
	dia._caminante.set_physics_process(false)
	await dia.get_tree().create_timer(DEMORA_TRANSICION).timeout
	if not is_instance_valid(dia) or not is_instance_valid(dia._caminante):
		return
	dia._caminante.set_physics_process(true)

	if bool(resultado.get("despido", false)):
		_despedir(dia)
		return
	if bool(resultado.get("fin_jornada", false)):
		# Deliberadamente NO llama a Jornada.fichar_salida: la expulsión no
		# paga nómina ni gasta/concede acciones. Se entra en casa y se persiste
		# el estado ya mutado por IncidentesConducta.
		dia._entrar_en("casa")
		dia._guardar_o_avisar("")


func _reaccionar_companeros(dia: Node, origen: Vector3) -> void:
	var controller := dia.get_node_or_null("CompanerosIdleController")
	if controller != null and controller.has_method("huir_de"):
		controller.huir_de(origen)


func _despedir(dia: Node) -> void:
	# La reincidencia es despido directo, no una vida de daño. Se reutiliza la
	# única ruta que ya reinicia Prometeo + Jornada para una nueva vida laboral.
	var vidas := maxi(1, int(dia.partida.estado.get("vida", 1)))
	var castigo := Acusacion.perder_vida(dia.partida.estado, dia.jornada, vidas)
	if not bool(castigo.get("despido", false)):
		return
	dia._guardar_o_avisar("")
	dia._reasignar()
