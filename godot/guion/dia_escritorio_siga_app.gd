## Adaptador del puesto de trabajo al shell de escritorio (#534).
##
## `Dia` sigue siendo dueño de entrar/salir del puesto y de persistir la partida.
## Este controller detecta únicamente la pantalla que contiene el visor histórico,
## lo adopta como una aplicación del shell y deja intactos duelos/cinemáticas.
extends Node

var _pantalla_envuelta_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var pantalla: Variant = dia._pantalla
	if pantalla == null or not is_instance_valid(pantalla):
		_pantalla_envuelta_id = 0
		return
	var id := (pantalla as Node).get_instance_id()
	if id == _pantalla_envuelta_id:
		return
	var visor := (pantalla as Node).get_node_or_null("Visor")
	if visor == null or not visor is Control:
		return
	_pantalla_envuelta_id = id
	_envolver_puesto(dia, pantalla as CanvasLayer, visor as Control)


func _envolver_puesto(dia: Node, pantalla: CanvasLayer, visor: Control) -> void:
	var escritorio := EscritorioSiga.new()
	escritorio.name = "EscritorioSiga"
	pantalla.add_child(escritorio)

	var preferencias := PreferenciasSiga.cargar()
	escritorio.configurar_reduccion_movimiento(
		bool(preferencias.get("reduccion_movimiento", false))
	)
	escritorio.establecer_reloj_narrativo("DÍA %02d" % int(dia.jornada.get("dia", 1)))

	var creador_visor := Callable(self, "_crear_visor")
	escritorio.registrar_aplicacion("siga-98", "SIGA-98", creador_visor)
	escritorio.activar_ayuda_sistema()
	escritorio.adoptar_aplicacion("siga-98", "SIGA-98", visor, creador_visor)
	escritorio.salir_solicitado.connect(_solicitar_salida)

	# `_abrir_expediente()` conserva temporalmente el botón histórico para que
	# la propiedad de salir siga en Dia. El shell ofrece esa acción en su menú,
	# así que se oculta la representación antigua sin desconectar su callback.
	for hijo in pantalla.get_children():
		if hijo is Button:
			(hijo as Button).visible = false


func _crear_visor() -> Control:
	return load("res://escenas/visor.tscn").instantiate() as Control


func _solicitar_salida() -> void:
	var dia := get_parent()
	if dia != null and dia._pantalla != null:
		dia._cerrar_expediente()
