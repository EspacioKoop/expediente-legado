extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	PreferenciasSiga.aplicar(PreferenciasSiga.nuevas())
	var escena: BolosPasillo3D = load("res://escenas/bolos_pasillo.tscn").instantiate()
	root.add_child(escena)
	await process_frame

	_comprobar(escena.estado.get("lanzadores", []).size() == 4, "jugador y tres compañeros")
	_comprobar(escena.total_bolos_en_pie() == 10, "la pista monta diez bolos")
	_comprobar(escena.lanzar(0.0, 1.0), "un tiro recto puede comenzar")
	var pasos_recto := escena.simular_hasta_reposo()
	_comprobar(pasos_recto > 0, "el tiro avanza con paso fijo")
	_comprobar(not escena.lanzamiento_activo(), "el tiro termina siempre")
	_comprobar(int(escena.estado.get("lanzamiento", 0)) == 1, "primer tiro consume un lanzamiento")
	_comprobar(int(escena.estado.get("puntuaciones", [0])[0]) > 0, "el tiro recto derriba")

	escena.reiniciar()
	_comprobar(escena.lanzar(1.0, 0.45), "se puede apuntar lateralmente")
	escena.simular_hasta_reposo()
	_comprobar(int(escena.estado.get("puntuaciones", [1])[0]) == 0, "un tiro lateral puede fallar")
	_comprobar(int(escena.estado.get("lanzamiento", 0)) == 1, "fallar no bloquea el turno")
	_comprobar(escena.lanzar(-1.0, 0.45), "segundo tiro puede comenzar")
	escena.simular_hasta_reposo()
	var resultado := escena.resultado_actual()
	_comprobar(bool(resultado.get("completa", false)), "dos tiros cierran jugador y compañeros")
	_comprobar(resultado.get("puntuaciones", []).size() == 4, "resultado incluye los cuatro turnos")

	escena.reiniciar()
	var abandonada := escena.abandonar()
	_comprobar(bool(abandonada.get("abandonada", false)), "abandonar devuelve resultado válido")
	_comprobar(not bool(abandonada.get("completa", true)), "abandonar no finge partida completa")

	escena.reiniciar()
	_comprobar(int(escena.estado.get("puntuaciones", [1])[0]) == 0, "repetir empieza desde cero")
	_comprobar(escena.total_bolos_en_pie() == 10, "repetir restaura los bolos")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	escena.queue_free()
	await process_frame
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO BolosPasillo3D: " + nombre)
