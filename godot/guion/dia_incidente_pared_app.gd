## Wiring jugable del incidente de conducta de #209.
##
## La regla vive en `IncidentesConducta`; este controller solo coloca paredes
## interactuables y traduce el resultado declarativo a mundo 3D. Oficina aplica
## reacción social/transición; casa y sueño reutilizan el gesto sin consecuencias
## laborales ni rutas alternativas de recompensa.
extends Node

const POSICION_PARED_OFICINA := Vector3(-6.78, 1.0, 1.15)
const POSICION_PARED_CASA := Vector3(-3.86, 1.0, 0.55)
const TAM_PARED := Vector3(0.28, 1.85, 1.8)
const TAM_MARCA := Vector3(0.035, 0.22, 0.28)
const DEMORA_TRANSICION := 0.55
const DEMORA_LOCAL := 0.22

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

	match String(dia.jornada.get("fase", "")):
		"archivo":
			_montar_pared(
				dia,
				mundo,
				"ParedGolpeableOficina",
				POSICION_PARED_OFICINA,
				IncidentesConducta.OFICINA,
				Vector3(1, 0, 0),
			)
		"casa":
			_montar_pared(
				dia,
				mundo,
				"ParedGolpeableCasa",
				POSICION_PARED_CASA,
				IncidentesConducta.CASA,
				Vector3(1, 0, 0),
			)
		"sueño":
			_montar_pared_sueno(dia, mundo)


func _montar_pared(
	dia,
	mundo: Node3D,
	nombre: String,
	posicion: Vector3,
	lugar: String,
	normal_interior: Vector3,
) -> void:
	var pared := Interactuable3D.new()
	pared.name = nombre
	pared.position = posicion
	pared.verbo = Interactuable3D.Verbo.GOLPEAR
	pared.nombre_objeto = "pared"
	pared.set_meta("lugar_incidente", lugar)
	pared.set_meta("normal_interior", normal_interior.normalized())
	pared.activado.connect(_al_golpear.bind(dia, pared, lugar))
	mundo.add_child(pared)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = TAM_PARED
	colision.shape = forma
	pared.add_child(colision)


func _montar_pared_sueno(dia, mundo: Node3D) -> void:
	var escenas: Array = dia.jornada.get("sueno_escenas", [])
	if escenas.is_empty():
		return
	var forma := SuenoFormas.de(String(escenas[0]))
	var bloques: Array = forma.get("bloques", [])
	if bloques.is_empty():
		return

	# El sueño cambia de planta. En vez de fijar coordenadas, se toma un tramo
	# vertical real del contorno y se coloca la interacción ligeramente dentro.
	var tramo_elegido: Dictionary = {}
	for tramo in Planta.paredes(bloques, 3):
		if String(tramo.get("eje", "")) == "z":
			tramo_elegido = tramo
			break
	if tramo_elegido.is_empty():
		return

	var anclaje := Planta.en_pared(bloques, tramo_elegido, 0.20)
	var posicion: Vector3 = anclaje.get("pos", Vector3.ZERO)
	posicion.y = 1.0
	var hacia := float(tramo_elegido.get("hacia", 1))
	_montar_pared(
		dia,
		mundo,
		"ParedGolpeableSueno",
		posicion,
		IncidentesConducta.SUENO,
		Vector3(hacia, 0, 0),
	)


