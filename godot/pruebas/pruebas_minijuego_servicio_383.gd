extends SceneTree

## Regresión de la fachada común de sala privada para #383.

const MinijuegoServicio = preload("res://guion/red/minijuego_servicio.gd")
const MinijuegoSesionDatos = preload("res://guion/red/minijuego_sesion_datos.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")

const AHORA := 2_100_300_000
const SCENE_KEY := "oficina/golf_coop"
const ROOM_ID := "SALA-383-B"
const SESSION_ID := "golf-383-b"
const MINIGAME_ID := "golf_pasillo"

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_apertura_y_publicacion()
	_probar_filtrado_y_deduplicacion()
	_probar_version_y_recuperacion()
	_probar_cierre_sin_partida()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _abrir(servicio: MinijuegoServicio, actor: String) -> Dictionary:
	return servicio.abrir_sala(
		SCENE_KEY,
		ROOM_ID,
		SESSION_ID,
		MINIGAME_ID,
		1,
		actor,
	)


func _evento(
	actor: String,
	room_id: String = ROOM_ID,
	session_id: String = SESSION_ID,
	rules_version: int = 1,
	sequence: int = 0,
) -> Dictionary:
	return MinijuegoSesionDatos.crear_accion(
		SCENE_KEY,
		"test-383-service",
		actor,
		room_id,
		session_id,
		MINIGAME_ID,
		rules_version,
		sequence,
		sequence,
		{"type": "shot", "direction": [0.0, -1.0], "power": 0.3},
		AHORA + sequence,
		"service-%s-%d-%d" % [actor, rules_version, sequence],
	)


func _probar_apertura_y_publicacion() -> void:
	var transporte := TransporteFixture.new()
	var servicio := MinijuegoServicio.new(transporte)
	var apertura := _abrir(servicio, "anon-a")
	_comprobar("abre sala privada", apertura["ok"], true)
	_comprobar("servicio activo", servicio.activa(), true)
	_comprobar("contexto conserva sala", servicio.contexto()["room_id"], ROOM_ID)
	_comprobar("contexto conserva sesión", servicio.contexto()["session_id"], SESSION_ID)

	var publicacion := servicio.publicar_accion(
		"test-383-service",
		0,
		0,
		{"type": "shot", "direction": [0.0, -1.0], "power": 0.3},
		AHORA,
		"service-a-0",
	)
	_comprobar("publica acción", publicacion["ok"], true)
	_comprobar("fixture recibe una", transporte.publicados().size(), 1)
	_comprobar(
		"publicación lleva sesión",
		publicacion["event"]["payload"]["session_id"],
		SESSION_ID,
	)

	var prohibida := servicio.publicar_accion(
		"test-383-service",
		1,
		1,
		{"type": "shot", "direction": [0.0, -1.0], "power": 0.3, "score": 900},
		AHORA + 1,
	)
	_comprobar("score sigue prohibido", prohibida["ok"], false)
	_comprobar("score falla antes de transporte", transporte.publicados().size(), 1)


func _probar_filtrado_y_deduplicacion() -> void:
	var transporte := TransporteFixture.new()
	var servicio := MinijuegoServicio.new(transporte)
	_abrir(servicio, "anon-a")

	var bueno_1 := _evento("anon-b", ROOM_ID, SESSION_ID, 1, 1)
	var bueno_0 := _evento("anon-b", ROOM_ID, SESSION_ID, 1, 0)
	var otra_sala := _evento("anon-b", "OTRA-SALA", SESSION_ID, 1, 2)
	var otra_sesion := _evento("anon-b", ROOM_ID, "otra-sesion", 1, 3)
	var otra_version := _evento("anon-b", ROOM_ID, SESSION_ID, 2, 4)
	for creado in [bueno_1, bueno_0, otra_sala, otra_sesion, otra_version]:
		_comprobar("fixture creado válido", creado["ok"], true)
		transporte.inyectar(creado["event"])
	transporte.inyectar(bueno_0["event"])

	var primera := servicio.consultar_acciones(AHORA + 5)
	_comprobar("consulta válida", primera["ok"], true)
	_comprobar("solo misma sesión/version", primera["actions"].size(), 2)
	_comprobar("descarta contextos ajenos", primera["discarded"], 3)
	_comprobar("ordena secuencia 0", primera["actions"][0]["payload"]["sequence"], 0)
	_comprobar("ordena secuencia 1", primera["actions"][1]["payload"]["sequence"], 1)

	var segunda := servicio.consultar_acciones(AHORA + 5)
	_comprobar("dedup persiste entre consultas", segunda["actions"].size(), 0)


func _probar_version_y_recuperacion() -> void:
	var transporte := TransporteFixture.new()
	var servicio := MinijuegoServicio.new(transporte)
	_abrir(servicio, "anon-a")

	_comprobar("misma versión compatible", servicio.comprobar_version(1)["ok"], true)
	var incompatible := servicio.comprobar_version(2)
	_comprobar("otra versión rechazada", incompatible["status"], "incompatible_rules")
	_comprobar("expone versión local", incompatible["local"], 1)
	_comprobar("expone versión remota", incompatible["remote"], 2)

	transporte.simular_timeout(true)
	var fallo := servicio.publicar_accion(
		"test-383-service",
		0,
		0,
		{"type": "shot", "direction": [0.0, -1.0], "power": 0.3},
		AHORA,
	)
	_comprobar("timeout visible", fallo["status"], "timeout")
	_comprobar("timeout no cierra servicio", servicio.activa(), true)
	_comprobar("health refleja caída", servicio.estado_transporte()["online"], false)

	transporte.simular_timeout(false)
	var recuperado := servicio.publicar_accion(
		"test-383-service",
		0,
		0,
		{"type": "shot", "direction": [0.0, -1.0], "power": 0.3},
		AHORA,
	)
	_comprobar("recupera sin reabrir sala", recuperado["ok"], true)
	_comprobar("health vuelve online", servicio.estado_transporte()["online"], true)


func _probar_cierre_sin_partida() -> void:
	var partida := {
		"dinero": 27,
		"vidas": 2,
		"pistas_descubiertas": ["pista-previa"],
		"veredictos": {"caso-previo": "firma"},
	}
	var antes := JSON.stringify(partida)
	var transporte := TransporteFixture.new()
	var servicio := MinijuegoServicio.new(transporte)
	_abrir(servicio, "anon-a")
	_comprobar("cierre transporte ok", servicio.cerrar_sala()["ok"], true)
	_comprobar("servicio inactivo", servicio.activa(), false)
	_comprobar("contexto limpio", servicio.contexto()["room_id"], "")
	_comprobar("Partida intacta", JSON.stringify(partida), antes)


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
