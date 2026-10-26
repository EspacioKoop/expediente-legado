extends SceneTree

const Recorrido := preload("res://guion/catedral_invertida_recorrido_3d.gd")

var _pasadas := 0
var _fallos := 0
var _eventos := 0


func _initialize() -> void:
	_probar_recorrido_completo()
	_probar_reduccion_movimiento()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _nuevo(reducido: bool = false) -> Dictionary:
	var actor := CharacterBody3D.new()
	actor.name = "CaminanteSimulado"
	var camara := Camera3D.new()
	camara.name = "Camara"
	actor.add_child(camara)
	get_root().add_child(actor)
	var recorrido := Recorrido.new()
	recorrido.reduccion_movimiento = reducido
	get_root().add_child(recorrido)
	_comprobar(recorrido.montar_para(actor), "admite actor de la jornada")
	return {"actor": actor, "camara": camara, "recorrido": recorrido}


func _probar_recorrido_completo() -> void:
	var contexto := _nuevo(true)
	var actor: CharacterBody3D = contexto["actor"]
	var camara: Camera3D = contexto["camara"]
	var recorrido: CatedralInvertidaRecorrido3D = contexto["recorrido"]
	recorrido.recorrido_completado.connect(_contar_finales)
	_comprobar(recorrido.paso_actual() == 0, "empieza sin giros")
	_comprobar(not recorrido.completado(), "no concede victoria al entrar")
	_comprobar(recorrido.suelo_seguro() != null, "plataforma física independiente")
	_comprobar(
		recorrido.suelo_seguro().get_parent() == recorrido,
		"el suelo seguro no gira con la nave",
	)
	_comprobar(
		recorrido.suelo_seguro().get_node_or_null("CollisionShape3D") != null,
		"el suelo seguro tiene collider",
	)
	_comprobar(not recorrido.sello(2).habilitado, "salida empieza cerrada")
	recorrido.sello(2).interactuar(camara)
	_comprobar(recorrido.paso_actual() == 0, "salida no admite atajos")
	recorrido.sello(0).interactuar(camara)
	_comprobar(recorrido.paso_actual() == 0, "impide activar sellos desde lejos")
	actor.position = Vector3(-3.0, 0.0, -1.8)
	recorrido.sello(0).interactuar(Node.new())
	_comprobar(recorrido.paso_actual() == 0, "rechaza actores ajenos")
	recorrido.sello(0).interactuar(camara)
	_comprobar(recorrido.paso_actual() == 1, "primer sello desbloquea segundo paso")
	_comprobar(
		recorrido.nave().orientacion_actual() == CatedralInvertida.MURO_DERECHO,
		"primer giro gira 90 grados",
	)
	_comprobar(not recorrido.sello(0).habilitado, "primer sello no se puede repetir")
	_comprobar(recorrido.sello(1).habilitado, "segundo sello se habilita")
	actor.position = Vector3(3.0, 0.0, -1.8)
	recorrido.sello(1).interactuar(camara)
	_comprobar(recorrido.paso_actual() == 2, "segundo sello abre salida")
	_comprobar(
		recorrido.nave().orientacion_actual() == CatedralInvertida.TECHO,
		"segundo giro invierte orientación",
	)
	_comprobar(recorrido.sello(2).habilitado, "habilita umbral tras dos giros")
	_comprobar(_eventos == 0, "los giros no completan el recorrido por sí solos")
	actor.position = Vector3(0.0, 0.0, -2.8)
	recorrido.sello(2).interactuar(camara)
	_comprobar(recorrido.completado(), "cruzar umbral completa recorrido")
	_comprobar(_eventos == 1, "emite una sola señal de final")
	recorrido.sello(2).interactuar(camara)
	_comprobar(_eventos == 1, "la salida no duplica recompensa")
	_comprobar(actor.rotation_degrees == Vector3.ZERO, "sin rotar jugador")
	_comprobar(camara.rotation_degrees == Vector3.ZERO, "sin rotar cámara")
	recorrido.queue_free()
	actor.queue_free()


func _probar_reduccion_movimiento() -> void:
	var contexto := _nuevo(true)
	var actor: CharacterBody3D = contexto["actor"]
	var camara: Camera3D = contexto["camara"]
	var recorrido: CatedralInvertidaRecorrido3D = contexto["recorrido"]
	actor.position = Vector3(-3.0, 0.0, -1.8)
	recorrido.sello(0).interactuar(camara)
	_comprobar(
		recorrido.nave().nodo_arquitectura().rotation_degrees == Vector3(0, 0, -90),
		"reducción de movimiento aplica un corte instantáneo",
	)
	actor.position = Vector3(3.0, 0.0, -1.8)
	recorrido.sello(1).interactuar(camara)
	_comprobar(
		recorrido.nave().nodo_arquitectura().rotation_degrees == Vector3(0, 0, 180),
		"segundo giro reducido mantiene destino exacto",
	)
	recorrido.queue_free()
	actor.queue_free()


func _contar_finales() -> void:
	_eventos += 1


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO catedral recorrido: " + nombre)
