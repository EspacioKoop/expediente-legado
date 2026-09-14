extends SceneTree

const Puzzle := preload("res://guion/puzzle_onirico.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_fuentes()
	_probar_determinismo()
	_probar_ciclo_de_vida()
	_probar_serializacion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_fuentes() -> void:
	var rechazado = Puzzle.crear("ecos", ["F-1", "F-2"], ["F-1"], 17)
	_comprobar(rechazado == null, "rechaza una fuente que no se leyó hoy")

	var vacio = Puzzle.crear("ecos", [], ["F-1"], 17)
	_comprobar(vacio == null, "no crea puzzles sin material del archivo")

	var puzzle = Puzzle.crear("ecos", ["F-2", "F-1", "F-2"], ["F-1", "F-2"], 17)
	_comprobar(puzzle != null, "crea el puzzle con fuentes permitidas")
	_comprobar(puzzle.source_ids == ["F-1", "F-2"], "ordena y deduplica las fuentes")


func _probar_determinismo() -> void:
	var a = Puzzle.crear("ecos", ["F-2", "F-1"], ["F-1", "F-2"], 4431)
	var b = Puzzle.crear("ecos", ["F-1", "F-2"], ["F-1", "F-2"], 4431)
	var otro = Puzzle.crear("cronologia", ["F-1", "F-2"], ["F-1", "F-2"], 4431)
	_comprobar(a.seed == b.seed, "misma raíz y fuentes producen la misma semilla")
	_comprobar(a.seed != otro.seed, "el id separa las semillas de puzzles distintos")
	_comprobar(a.seed >= 0 and a.seed <= 0xFFFFFFFF, "la semilla cabe exacta en JSON")


func _probar_ciclo_de_vida() -> void:
	var puzzle = Puzzle.crear("ecos", ["F-1"], ["F-1"], 91)
	var resultados: Array = []
	puzzle.resultado.connect(func(datos): resultados.append(datos))

	_comprobar(puzzle.completar(), "completar cierra un puzzle pendiente")
	_comprobar(puzzle.state == Puzzle.ESTADO_COMPLETADO, "conserva el estado completado")
	_comprobar(resultados.size() == 1, "emite exactamente un resultado al cerrar")
	_comprobar(not puzzle.abandonar(), "un puzzle terminal no puede cerrarse otra vez")
	_comprobar(resultados.size() == 1, "un segundo cierre no duplica el resultado")

	var abandonado = Puzzle.crear("ecos", ["F-1"], ["F-1"], 92)
	_comprobar(abandonado.abandonar(), "abandonar es un resultado terminal válido")
	_comprobar(abandonado.state == Puzzle.ESTADO_ABANDONADO, "distingue abandono de fallo")


func _probar_serializacion() -> void:
	var puzzle = Puzzle.crear("ecos", ["F-2", "F-1"], ["F-1", "F-2"], 123456)
	puzzle.fallar()
	var texto := JSON.stringify(puzzle.serializar())
	var desde_json: Dictionary = JSON.parse_string(texto)
	var restaurado = Puzzle.restaurar(desde_json, ["F-1", "F-2"])
	_comprobar(restaurado != null, "restaura un puzzle válido tras pasar por JSON")
	_comprobar(restaurado.seed == puzzle.seed, "recargar no altera la semilla")
	_comprobar(restaurado.state == Puzzle.ESTADO_FALLADO, "recargar conserva el estado")
	_comprobar(not restaurado.completar(), "recargar un terminal no reemite resultado")

	var filtrado = Puzzle.restaurar(desde_json, ["F-1"])
	_comprobar(filtrado == null, "restaurar vuelve a validar las fuentes de hoy")

	var contradictorio := desde_json.duplicate(true)
	contradictorio["resultado_emitido"] = false
	_comprobar(
		Puzzle.restaurar(contradictorio, ["F-1", "F-2"]) == null,
		"rechaza un terminal que dice no haber emitido resultado"
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO puzzle onírico: " + nombre)
