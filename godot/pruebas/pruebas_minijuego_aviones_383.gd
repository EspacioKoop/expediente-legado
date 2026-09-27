extends SceneTree

## Segundo minijuego físico sobre el contrato común de #383.

const MinijuegoAvionesAutoridad = preload("res://guion/red/minijuego_aviones_autoridad.gd")
const MinijuegoSesionDatos = preload("res://guion/red/minijuego_sesion_datos.gd")

const AHORA := 2_100_500_000
const SCENE_KEY := "oficina/aviones_coop"
const ROOM_ID := "SALA-383-AV"
const SESSION_ID := "aviones-383-a"
const BUILD := "test-383-aviones"

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_dos_jugadores()
	_probar_determinismo_y_serializacion()
	_probar_validaciones()
	_probar_abandono_sin_partida()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _accion(
	actor: String,
	sequence: int,
	turn: int,
	modelo: String = "estable",
	direccion: float = 0.0,
	altura: float = 15.0,
	potencia: float = 0.72,
	rules_version: int = 1,
) -> Dictionary:
	return (
		MinijuegoSesionDatos
		. crear_accion(
			SCENE_KEY,
			BUILD,
			actor,
			ROOM_ID,
			SESSION_ID,
			MinijuegoAvionesAutoridad.MINIGAME_ID,
			rules_version,
			sequence,
			turn,
			{
				"type": "launch",
				"model": modelo,
				"direction": direccion,
				"height": altura,
				"power": potencia,
			},
			AHORA + sequence,
			"av-%s-%d-%d" % [actor, rules_version, sequence],
		)
	)


func _nueva() -> MinijuegoAvionesAutoridad:
	return (
		MinijuegoAvionesAutoridad
		. new(
			ROOM_ID,
			SESSION_ID,
			["anon-a", "anon-b"],
			"distancia",
		)
	)


func _probar_dos_jugadores() -> void:
	var autoridad := _nueva()
	_comprobar("autoridad válida", autoridad.valida(), true)
	_comprobar("empieza A", autoridad.snapshot()["state"]["current_player"], "anon-a")
	_comprobar("acción permitida", autoridad.snapshot()["allowed_actions"], ["launch"])

	for indice in range(6):
		var snapshot := autoridad.snapshot()
		var actor := String(snapshot["state"]["current_player"])
		var turno := int(snapshot["turn"])
		var evento := _accion(actor, indice, turno)
		_comprobar("evento válido %d" % indice, evento["ok"], true)
		var aplicado := autoridad.aplicar_evento(evento["event"], AHORA + indice)
		_comprobar("lanzamiento aceptado %d" % indice, aplicado["ok"], true)
		_comprobar("vuelo tiene distancia %d" % indice, aplicado["flight"]["distance"] > 0.0, true)

		if indice == 2:
			_comprobar(
				"tras tres lanza B", aplicado["snapshot"]["state"]["current_player"], "anon-b"
			)
			_comprobar("turno avanza a uno", aplicado["snapshot"]["turn"], 1)

	var final := autoridad.snapshot()
	_comprobar("sesión termina", final["phase"], "finished")
	_comprobar("sin acciones tras final", final["allowed_actions"].size(), 0)
	_comprobar("secuencia final", final["sequence"], 6)
	_comprobar("A tiene tres vuelos", final["state"]["results"]["anon-a"].size(), 3)
	_comprobar("B tiene tres vuelos", final["state"]["results"]["anon-b"].size(), 3)
	_comprobar("resultado completo", final["result"]["completa"], true)
	_comprobar("resultado contiene ambos", final["result"]["puntuaciones"].size(), 2)


