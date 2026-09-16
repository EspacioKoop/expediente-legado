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
	_probar_brazos_cruzados_intermitentes()
	_probar_reduccion_sin_gestos()
	_probar_conversacion_y_retorno()
	_probar_controller_enlaza_conversaciones()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_brazos_cruzados_intermitentes() -> void:
	var cuerpo := _persona(root)
	var idle := _idle(cuerpo, false, false, false, true)
	_comprobar(idle.actividad_brazos, "quien no trabaja se cruza de brazos")
	idle._reloj_actividad = 0.5
	idle._process(0.01)
	_comprobar(_clip(cuerpo) == "ual/brazos_cruzados", "dentro de la ventana cruza los brazos")
	idle._reloj_actividad = CompaneroIdle3D.DURACION_BRAZOS_CRUZADOS + 0.5
	idle._process(0.01)
	_comprobar(not _clip(cuerpo).begins_with("ual/"), "fuera de la ventana vuelve a idle")
	var trabajador := _idle(_persona(root), false, false, true, true)
	_comprobar(not trabajador.actividad_brazos, "trabajar y cruzar brazos no se solapan")
	var telefono := _idle(_persona(root), true, false, false, true)
	_comprobar(not telefono.actividad_brazos, "al teléfono no se cruzan brazos")
	_liberar()


func _probar_reduccion_sin_gestos() -> void:
	var cuerpo := _persona(root)
	var idle := _idle(cuerpo, false, true, false, true)
	idle._reloj_actividad = 0.5
	idle._process(0.01)
	_comprobar(not _clip(cuerpo).begins_with("ual/"), "reducción de movimiento sin brazos")
	idle.conversar(true)
	_comprobar(not idle.esta_conversando(), "reducción de movimiento sin gesto al hablar")
	_liberar()


func _probar_conversacion_y_retorno() -> void:
	var cuerpo := _persona(root)
	var idle := _idle(cuerpo, true, false)
	idle.conversar(true)
	_comprobar(idle.esta_conversando(), "conversa al pedirlo")
	_comprobar(_clip(cuerpo) == "ual/conversar", "gesticula al hablar")
	idle._reloj_actividad = 0.1
	idle._process(0.01)
	_comprobar(_clip(cuerpo) == "ual/conversar", "la rutina no interrumpe la conversación")
	idle.conversar(false)
	_comprobar(_clip(cuerpo) == "ual/telefono", "al terminar vuelve al teléfono")

	var otro := _persona(root)
	var huido := _idle(otro, false, false)
	huido.conversar(true)
	huido.huir_de(Vector3(5, 0, 5))
	_comprobar(not huido.esta_conversando(), "huir corta la conversación")
	_liberar()


func _probar_controller_enlaza_conversaciones() -> void:
	var dia := DiaFalso.new()
	dia._mundo = Node3D.new()
	root.add_child(dia)
	dia.add_child(dia._mundo)
	var sitios: Array = EspaciosCatalogo.OFICINA["sitios_companeros"]
	for sitio in sitios:
		var cuerpo := _persona(dia._mundo)
		cuerpo.position = sitio
	var conversable := CompaneroInteractivo3D.new()
	conversable.clave_dialogo = "frase"
	conversable.position = sitios[1] + Vector3(0.0, Controller.ALTURA_CONVERSABLE, 0.0)
	dia._mundo.add_child(conversable)

	var controller: Node = Controller.new()
	dia.add_child(controller)
	controller._process(0.01)
	_comprobar(controller._idles.size() == sitios.size(), "monta un idle por sitio")
	var idle: CompaneroIdle3D = controller._idles[1]

	dia._dialogo_actual = PanelContainer.new()
	dia.add_child(dia._dialogo_actual)
	conversable.interactuar(null)
	_comprobar(idle.esta_conversando(), "hablar con el volumen hace gesticular a su cuerpo")
	for otro in controller._idles:
		if otro != idle:
			_comprobar(not otro.esta_conversando(), "solo gesticula el interlocutor")
	controller._process(0.01)
	_comprobar(idle.esta_conversando(), "sigue mientras el diálogo está abierto")
	dia._dialogo_actual.free()
	controller._process(0.01)
	_comprobar(not idle.esta_conversando(), "al cerrarse el diálogo deja de gesticular")
	dia.free()


func _persona(padre: Node) -> Node3D:
	var cuerpo := Node3D.new()
	padre.add_child(cuerpo)
	Modelos.persona(cuerpo, "persona", Color.GRAY)
	return cuerpo


func _idle(
	cuerpo: Node3D,
	telefono: bool,
	reducir: bool,
	trabajo: bool = false,
	brazos: bool = false,
) -> CompaneroIdle3D:
	var idle := CompaneroIdle3D.new()
	idle.add_to_group("prueba_gestos")
	cuerpo.add_child(idle)
	idle.configurar(cuerpo, 134, telefono, reducir, trabajo, brazos)
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
