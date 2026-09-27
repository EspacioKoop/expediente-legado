extends SceneTree

## Vertical ejecutable de #383: dos clientes fixture completan tres hoyos
## enviando únicamente dirección + potencia a una autoridad determinista.

const MinijuegoGolfAutoridad = preload("res://guion/red/minijuego_golf_autoridad.gd")
const MinijuegoSesionDatos = preload("res://guion/red/minijuego_sesion_datos.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")

const AHORA := 2_100_000_000
const SCENE_KEY := "oficina/golf_coop"
const ROOM_ID := "SALA-383"
const SESSION_ID := "golf-383-a"
const BUILD := "test-383"

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_contrato_acciones()
	_probar_vertical_dos_clientes()
	_probar_orden_version_y_timeout()
	_probar_abandono_sin_partida()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _configuraciones_faciles() -> Array:
	var salida: Array = []
	for _i in range(3):
		(
			salida
			. append(
				{
					"inicio": Vector2.ZERO,
					"objetivo": Vector2(0.0, -0.14625),
					"limite": Rect2(-1.0, -1.0, 2.0, 2.0),
					"radio_objetivo": 0.04,
					"obstaculos": [],
				}
			)
		)
	return salida


func _crear_evento(
	actor: String,
	sequence: int,
	turn: int,
	rules_version: int = MinijuegoGolfAutoridad.RULES_VERSION,
) -> Dictionary:
	return (
		MinijuegoSesionDatos
		. crear_accion(
			SCENE_KEY,
			BUILD,
			actor,
			ROOM_ID,
			SESSION_ID,
			MinijuegoGolfAutoridad.MINIGAME_ID,
			rules_version,
			sequence,
			turn,
			{"type": "shot", "direction": [0.0, -1.0], "power": 0.1},
			AHORA + sequence,
			"evt-%s-%d-%d" % [actor, rules_version, sequence],
		)
	)


func _probar_contrato_acciones() -> void:
	var evento := _crear_evento("anon-a", 0, 0)
	_comprobar("acción válida", evento["ok"], true)
	_comprobar("kind dedicado", evento["event"]["kind"], "minigame_action")
	_comprobar("no transporta resultado", evento["event"]["payload"].has("result"), false)

	var puntuacion := (
		MinijuegoSesionDatos
		. crear_accion(
			SCENE_KEY,
			BUILD,
			"anon-a",
			ROOM_ID,
			SESSION_ID,
			MinijuegoGolfAutoridad.MINIGAME_ID,
			1,
			0,
			0,
			{"type": "shot", "direction": [0.0, -1.0], "power": 0.1, "score": 900},
			AHORA,
		)
	)
	_comprobar("cliente no puede enviar score", puntuacion["ok"], false)
	_comprobar("rechazo identifica resultado", puntuacion["reason"], "forbidden_result_field")

	var sesion := (
		MinijuegoSesionDatos
		. nueva_sesion(
			SESSION_ID,
			MinijuegoGolfAutoridad.MINIGAME_ID,
			1,
			["anon-a", "anon-b"],
		)
	)
	_comprobar("contrato tiene jugadores", sesion["players"].size(), 2)
	_comprobar("contrato tiene fase", sesion["phase"], "playing")
	_comprobar("contrato tiene estado", sesion.has("state"), true)
	_comprobar("contrato tiene acciones permitidas", sesion.has("allowed_actions"), true)