func _al_golpear(_actor: Node, dia, pared: Interactuable3D, lugar: String) -> void:
	if _resolviendo or dia._pantalla != null or dia.partida.guardado_pendiente:
		return
	if not _fase_coincide(String(dia.jornada.get("fase", "")), lugar):
		return

	var resultado := IncidentesConducta.registrar_en_partida(
		dia.partida.estado, IncidentesConducta.GOLPE_PARED, lugar
	)
	if resultado.is_empty():
		return

	_resolviendo = true
	pared.habilitado = false
	Sonido.sonar_stream(dia, Sonido.impacto_careo())

	if lugar == IncidentesConducta.CASA:
		# La marca dura mientras exista esta casa 3D, pero no crea otro contador ni
		# toca historial laboral. La regla base devuelve persistir=false.
		_marca_domestica(pared)
		await dia.get_tree().create_timer(DEMORA_LOCAL).timeout
		_liberar_interaccion(pared)
		return

	if lugar == IncidentesConducta.SUENO:
		# El segundo golpe acústico y la deformación efímera son presentación:
		# registrar_en_partida devuelve persistir=false y no escribe estado real.
		_feedback_onirico(pared)
		await dia.get_tree().create_timer(0.10).timeout
		if is_instance_valid(dia):
			Sonido.sonar_stream(dia, Sonido.impacto_careo())
		await dia.get_tree().create_timer(DEMORA_LOCAL).timeout
		_liberar_interaccion(pared)
		return

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
	elif bool(resultado.get("fin_jornada", false)):
		# La expulsión entra directamente en casa: no pasa por la salida laboral,
		# no paga nómina y no gasta ni concede acciones.
		dia._entrar_en("casa")
		dia._guardar_o_avisar("")


func _fase_coincide(fase: String, lugar: String) -> bool:
	return (
		(fase == "archivo" and lugar == IncidentesConducta.OFICINA)
		or (fase == "casa" and lugar == IncidentesConducta.CASA)
		or (fase == "sueño" and lugar == IncidentesConducta.SUENO)
	)


func _liberar_interaccion(pared: Interactuable3D) -> void:
	_resolviendo = false
	if is_instance_valid(pared):
		pared.habilitado = true


func _marca_domestica(pared: Interactuable3D) -> void:
	if pared.has_node("MarcaGolpePared"):
		return
	var marca := MeshInstance3D.new()
	marca.name = "MarcaGolpePared"
	var caja := BoxMesh.new()
	caja.size = TAM_MARCA
	marca.mesh = caja
	var normal: Vector3 = pared.get_meta("normal_interior", Vector3(1, 0, 0))
	marca.position = normal * 0.17
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.16, 0.13, 0.11)
	marca.material_override = material
	pared.add_child(marca)


func _feedback_onirico(pared: Interactuable3D) -> void:
	var eco := MeshInstance3D.new()
	eco.name = "EcoGolpeParedOnirico"
	var caja := BoxMesh.new()
	caja.size = Vector3(0.04, 0.72, 0.72)
	eco.mesh = caja
	var normal: Vector3 = pared.get_meta("normal_interior", Vector3(1, 0, 0))
	eco.position = normal * 0.16
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.56, 0.48, 0.70)
	eco.material_override = material
	pared.add_child(eco)

	# La superficie parece estirarse y plegarse, pero el nodo es efímero: no
	# cambia geometría lógica, objetivos ni guardado del sueño.
	var tween := eco.create_tween()
	tween.tween_property(eco, "scale", Vector3(1.0, 1.8, 3.6), 0.14)
	tween.tween_property(eco, "scale", Vector3(1.0, 0.12, 0.12), 0.20)
	tween.tween_callback(Callable(eco, "queue_free"))


func _reaccionar_companeros(dia, origen: Vector3) -> void:
	var controller: Node = dia.get_node_or_null("CompanerosIdleController")
	if controller != null and controller.has_method("huir_de"):
		controller.huir_de(origen)


func _despedir(dia) -> void:
	# La reincidencia es despido directo, no una vida de daño. Se reutiliza la
	# única ruta que ya reinicia Prometeo + Jornada para una nueva vida laboral.
	var vidas := maxi(1, int(dia.partida.estado.get("vida", 1)))
	var castigo := Acusacion.perder_vida(dia.partida.estado, dia.jornada, vidas)
	# Este incidente ya decidió un cese disciplinario: no ofrece el canje de
	# último recurso propio del agotamiento normal de vidas.
	if bool(castigo.get("despido_pendiente", false)):
		castigo = Acusacion.aceptar_cese(dia.partida.estado, dia.jornada)
	if not bool(castigo.get("despido", false)):
		return
	dia._guardar_o_avisar("")
	dia._reasignar()
