extends SceneTree

## Tercer minijuego físico sobre el contrato común de #383: bolos (#159).

const BolosPasillo3D = preload("res://guion/bolos_pasillo_3d.gd")
const MinijuegoBolosAutoridad = preload("res://guion/red/minijuego_bolos_autoridad.gd")
const MinijuegoSesionDatos = preload("res://guion/red/minijuego_sesion_datos.gd")

const AHORA := 2_100_600_000
const SCENE_KEY := "oficina/bolos_coop"
const ROOM_ID := "SALA-383-BO"
const SESSION_ID := "bolos-383-a"
const BUILD := "test-383-bolos"

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_fisica_compartida()
	_probar_dos_jugadores()
	_probar_determinismo()
	_probar_validaciones()
	_probar_abandono_sin_partida()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _accion(
	actor: String,
	sequence: int,
	turn: int,
	apuntado: float = 0.0,
	potencia: float = 0.75,
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
			MinijuegoBolosAutoridad.MINIGAME_ID,
			rules_version,
			sequence,
			turn,
			{
				"type": "roll",
				"aim": apuntado,
				"power": potencia,
			},
			AHORA + sequence,
			"bo-%s-%d-%d" % [actor, rules_version, sequence],
		)
	)


func _nueva() -> MinijuegoBolosAutoridad:
	return (
		MinijuegoBolosAutoridad
		. new(
			ROOM_ID,
			SESSION_ID,
			["anon-a", "anon-b"],
			BolosPasillo3D.VARIANTE_ESTRECHO,
		)
	)


func _probar_fisica_compartida() -> void:
	var simulador := BolosPasillo3D.new()
	simulador.configurar_variante(BolosPasillo3D.VARIANTE_ESTRECHO)
	var directo := simulador.simular_lanzamiento_autoritativo(0.0, 0.82)
	simulador.free()
	_comprobar("simulación headless válida", directo["ok"], true)
	_comprobar("simulación conserva diez pines", directo["pins_standing"].size(), 10)
	_comprobar("paso fijo realmente avanza", directo["steps"] > 0, true)

	var autoridad := _nueva()
	var evento := _accion("anon-a", 0, 0, 0.0, 0.82)
	var aplicado := autoridad.aplicar_evento(evento["event"], AHORA)
	_comprobar("autoridad acepta física compartida", aplicado["ok"], true)
	_comprobar("mismos bolos derribados", aplicado["roll"]["knocked"], directo["knocked"])
	_comprobar(
		"mismo rack resultante",
		aplicado["roll"]["pins_standing"],
		directo["pins_standing"],
	)


func _probar_dos_jugadores() -> void:
	var autoridad := _nueva()
	_comprobar("autoridad válida", autoridad.valida(), true)
	_comprobar("empieza A", autoridad.snapshot()["state"]["current_player"], "anon-a")
	_comprobar("acción permitida", autoridad.snapshot()["allowed_actions"], ["roll"])

	for indice in range(4):
		var snapshot := autoridad.snapshot()
		var actor := String(snapshot["state"]["current_player"])
		var turno := int(snapshot["turn"])
		var evento := _accion(actor, indice, turno, -0.12 + indice * 0.08, 0.76)
		_comprobar("evento válido %d" % indice, evento["ok"], true)
		var aplicado := autoridad.aplicar_evento(evento["event"], AHORA + indice)
		_comprobar("lanzamiento aceptado %d" % indice, aplicado["ok"], true)
		_comprobar("derribo acotado %d" % indice, aplicado["roll"]["knocked"] >= 0, true)
		_comprobar("rack del tiro %d" % indice, aplicado["roll"]["pins_standing"].size(), 10)

		if indice == 1:
			_comprobar(
				"tras dos lanza B", aplicado["snapshot"]["state"]["current_player"], "anon-b"
			)
			_comprobar("turno avanza a uno", aplicado["snapshot"]["turn"], 1)
			_comprobar(
				"rack se restaura para B",
				aplicado["snapshot"]["state"]["pins_standing"].count(true),
				10,
			)

	var final := autoridad.snapshot()
	_comprobar("sesión termina", final["phase"], "finished")
	_comprobar("sin acciones tras final", final["allowed_actions"].size(), 0)
	_comprobar("secuencia final", final["sequence"], 4)
	_comprobar("resultado completo", final["result"]["completa"], true)
	_comprobar("resultado contiene ambos", final["result"]["puntuaciones"].size(), 2)


func _probar_determinismo() -> void:
	var a := _nueva()
	var b := _nueva()
	var evento_a := _accion("anon-a", 0, 0, 0.21, 0.91)
	var evento_b := _accion("anon-a", 0, 0, 0.21, 0.91)
	var resultado_a := a.aplicar_evento(evento_a["event"], AHORA)
	var resultado_b := b.aplicar_evento(evento_b["event"], AHORA)
	_comprobar("mismo lanzamiento A", resultado_a["ok"], true)
	_comprobar("mismo lanzamiento B", resultado_b["ok"], true)
	_comprobar(
		"derribos deterministas",
		resultado_a["roll"]["knocked"],
		resultado_b["roll"]["knocked"],
	)
	_comprobar(
		"rack determinista",
		resultado_a["roll"]["pins_standing"],
		resultado_b["roll"]["pins_standing"],
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

	var incompatible := _accion("anon-a", 1, 0, 0.0, 0.7, 2)
	_comprobar(
		"reglas incompatibles rechazadas",
		autoridad.aplicar_evento(incompatible["event"], AHORA + 1)["status"],
		"incompatible_rules",
	)

	var apuntado := _accion("anon-a", 1, 0, 1.5)
	_comprobar(
		"apuntado fuera de rango rechazado",
		autoridad.aplicar_evento(apuntado["event"], AHORA + 1)["reason"],
		"aim_out_of_range",
	)

	var potencia := _accion("anon-a", 1, 0, 0.0, 0.0)
	_comprobar(
		"potencia cero rechazada",
		autoridad.aplicar_evento(potencia["event"], AHORA + 1)["reason"],
		"power_out_of_range",
	)

	var score := (
		MinijuegoSesionDatos
		. crear_accion(
			SCENE_KEY,
			BUILD,
			"anon-a",
			ROOM_ID,
			SESSION_ID,
			MinijuegoBolosAutoridad.MINIGAME_ID,
			1,
			1,
			0,
			{
				"type": "roll",
				"aim": 0.0,
				"power": 0.7,
				"score": 10,
			},
			AHORA + 1,
		)
	)
	_comprobar("cliente no envía score", score["ok"], false)
	_comprobar("score cae en contrato común", score["reason"], "forbidden_result_field")


func _probar_abandono_sin_partida() -> void:
	var partida := {
		"dinero": 51,
		"vidas": 2,
		"pistas_descubiertas": ["previa"],
		"veredictos": {"caso": "firma"},
	}
	var antes := JSON.stringify(partida)
	var autoridad := _nueva()
	var abandono := autoridad.abandonar()
	_comprobar("abandono termina sesión", abandono["snapshot"]["phase"], "finished")
	_comprobar("abandono quita acciones", abandono["snapshot"]["allowed_actions"].size(), 0)
	_comprobar(
		"abandono limpia jugador actual", abandono["snapshot"]["state"]["current_player"], ""
	)
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