func _probar_vertical_dos_clientes() -> void:
	var autoridad := (
		MinijuegoGolfAutoridad
		. new(
			ROOM_ID,
			SESSION_ID,
			["anon-a", "anon-b"],
			_configuraciones_faciles(),
		)
	)
	_comprobar("autoridad válida", autoridad.valida(), true)

	var cliente_a := TransporteFixture.new()
	var cliente_b := TransporteFixture.new()
	var relay_host := TransporteFixture.new()
	_comprobar("cliente A abre sala", cliente_a.abrir_sala(SCENE_KEY)["ok"], true)
	_comprobar("cliente B abre sala", cliente_b.abrir_sala(SCENE_KEY)["ok"], true)

	for indice in range(6):
		var snapshot := autoridad.snapshot()
		var actor := String(snapshot["state"]["current_player"])
		var evento := _crear_evento(actor, int(snapshot["sequence"]), int(snapshot["turn"]))
		var cliente = cliente_a if actor == "anon-a" else cliente_b
		var publicado := cliente.publicar_evento(evento["event"], AHORA + indice)
		_comprobar("cliente publica acción %d" % indice, publicado["ok"], true)

		relay_host.inyectar(evento["event"])
		var consulta := (
			relay_host
			. consultar_eventos(
				SCENE_KEY,
				MinijuegoSesionDatos.KIND,
				AHORA + indice,
			)
		)
		_comprobar("relay entrega acción %d" % indice, consulta["events"].is_empty(), false)
		var recibida: Dictionary = consulta["events"][-1]
		var aplicado := autoridad.aplicar_evento(recibida, AHORA + indice)
		_comprobar("host acepta acción %d" % indice, aplicado["ok"], true)
		_comprobar("tiro entra %d" % indice, aplicado["shot"]["holed"], true)

	var final := autoridad.snapshot()
	_comprobar("sesión termina", final["phase"], "finished")
	_comprobar("sin acciones tras final", final["allowed_actions"].size(), 0)
	_comprobar("tres golpes A", final["result"]["totales"]["anon-a"], 3)
	_comprobar("tres golpes B", final["result"]["totales"]["anon-b"], 3)
	_comprobar("empate calculado por autoridad", final["result"]["ganador"], "empate")
	_comprobar("secuencia final", final["sequence"], 6)


func _probar_orden_version_y_timeout() -> void:
	var autoridad := MinijuegoGolfAutoridad.new(
		ROOM_ID,
		SESSION_ID,
		["anon-a", "anon-b"],
		_configuraciones_faciles(),
	)
	var evento := _crear_evento("anon-a", 0, 0)
	var primero := autoridad.aplicar_evento(evento["event"], AHORA)
	_comprobar("primer paquete aceptado", primero["ok"], true)

	var duplicado := autoridad.aplicar_evento(evento["event"], AHORA)
	_comprobar("duplicado rechazado", duplicado["status"], "late_or_duplicate")
	var adelantado := _crear_evento("anon-b", 3, 1)
	var fuera_orden := autoridad.aplicar_evento(adelantado["event"], AHORA + 1)
	_comprobar("salto de secuencia rechazado", fuera_orden["status"], "out_of_order")

	var incompatible := _crear_evento("anon-b", 1, 1, 2)
	var version := autoridad.aplicar_evento(incompatible["event"], AHORA + 1)
	_comprobar("reglas incompatibles rechazadas", version["status"], "incompatible_rules")

	var transporte := TransporteFixture.new()
	transporte.simular_timeout(true)
	var valido := _crear_evento("anon-b", 1, 1)
	var secuencia_antes := int(autoridad.snapshot()["sequence"])
	var fallo := transporte.publicar_evento(valido["event"], AHORA + 1)
	_comprobar("timeout explícito", fallo["status"], "timeout")
	_comprobar("timeout no avanza autoridad", autoridad.snapshot()["sequence"], secuencia_antes)


func _probar_abandono_sin_partida() -> void:
	var partida := {
		"dinero": 31,
		"vidas": 2,
		"pistas_descubiertas": ["pista-previa"],
		"veredictos": {"caso-previo": "firma"},
	}
	var antes := JSON.stringify(partida)
	var autoridad := MinijuegoGolfAutoridad.new(
		ROOM_ID,
		SESSION_ID,
		["anon-a", "anon-b"],
		_configuraciones_faciles(),
	)
	var abandono := autoridad.abandonar()
	_comprobar("abandono termina sesión", abandono["snapshot"]["phase"], "finished")
	_comprobar("abandono marcado", abandono["snapshot"]["result"]["abandonada"], true)
	_comprobar("Partida queda intacta", JSON.stringify(partida), antes)


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
