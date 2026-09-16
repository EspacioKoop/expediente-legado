extends SceneTree

const Controller := preload("res://guion/dia_companeros_idle_app.gd")


class DiaFalso:
	extends Node
	var jornada := {"fase": "archivo"}
	var _mundo: Node3D
	var _dialogo_actual: Control


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	process_frame.connect(_ejecutar, CONNECT_ONE_SHOT)


func _ejecutar() -> void:
	await _probar_navegacion_rodea_muebles()
	_probar_ciclo_completo()
	_probar_inicio_invalido()
	_probar_pausa_al_hablar()
	_probar_huida_cancela()
	await _probar_controller()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_navegacion_rodea_muebles() -> void:
	var mundo := _sala()
	var mesa := _caja(mundo, Vector3(0.0, 0.4, 0.0), Vector3(4.0, 0.8, 1.0))
	var region := NavegacionOficina.montar(mundo)
	await _sincronizar()
	var ruta := NavegacionOficina.ruta(region, Vector3(0, 0, -2), Vector3(0, 0, 2))
	_comprobar(ruta.size() >= 3, "hay camino rodeando la mesa")
	var dentro := false
	for punto in ruta:
		if absf(punto.x) < 1.9 and absf(punto.z) < 0.4:
			dentro = true
	_comprobar(not dentro, "el camino no atraviesa la mesa")
	_comprobar(mesa is StaticBody3D, "la malla sale de los colliders del espacio")
	mundo.free()


func _probar_ciclo_completo() -> void:
	var cuerpo := _persona(root, Vector3(1, 0, 2))
	var idle := _idle_sentado(cuerpo)
	var postura := cuerpo.transform
	var recado := RecadoCompanero3D.new()
	idle.add_child(recado)
	var ruta := PackedVector3Array([Vector3(1, 0.2, 2), Vector3(1, 0.2, 3.5), Vector3(3, 0.2, 3.5)])
	_comprobar(
		recado.iniciar(idle, ruta, Vector3(4, 0, 3.5)), "un compañero sentado acepta el recado"
	)
	_comprobar(idle.en_recado(), "la rutina queda en pausa")
	var fases := [recado.fase]
	var clips := {}
	var pasos := 0
	while (
		is_instance_valid(recado) and recado.fase != RecadoCompanero3D.Fase.HECHO and pasos < 2000
	):
		idle._process(0.05)
		recado._process(0.05)
		if not is_instance_valid(recado):
			break
		if fases.back() != recado.fase:
			fases.append(recado.fase)
		clips[_clip(cuerpo)] = true
		if recado.fase == RecadoCompanero3D.Fase.IR or recado.fase == RecadoCompanero3D.Fase.VOLVER:
			_comprobar(is_zero_approx(cuerpo.position.y), "anda sobre el suelo del sitio")
		pasos += 1
	var esperado := [
		RecadoCompanero3D.Fase.LEVANTARSE,
		RecadoCompanero3D.Fase.IR,
		RecadoCompanero3D.Fase.GESTO,
		RecadoCompanero3D.Fase.VOLVER,
		RecadoCompanero3D.Fase.SENTARSE,
	]
	_comprobar(fases.slice(0, 5) == esperado, "recorre las fases en orden: %s" % [fases])
	for clip in ["ual/levantarse", "ual/andar", "ual/coger", "ual/andar_cargando", "ual/sentarse"]:
		_comprobar(clips.has(clip), "usa el clip %s" % clip)
	_comprobar(pasos < 2000, "el recado termina")
	_comprobar(not idle.en_recado(), "al terminar la rutina vuelve")
	_comprobar(
		cuerpo.transform.origin.is_equal_approx(postura.origin), "vuelve a su postura sentada"
	)
	_comprobar(_clip(cuerpo).begins_with("ual/sentado"), "y sigue sentado")
	_liberar()


func _probar_inicio_invalido() -> void:
	var de_pie := _persona(root, Vector3.ZERO)
	var idle := CompaneroIdle3D.new()
	de_pie.add_child(idle)
	idle.configurar(de_pie, 7, false, false, false, true, false)
	var recado := RecadoCompanero3D.new()
	idle.add_child(recado)
	var ruta := PackedVector3Array([Vector3.ZERO, Vector3(2, 0, 0)])
	_comprobar(not recado.iniciar(idle, ruta, Vector3.ZERO), "quien está de pie no hace recados")
	var sentado := _idle_sentado(_persona(root, Vector3(3, 0, 0)))
	var otro := RecadoCompanero3D.new()
	sentado.add_child(otro)
	_comprobar(
		not otro.iniciar(sentado, PackedVector3Array(), Vector3.ZERO), "sin ruta no hay recado"
	)
	_comprobar(not sentado.en_recado(), "y la rutina sigue")
	_liberar()


func _probar_pausa_al_hablar() -> void:
	var cuerpo := _persona(root, Vector3(1, 0, 2))
	var idle := _idle_sentado(cuerpo)
	var recado := _recado_en_marcha(idle)
	idle.conversar(true)
	_comprobar(recado.esta_pausado(), "hablarle a mitad de recado lo detiene")
	_comprobar(_clip(cuerpo) == "ual/conversar", "y habla de pie")
	var parado := cuerpo.position
	recado._process(0.5)
	_comprobar(cuerpo.position.is_equal_approx(parado), "no se mueve mientras habla")
	idle.conversar(false)
	_comprobar(not recado.esta_pausado(), "al terminar la conversación sigue")
	_comprobar(_clip(cuerpo) == "ual/andar", "y retoma el paso")
	_liberar()