func _probar_determinismo_y_serializacion() -> void:
	var a := _nueva()
	var b := _nueva()
	var evento_a := _accion("anon-a", 0, 0, "rapido", 0.16, 19.0, 0.83)
	var evento_b := _accion("anon-a", 0, 0, "rapido", 0.16, 19.0, 0.83)
	var resultado_a := a.aplicar_evento(evento_a["event"], AHORA)
	var resultado_b := b.aplicar_evento(evento_b["event"], AHORA)
	_comprobar("mismo lanzamiento A", resultado_a["ok"], true)
	_comprobar("mismo lanzamiento B", resultado_b["ok"], true)
	_comprobar(
		"trayectoria determinista",
		resultado_a["flight"]["position"],
		resultado_b["flight"]["position"],
	)
	_comprobar(
		"puntuación determinista",
		resultado_a["flight"]["points"],
		resultado_b["flight"]["points"],
	)

	var json := JSON.stringify(resultado_a["snapshot"])
	var rehidratado = JSON.parse_string(json)
	_comprobar("snapshot es JSON válido", typeof(rehidratado), TYPE_DICTIONARY)
	_comprobar("snapshot no filtra Vector3", json.contains("Vector3"), false)


func _probar_validaciones() -> void:
	var autoridad := _nueva()
	var primero := _accion("anon-a", 0, 0)
	_comprobar(
		"primer evento se aplica", autoridad.aplicar_evento(primero["event"], AHORA)["ok"], true
	)

	var duplicado := autoridad.aplicar_evento(primero["event"], AHORA)
	_comprobar("duplicado rechazado", duplicado["status"], "late_or_duplicate")

	var salto := _accion("anon-a", 4, 0)
	_comprobar(
		"salto de secuencia rechazado",
		autoridad.aplicar_evento(salto["event"], AHORA + 1)["status"],
		"out_of_order",
	)

	var otro_actor := _accion("anon-b", 1, 0)
	_comprobar(
		"actor fuera de turno rechazado",
		autoridad.aplicar_evento(otro_actor["event"], AHORA + 1)["status"],
		"not_actor_turn",
	)

	var incompatible := _accion("anon-a", 1, 0, "estable", 0.0, 15.0, 0.7, 2)
	_comprobar(
		"reglas incompatibles rechazadas",
		autoridad.aplicar_evento(incompatible["event"], AHORA + 1)["status"],
		"incompatible_rules",
	)

	var modelo := _accion("anon-a", 1, 0, "ovni")
	_comprobar(
		"modelo inválido rechazado",
		autoridad.aplicar_evento(modelo["event"], AHORA + 1)["reason"],
		"invalid_model",
	)

	var rango := _accion("anon-a", 1, 0, "estable", 1.5)
	_comprobar(
		"dirección fuera de rango rechazada",
		autoridad.aplicar_evento(rango["event"], AHORA + 1)["reason"],
		"direction_out_of_range",
	)

	var score := (
		MinijuegoSesionDatos
		. crear_accion(
			SCENE_KEY,
			BUILD,
			"anon-a",
			ROOM_ID,
			SESSION_ID,
			MinijuegoAvionesAutoridad.MINIGAME_ID,
			1,
			1,
			0,
			{
				"type": "launch",
				"model": "estable",
				"direction": 0.0,
				"height": 15.0,
				"power": 0.7,
				"score": 999,
			},
			AHORA + 1,
		)
	)
	_comprobar("cliente no envía score", score["ok"], false)
	_comprobar("score cae en contrato común", score["reason"], "forbidden_result_field")


func _probar_abandono_sin_partida() -> void:
	var partida := {
		"dinero": 44,
		"vidas": 2,
		"pistas_descubiertas": ["previa"],
		"veredictos": {"caso": "firma"},
	}
	var antes := JSON.stringify(partida)
	var autoridad := _nueva()
	var abandono := autoridad.abandonar()
	_comprobar("abandono termina sesión", abandono["snapshot"]["phase"], "finished")
	_comprobar("abandono quita acciones", abandono["snapshot"]["allowed_actions"].size(), 0)
	_comprobar("abandono limpia jugador actual", abandono["snapshot"]["state"]["current_player"], "")
	_comprobar("abandono queda marcado", abandono["snapshot"]["result"]["abandonada"], true)
	_comprobar("abandono no es completa", abandono["snapshot"]["result"]["completa"], false)
	var posterior := _accion("anon-a", 0, 0)
	_comprobar(
		"abandono rechaza acciones posteriores",
		autoridad.aplicar_evento(posterior["event"], AHORA)["status"],
		"session_finished",
	)
	_comprobar("Partida sigue intacta", JSON.stringify(partida), antes)


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
