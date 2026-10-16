## Prueba de la portada local del CD-ROM ficticio de 1998 (#2589).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var programa := CronicasPc98.new()
	get_root().add_child(programa)
	await process_frame

	_comprobar(programa.has_node("Portada1998"), "menu original cargado")
	_comprobar(programa.has_node("Portada1998/FondoMonocromo"), "fondo CRT legible")
	_comprobar(not programa.juego_en_curso(), "portada en reposo")
	_comprobar(programa.prologos_locales() == 0, "sin visitas inventadas")
	var cerrar := [0]
	var completar := [0]
	programa.cerrar_solicitado.connect(func(): cerrar[0] += 1)
	programa.prologo_completado.connect(func(): completar[0] += 1)

	_comprobar(programa.comenzar(), "se inicia el juego")
	await process_frame
	_comprobar(programa.juego_en_curso(), "instancia sala 3D existente")
	_comprobar(
		programa.get_node_or_null("PartidaCronicas") is CronicasBastion3D, "no duplica motor"
	)
	_comprobar(not programa.comenzar(), "una sola instancia de partida")
	var sala := programa.get_node("PartidaCronicas") as CronicasBastion3D
	sala.registrar_lectura()
	sala.registrar_lectura()
	sala.registrar_resultado_duelo(true)
	_comprobar(sala.solicitar_salida(), "completado desde bastion real")
	await process_frame
	_comprobar(not programa.juego_en_curso(), "retorno a portada")
	_comprobar(programa.prologos_locales() == 1, "visita solo local")
	_comprobar(completar[0] == 1, "una sola notificacion")
	_comprobar(programa.get_node_or_null("PartidaCronicas") == null, "sala liberada")

	var boton := programa.find_child("CerrarPrograma", true, false) as Button
	_comprobar(boton != null, "cierre semanticamente visible")
	boton.pressed.emit()
	_comprobar(cerrar[0] == 1, "cerrar programa no cierra Expediente Legado")
	get_root().remove_child(programa)
	programa.free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("Cronicas PC: " + nombre)
