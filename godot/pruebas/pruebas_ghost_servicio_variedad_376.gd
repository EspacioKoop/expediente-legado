extends SceneTree

## Regresión de variedad/frescura para la selección de ghosts (#376).

const GhostDatos = preload("res://guion/red/ghost_datos.gd")
const GhostServicio = preload("res://guion/red/ghost_servicio.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")

const AHORA := 2_100_500_000
const SCENE_KEY := "trayecto"
const REVISION := "trayecto-variedad-v1"

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var transporte := TransporteFixture.new()
	for actor in ["gamma", "alpha", "epsilon", "beta", "delta"]:
		var evento := _evento(actor, _antiguedad(actor))
		_comprobar("fixture %s válido" % actor, evento["ok"], true)
		transporte.inyectar(evento["event"])

	var servicio := GhostServicio.new(transporte)
	servicio.configurar_actor_local("yo")

	var primera := servicio.consultar(SCENE_KEY, REVISION, AHORA)
	_comprobar("primera consulta válida", primera["ok"], true)
	_comprobar("primera respeta máximo visible", primera["ghosts"].size(), 3)
	_comprobar(
		"primera empieza por el ghost más fresco",
		_actores(primera["ghosts"]),
		["epsilon", "delta", "gamma"],
	)

	var segunda := servicio.consultar(SCENE_KEY, REVISION, AHORA)
	_comprobar("segunda consulta válida", segunda["ok"], true)
	_comprobar(
		"segunda prioriza actores aún no mostrados",
		_actores(segunda["ghosts"]),
		["beta", "alpha", "epsilon"],
	)

	var tercera := servicio.consultar(SCENE_KEY, REVISION, AHORA)
	_comprobar(
		"tercera evita al actor ya mostrado dos veces",
		_actores(tercera["ghosts"]),
		["delta", "gamma", "beta"],
	)

	servicio.reiniciar_seleccion()
	var reiniciada := servicio.consultar(SCENE_KEY, REVISION, AHORA)
	_comprobar(
		"reiniciar devuelve política limpia y determinista",
		_actores(reiniciada["ghosts"]),
		["epsilon", "delta", "gamma"],
	)

	var transporte_local := TransporteFixture.new()
	transporte_local.inyectar(_evento("yo", 5)["event"])
	transporte_local.inyectar(_evento("otro", 15)["event"])
	var servicio_local := GhostServicio.new(transporte_local)
	servicio_local.configurar_actor_local("yo")
	var sin_local := servicio_local.consultar(SCENE_KEY, REVISION, AHORA)
	_comprobar("actor local sigue excluido", _actores(sin_local["ghosts"]), ["otro"])

	print("\nGhost selección #376: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _evento(actor: String, antiguedad: int) -> Dictionary:
	var creado := AHORA - antiguedad
	return (
		GhostDatos
		. crear_evento(
			SCENE_KEY,
			REVISION,
			"test-376-variedad",
			actor,
			[
				{"t": 0.1, "position": [0.0, 0.0, 0.0], "yaw": 0.0, "gesture": ""},
				{"t": 0.3, "position": [1.0, 0.0, 0.0], "yaw": 0.0, "gesture": ""},
			],
			6.0,
			creado,
			"ghost-variedad-%s" % actor,
		)
	)


func _antiguedad(actor: String) -> int:
	return (
		{
			"alpha": 50,
			"beta": 40,
			"gamma": 30,
			"delta": 20,
			"epsilon": 10,
		}
		. get(actor, 60)
	)


func _actores(eventos: Array) -> Array:
	var resultado := []
	for evento in eventos:
		resultado.append(String(evento.get("actor_public_id", "")))
	return resultado


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
