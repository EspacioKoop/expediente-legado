extends SceneTree

var fallos := 0
var pasadas := 0


class DiaPrueba:
	extends "res://guion/dia_gato_app.gd"
	var guardados := 0
	var entradas := 0

	func _ready() -> void:
		set_process(false)
		set_process_input(false)

	func _guardar_o_avisar(_destino: String) -> bool:
		guardados += 1
		return true

	func _al_pisar_objetivo(cuerpo: Node3D, zona: Area3D) -> void:
		entradas += 1
		super._al_pisar_objetivo(cuerpo, zona)


func _initialize() -> void:
	call_deferred("probar")


func probar() -> void:
	var dia := DiaPrueba.new()
	root.add_child(dia)
	dia.jornada = {"fase": "sueño", "dia": 1}
	dia._objetivo_escena = "sintetica"
	dia._objetivos_espacio = [{"id": "primero"}, {"id": "segundo"}]
	dia._rotulo = Label.new()
	dia.add_child(dia._rotulo)
	dia._ambiente = Environment.new()
	var zona := Area3D.new()
	zona.set_meta("objetivo", "primero")
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	zona.add_child(forma)
	dia.add_child(zona)
	zona.body_entered.connect(dia._al_pisar_objetivo.bind(zona))
	var cuerpo := CharacterBody3D.new()
	var colision := CollisionShape3D.new()
	colision.shape = BoxShape3D.new()
	cuerpo.add_child(colision)
	cuerpo.position = Vector3(10, 0, 0)
	dia.add_child(cuerpo)
	dia._caminante = cuerpo
	await create_timer(0.15).timeout
	comprobar(dia.entradas == 0)
	cuerpo.position = Vector3.ZERO
	await create_timer(0.15).timeout
	comprobar(dia.entradas == 1)
	comprobar(not zona.monitoring)
	comprobar(SuenoObjetivos.progreso(dia._estado_objetivos_actual()) == Vector2i(1, 2))
	comprobar(dia.guardados == 1)
	comprobar(not SuenoObjetivos.resuelto(dia._estado_objetivos_actual()))
	cuerpo.position = Vector3(10, 0, 0)
	await create_timer(0.15).timeout
	cuerpo.position = Vector3.ZERO
	await create_timer(0.15).timeout
	comprobar(dia.entradas == 1)
	comprobar(dia.guardados == 1)
	comprobar(SuenoObjetivos.progreso(dia._estado_objetivos_actual()) == Vector2i(1, 2))
	dia.free()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos else 0)


func comprobar(condicion: bool) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		push_error("Fallo en comprobación %d" % (pasadas + fallos))
