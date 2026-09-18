extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_eco_local_no_intrusivo()
	_probar_idempotencia_y_objetivo_completado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_eco_local_no_intrusivo() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var zona := Area3D.new()
	zona.name = "ObjetivoSueno_Prueba_0"
	mundo.add_child(zona)
	var caminante := CharacterBody3D.new()
	mundo.add_child(caminante)
	var intruso := Node3D.new()
	mundo.add_child(intruso)

	var controlador := SuenoObjetivosLegibilidad.new()
	root.add_child(controlador)
	var ecos := controlador.montar_en(mundo, caminante)
	_comprobar(ecos.size() == 1, "monta un eco por objetivo pendiente")
	if ecos.size() == 1:
		var luz := ecos[0] as OmniLight3D
		_comprobar(luz != null, "el eco es iluminación 3D, no HUD")
		_comprobar(luz.omni_range <= 3.5, "la señal queda limitada al entorno local")
		_comprobar(luz.light_energy <= 0.5, "la señal conserva intensidad discreta")
		_comprobar(not luz.shadow_enabled, "el eco no añade sombras costosas")
		controlador._al_entrar_objetivo(intruso, zona, luz, caminante)
		_comprobar(luz.visible, "otro cuerpo no consume la señal del jugador")
		controlador._al_entrar_objetivo(caminante, zona, luz, caminante)
		_comprobar(not luz.visible, "la señal desaparece al alcanzar el objetivo")
		_comprobar(zona.monitoring, "la capa visual no desactiva ni completa el objetivo")

	controlador.queue_free()
	mundo.queue_free()


func _probar_idempotencia_y_objetivo_completado() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var pendiente := Area3D.new()
	pendiente.name = "ObjetivoSueno_Prueba_1"
	mundo.add_child(pendiente)
	var completado := Area3D.new()
	completado.name = "ObjetivoSueno_Prueba_2"
	completado.monitoring = false
	mundo.add_child(completado)

	var controlador := SuenoObjetivosLegibilidad.new()
	root.add_child(controlador)
	var primero := controlador.montar_en(mundo)
	var segundo := controlador.montar_en(mundo)
	_comprobar(primero.size() == 1, "ignora zonas ya desactivadas por progreso")
	_comprobar(segundo.size() == 1, "remontar no duplica ecos")
	_comprobar(
		pendiente.find_children("EcoLegibilidadObjetivo", "OmniLight3D", false, false).size() == 1,
		"cada objetivo conserva una única señal",
	)
	_comprobar(
		completado.get_node_or_null("EcoLegibilidadObjetivo") == null,
		"un objetivo ya completado no recupera señal",
	)

	controlador.queue_free()
	mundo.queue_free()


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error(descripcion)
