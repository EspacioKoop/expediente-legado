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
	_probar_sentarse_y_restaurar()
	_probar_actividad_sentado()
	_probar_exclusiones()
	_probar_oficina_sin_sillas_atravesadas()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_sentarse_y_restaurar() -> void:
	var cuerpo := _persona(root)
	cuerpo.position = Vector3(1.0, 0.0, 2.1)
	var idle := _idle(cuerpo, false, false, true, false, true)
	_comprobar(idle.sentado, "quien trabaja en su puesto se sienta")
	_comprobar(is_equal_approx(cuerpo.rotation.y, PI), "sentado mira a su mesa")
	var esperado := Vector3(
		1.0, CompaneroIdle3D.ALTURA_ASIENTO, 2.1 - CompaneroIdle3D.ADELANTO_SENTADO
	)
	_comprobar(cuerpo.position.is_equal_approx(esperado), "sube al asiento y se acerca a la mesa")
	idle.free()
	_comprobar(
		cuerpo.position.is_equal_approx(Vector3(1.0, 0.0, 2.1)), "al desmontar vuelve a su sitio"
	)
	_comprobar(is_zero_approx(cuerpo.rotation.y), "y a su giro")
	_comprobar(not _clip(cuerpo).begins_with("ual/"), "y a su idle de pie")
	_liberar()


func _probar_actividad_sentado() -> void:
	var cuerpo := _persona(root)
	var idle := _idle(cuerpo, false, false, true, false, true)
	idle._reloj_actividad = 0.5
	idle._process(0.01)
	_comprobar(_clip(cuerpo) == "ual/sentado_hablando", "trabaja sentado sin levantarse")
	idle._reloj_actividad = CompaneroIdle3D.DURACION_TRABAJO + 0.5
	idle._process(0.01)
	_comprobar(_clip(cuerpo) == "ual/sentado", "descansa sentado")
	idle.conversar(true)
	_comprobar(_clip(cuerpo) == "ual/sentado_hablando", "habla sentado")
	idle.conversar(false)
	_comprobar(_clip(cuerpo) == "ual/sentado", "y vuelve a su pausa sentado")

	var reducido := _persona(root)
	var quieto := _idle(reducido, false, true, true, false, true)
	quieto._reloj_actividad = 0.5
	quieto._process(0.01)
	_comprobar(quieto.sentado, "reducción de movimiento no levanta a nadie")
	_comprobar(_clip(reducido) == "ual/sentado", "pero no hay gesto de trabajo")
	_liberar()


func _probar_exclusiones() -> void:
	var al_telefono := _idle(_persona(root), true, false, false, false, true)
	_comprobar(not al_telefono.sentado, "el teléfono se atiende de pie")
	var cruzado := _idle(_persona(root), false, false, false, true, true)
	_comprobar(cruzado.sentado, "puede sentarse quien no trabaja")
	_comprobar(not cruzado.actividad_brazos, "pero sentado no se cruza de brazos")
	var cuerpo := _persona(root)
	var huido := _idle(cuerpo, false, false, true, false, true)
	huido.huir_de(Vector3(5, 0, 5))
	_comprobar(not huido.sentado, "huir levanta de la silla")
	_liberar()


func _probar_oficina_sin_sillas_atravesadas() -> void:
	var dia := DiaFalso.new()
	dia._mundo = Node3D.new()
	root.add_child(dia)
	dia.add_child(dia._mundo)
	for sitio in EspaciosCatalogo.OFICINA["sitios_companeros"]:
		_persona(dia._mundo).position = sitio
	var controller: Node = Controller.new()
	dia.add_child(controller)
	controller._process(0.01)

	var sillas := []
	for bulto in EspaciosCatalogo.OFICINA["bultos"]:
		if String(bulto.get("modelo", "")) == "chairDesk":
			sillas.append(Vector2(bulto["pos"].x, bulto["pos"].z))
	var sentados := 0
	for idle in controller._idles:
		var sitio := Vector2(idle.sitio().x, idle._posicion_original.z)
		var mas_cercana := INF
		for silla in sillas:
			mas_cercana = minf(mas_cercana, sitio.distance_to(silla))
		if idle.sentado:
			sentados += 1
			_comprobar(mas_cercana < 0.05, "quien se sienta lo hace en una silla")
		else:
			_comprobar(mas_cercana > 0.5, "quien está de pie no atraviesa una silla")
	_comprobar(sentados >= 2, "hay compañeros sentados en la oficina")
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
	trabajo: bool,
	brazos: bool,
	en_silla: bool,
) -> CompaneroIdle3D:
	var idle := CompaneroIdle3D.new()
	cuerpo.add_child(idle)
	idle.configurar(cuerpo, 134, telefono, reducir, trabajo, brazos, en_silla)
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