func _probar_huida_cancela() -> void:
	var cuerpo := _persona(root, Vector3(1, 0, 2))
	var idle := _idle_sentado(cuerpo)
	var recado := _recado_en_marcha(idle)
	idle.huir_de(Vector3(5, 0, 5))
	_comprobar(recado.is_queued_for_deletion(), "huir cancela el recado")
	_comprobar(not idle.sentado, "y no vuelve a sentarse")
	_liberar()


func _probar_controller() -> void:
	var dia := DiaFalso.new()
	dia._mundo = _sala()
	root.remove_child(dia._mundo)
	root.add_child(dia)
	dia.add_child(dia._mundo)
	var sitios: Array = EspaciosCatalogo.OFICINA["sitios_companeros"]
	for sitio in sitios:
		_persona(dia._mundo, sitio)
	var conversables := []
	for sitio in sitios:
		var conversable := CompaneroInteractivo3D.new()
		conversable.clave_dialogo = "frase"
		conversable.position = sitio + Vector3.UP * Controller.ALTURA_CONVERSABLE
		dia._mundo.add_child(conversable)
		conversables.append(conversable)
	var controller: Node = Controller.new()
	dia.add_child(controller)
	controller._process(0.01)
	await _sincronizar()

	var destinos: Array = Controller.destinos_recado(dia._mundo)
	_comprobar(not destinos.is_empty(), "los archivadores del catálogo son destinos")
	for destino in destinos:
		_comprobar(absf(destino["pie"].x) < 5.5, "se para delante del archivador, no dentro")

	controller._seguir_recados(dia._mundo, Controller.PRIMER_RECADO - 1.0)
	_comprobar(not controller._hay_recado(), "antes de tiempo no hay recados")
	controller._seguir_recados(dia._mundo, 1.5)
	_comprobar(controller._hay_recado(), "al cumplirse el plazo alguien se levanta")
	var recado: RecadoCompanero3D = null
	var quien: CompaneroIdle3D = null
	for idle in controller._idles:
		if idle.en_recado():
			recado = idle.recado
			quien = idle
	_comprobar(quien != null and quien.sentado, "va quien estaba sentado")
	_comprobar(controller.lanzar_recado(dia._mundo) == null, "nunca dos recados a la vez")

	for i in 60:
		recado._process(0.1)
	controller._seguir_recados(dia._mundo, 0.0)
	var conversable: Node3D = controller._conversables[quien]
	_comprobar(
		Vector2(conversable.position.x, conversable.position.z).is_equal_approx(
			Vector2(quien.objetivo.position.x, quien.objetivo.position.z)
		),
		"el volumen para hablarle le sigue"
	)
	controller._reducir = true
	recado.cancelar()
	await process_frame
	controller._seguir_recados(dia._mundo, Controller.INTERVALO_RECADO * 3.0)
	_comprobar(not controller._hay_recado(), "con reducción de movimiento no hay recados")
	dia.free()


func _recado_en_marcha(idle: CompaneroIdle3D) -> RecadoCompanero3D:
	var recado := RecadoCompanero3D.new()
	idle.add_child(recado)
	var ruta := PackedVector3Array([Vector3(1, 0, 2), Vector3(1, 0, 6)])
	recado.iniciar(idle, ruta, Vector3(1, 0, 7))
	recado._process(AnimacionesUAL.duracion("levantarse") + 0.01)
	recado._process(0.5)
	return recado


func _sala() -> Node3D:
	var mundo := Node3D.new()
	root.add_child(mundo)
	_caja(mundo, Vector3(0, -0.1, 0), Vector3(14, 0.2, 10))
	return mundo


func _caja(mundo: Node3D, pos: Vector3, tam: Vector3) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = tam
	forma.shape = caja
	cuerpo.add_child(forma)
	mundo.add_child(cuerpo)
	return cuerpo


## El servidor de navegación aplica los cambios al sincronizar el mapa en
## fotogramas de física posteriores: se espera a que la iteración avance desde
## que se montó la región, no a una iteración de una prueba anterior.
func _sincronizar() -> void:
	var mapa: RID = root.get_world_3d().navigation_map
	var inicial := NavigationServer3D.map_get_iteration_id(mapa)
	for i in 60:
		await physics_frame
		if NavigationServer3D.map_get_iteration_id(mapa) >= inicial + 2:
			return


func _persona(padre: Node, pos: Vector3) -> Node3D:
	var cuerpo := Node3D.new()
	padre.add_child(cuerpo)
	cuerpo.position = pos
	Modelos.persona(cuerpo, "persona", Color.GRAY)
	return cuerpo


func _idle_sentado(cuerpo: Node3D) -> CompaneroIdle3D:
	var idle := CompaneroIdle3D.new()
	cuerpo.add_child(idle)
	idle.configurar(cuerpo, 400, false, false, true, false, true)
	return idle


func _clip(cuerpo: Node3D) -> String:
	return String(Modelos._reproductor(cuerpo).current_animation)


func _liberar() -> void:
	for hijo in root.get_children():
		if hijo is Node3D:
			hijo.free()


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
