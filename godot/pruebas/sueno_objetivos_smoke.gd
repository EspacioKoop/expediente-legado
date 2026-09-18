## Smoke ejecutable del contrato de objetivos oníricos (#299).
##
## Uso:
##     godot4 --headless --path godot --script pruebas/sueno_objetivos_smoke.gd
extends SceneTree

const Regla = preload("res://guion/sueno_objetivos.gd")

var fallos := 0


func _init() -> void:
	_comprobar_vertical_0_1_2()
	_comprobar_objetivo_no_puntuable()
	_comprobar_sustitucion_puzzle()
	_comprobar_fallo_opcional()
	if fallos == 0:
		print("Sueño objetivos smoke: OK")
		quit(0)
		return
	push_error("Sueño objetivos smoke: %d fallos" % fallos)
	quit(1)


func _comprobar_vertical_0_1_2() -> void:
	var estado := Regla.nuevo(["anomalia", "figura", "interaccion"])
	_comprobar(Regla.progreso(estado) == Vector2i(0, 2), "empieza en 0/2")
	_comprobar(Regla.completar(estado, "anomalia"), "primer objetivo progresa")
	_comprobar(Regla.progreso(estado) == Vector2i(1, 2), "pasa a 1/2")
	_comprobar(not Regla.resuelto(estado), "1/2 no resuelve")
	_comprobar(not Regla.completar(estado, "anomalia"), "duplicado no cuenta")
	_comprobar(Regla.progreso(estado) == Vector2i(1, 2), "duplicado conserva 1/2")
	_comprobar(Regla.completar(estado, "figura"), "segundo objetivo progresa")
	_comprobar(Regla.progreso(estado) == Vector2i(2, 2), "pasa a 2/2")
	_comprobar(Regla.resuelto(estado), "2/2 resuelve")
	_comprobar(not Regla.completar(estado, "interaccion"), "resuelto no vuelve a mutar")


func _comprobar_objetivo_no_puntuable() -> void:
	var estado := (
		Regla
		. nuevo(
			[
				{
					"id": "eco",
					"tipo": "anomalia",
					"condicion": "observar",
					"feedback": "ambiente",
					"cuenta": false,
				},
				{"id": "a", "tipo": "interaccion", "cuenta": true},
				{"id": "b", "tipo": "figura", "cuenta": true},
			],
			2,
		)
	)
	_comprobar(Regla.completar(estado, "eco"), "no puntuable puede completarse")
	_comprobar(Regla.progreso(estado) == Vector2i(0, 2), "no puntuable no suma")
	_comprobar(estado["completados"].has("eco"), "no puntuable queda completado")
	_comprobar(Regla.completar(estado, "a"), "primer puntuable progresa")
	_comprobar(Regla.completar(estado, "b"), "segundo puntuable progresa")
	_comprobar(Regla.resuelto(estado), "dos puntuables resuelven")


func _comprobar_sustitucion_puzzle() -> void:
	var estado := Regla.nuevo(["ruta-a", "ruta-b", "ruta-c"], 2)
	var puzzle := {
		"id": "pista:ecos:P-1",
		"tipo": "pista_onirica",
		"condicion": "resolver",
		"feedback": "pista",
		"cuenta": true,
	}
	_comprobar(
		Regla.sustituir_puntuable(estado, puzzle, "ruta-c"),
		"el puzzle sustituye una plaza puntuable pendiente",
	)
	_comprobar(
		Regla.sustituir_puntuable(estado, puzzle, "ruta-c"),
		"registrar el mismo puzzle otra vez es idempotente",
	)
	_comprobar(estado["ids"].count("pista:ecos:P-1") == 1, "el puzzle no se duplica al recargar")
	_comprobar(Regla.completar(estado, "ruta-c"), "la ruta sustituida puede quedar registrada")
	_comprobar(Regla.progreso(estado) == Vector2i(0, 2), "la ruta sustituida ya no puntúa")
	_comprobar(Regla.completar(estado, "pista:ecos:P-1"), "resolver el puzzle suma su plaza")
	_comprobar(Regla.progreso(estado) == Vector2i(1, 2), "el puzzle resuelto deja progreso 1/2")
	_comprobar(Regla.completar(estado, "ruta-a"), "una ruta espacial completa el umbral")
	_comprobar(Regla.resuelto(estado), "puzzle más una ruta resuelven la escena")

	var fallido := Regla.nuevo(["ruta-a", "ruta-b", "ruta-c"], 2)
	_comprobar(
		Regla.sustituir_puntuable(fallido, puzzle, "ruta-c"),
		"el puzzle fallable ocupa la misma plaza",
	)
	_comprobar(Regla.fallar(fallido, "pista:ecos:P-1"), "el puzzle puede fallar sin puntuar")
	_comprobar(Regla.completar(fallido, "ruta-a"), "primera ruta alternativa progresa")
	_comprobar(Regla.completar(fallido, "ruta-b"), "segunda ruta alternativa progresa")
	_comprobar(Regla.resuelto(fallido), "fallar el puzzle no bloquea las dos rutas restantes")

	var tarde := Regla.nuevo(["ruta-a", "ruta-b", "ruta-c"], 2)
	_comprobar(Regla.completar(tarde, "ruta-c"), "la ruta puede completarse antes del puzzle")
	_comprobar(
		not Regla.sustituir_puntuable(tarde, puzzle, "ruta-c"),
		"no se roba progreso ya conseguido al integrar tarde",
	)


func _comprobar_fallo_opcional() -> void:
	var estado := Regla.nuevo(["puzzle", "ruta-a", "ruta-b"], 2)
	_comprobar(Regla.fallar(estado, "puzzle"), "puzzle opcional puede fallar")
	_comprobar(not Regla.fallar(estado, "puzzle"), "fallo duplicado es idempotente")
	_comprobar(not Regla.completar(estado, "puzzle"), "fallido no revive como completado")
	_comprobar(Regla.progreso(estado) == Vector2i(0, 2), "fallo no suma progreso")
	_comprobar(Regla.completar(estado, "ruta-a"), "ruta alternativa uno progresa")
	_comprobar(Regla.completar(estado, "ruta-b"), "ruta alternativa dos progresa")
	_comprobar(Regla.resuelto(estado), "fallo opcional no bloquea si quedan dos rutas")


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		return
	fallos += 1
	printerr("FALLO #299: %s" % mensaje)
