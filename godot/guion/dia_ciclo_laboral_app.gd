## Ciclo laboral y UI temporal de nueva vida (#1761).
##
## DiaApp conserva los hooks heredables y decide cuándo invocarlos. Este helper
## posee únicamente la entrada de vuelta, la decisión de último recurso y la
## selección de auditorías de una nueva vida. Las reglas siguen en sus dominios.
class_name DiaCicloLaboralApp
extends RefCounted

const ESCENA_ENTRADA := preload("res://escenas/cinematica.tscn")

var entrada: Node3D
var ultimo_recurso: UltimoRecursoApp
var auditorias_nueva_vida: AuditoriasNuevaVidaApp


func abrir_ultimo_recurso_pendiente(
	parent: Node,
	estado: Dictionary,
	caminante: CharacterBody3D,
	al_canje: Callable,
	al_cese: Callable,
) -> void:
	if not Acusacion.despido_pendiente(estado):
		return
	if is_instance_valid(ultimo_recurso):
		ultimo_recurso.actualizar(estado)
		return
	if is_instance_valid(caminante):
		caminante.set_physics_process(false)
	ultimo_recurso = UltimoRecursoApp.new()
	ultimo_recurso.name = "UltimoRecurso"
	ultimo_recurso.canje_solicitado.connect(al_canje)
	ultimo_recurso.cese_solicitado.connect(al_cese)
	parent.add_child(ultimo_recurso)
	ultimo_recurso.abrir(estado)


func canjear_ultimo_recurso(
	parent: Node,
	estado: Dictionary,
	jornada: Dictionary,
	carta_id: String,
	guardar: Callable,
	caminante: CharacterBody3D,
) -> void:
	var resultado := Acusacion.canjear_carta_por_vida(estado, carta_id)
	if String(resultado.get("resultado", "")) != "canje":
		if is_instance_valid(ultimo_recurso):
			ultimo_recurso.actualizar(estado)
		return

	ClimaxHastur.reanudar_tras_ultimo_recurso(estado, jornada)
	var guardado := bool(guardar.call(""))
	cerrar_ultimo_recurso()
	if not guardado:
		if is_instance_valid(caminante):
			caminante.set_physics_process(true)
		return

	var climax := parent.get_node_or_null("ClimaxHasturOwnerController")
	if climax != null and climax.has_method("_reanudar_si_procede"):
		climax.call_deferred("_reanudar_si_procede")
	elif is_instance_valid(caminante):
		caminante.set_physics_process(true)


func aceptar_cese(
	estado: Dictionary,
	jornada: Dictionary,
	guardar: Callable,
	reasignar: Callable,
) -> void:
	var resultado := Acusacion.aceptar_cese(estado, jornada)
	if not bool(resultado.get("despido", false)):
		if is_instance_valid(ultimo_recurso):
			ultimo_recurso.actualizar(estado)
		return
	guardar.call("")
	cerrar_ultimo_recurso()
	reasignar.call()


func cerrar_ultimo_recurso() -> void:
	if is_instance_valid(ultimo_recurso):
		ultimo_recurso.queue_free()
	ultimo_recurso = null


func abrir_vuelta(
	parent: Node,
	estado: Dictionary,
	jornada: Dictionary,
	caminante: CharacterBody3D,
	hud: CanvasLayer,
	abrir_auditorias: Callable,
	al_cerrar: Callable,
	sello_reincorporacion: String,
) -> void:
	if jornada["fase"] != "archivo" or jornada["dia"] != 1:
		return
	if jornada["acciones"] != Jornada.ACCIONES_POR_DIA:
		return
	if int(jornada.get("vuelta", 1)) > 1 and Auditorias.seleccion_pendiente(estado):
		abrir_auditorias.call()
		return

	registrar_reincorporacion(estado, jornada, sello_reincorporacion)

	if is_instance_valid(caminante):
		caminante.set_physics_process(false)
	if is_instance_valid(hud):
		hud.visible = false

	entrada = ESCENA_ENTRADA.instantiate()
	parent.add_child(entrada)
	entrada.terminada.connect(al_cerrar)
	var vistas := Cinematica.vistas_de(estado, EntradaCinematica.ID)
	entrada.reproducir(EntradaCinematica.planos_de(vistas), EntradaCinematica.ID, estado)


func abrir_auditorias(
	parent: Node,
	estado: Dictionary,
	caminante: CharacterBody3D,
	hud: CanvasLayer,
	al_confirmar: Callable,
) -> void:
	if is_instance_valid(auditorias_nueva_vida):
		return
	if is_instance_valid(caminante):
		caminante.set_physics_process(false)
	if is_instance_valid(hud):
		hud.visible = false
	auditorias_nueva_vida = AuditoriasNuevaVidaApp.new()
	auditorias_nueva_vida.name = "AuditoriasNuevaVida"
	auditorias_nueva_vida.seleccion_confirmada.connect(al_confirmar)
	parent.add_child(auditorias_nueva_vida)
	auditorias_nueva_vida.abrir(estado)


func confirmar_auditorias(
	estado: Dictionary,
	seleccion: Array,
	guardar: Callable,
	reabrir_vuelta: Callable,
) -> void:
	var anterior := Dictionary(estado.get(Auditorias.CLAVE_ESTADO, {})).duplicate(true)
	if not Auditorias.resolver_seleccion(estado, seleccion):
		return
	if not bool(guardar.call("")):
		estado[Auditorias.CLAVE_ESTADO] = anterior
		return
	if is_instance_valid(auditorias_nueva_vida):
		auditorias_nueva_vida.queue_free()
	auditorias_nueva_vida = null
	reabrir_vuelta.call()


func registrar_reincorporacion(
	estado: Dictionary,
	jornada: Dictionary,
	sello_reincorporacion: String,
) -> Dictionary:
	if int(jornada.get("vuelta", 1)) <= 1:
		return {"resultado": "no-cumplido", "id": sello_reincorporacion}
	return Sellos.registrar_sello(estado, sello_reincorporacion)


func cerrar_vuelta(
	caminante: CharacterBody3D,
	hud: CanvasLayer,
	guardar: Callable,
) -> void:
	if entrada == null:
		return
	entrada.queue_free()
	entrada = null
	if is_instance_valid(caminante):
		caminante.set_physics_process(true)
	if is_instance_valid(hud):
		hud.visible = true
	guardar.call("")
