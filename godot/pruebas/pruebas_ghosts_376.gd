extends SceneTree

## Vertical local ejecutable de #376.
## Uso: godot4 --headless --path godot --script res://pruebas/pruebas_ghosts_376.gd

const GhostDatos = preload("res://guion/red/ghost_datos.gd")
const GhostGrabador = preload("res://guion/red/ghost_grabador.gd")
const GhostServicio = preload("res://guion/red/ghost_servicio.gd")
const GhostRemoto3D = preload("res://guion/red/ghost_remoto_3d.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")

const AHORA := 2_100_000_000
const RUTA_FIXTURE := "res://datos/multiplayer_ghost_calle_fixture.json"

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_fixture_y_reproductor()
	_probar_revision_y_apagado()
	_probar_grabador_local()
	_probar_sueno_seguro()
	print("\nGhosts #376: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _fixture() -> Dictionary:
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_FIXTURE))
	return datos if datos is Dictionary else {}


func _probar_fixture_y_reproductor() -> void:
	var evento := _fixture()
	var validacion := GhostDatos.validar_evento(evento, AHORA)
	_comprobar("fixture JSON válido", validacion["ok"], true)
	if not validacion["ok"]:
		return
	_comprobar("fixture es ghost", validacion["event"]["kind"], "ghost")
	_comprobar("fixture queda bajo límite de frames", validacion["event"]["payload"]["frames"].size() <= GhostDatos.MAX_FRAMES, true)

	var ghost := GhostRemoto3D.new()
	_comprobar("reproductor acepta revisión compatible", ghost.cargar_evento(evento, "calle-r1", AHORA), true)
	_comprobar("ghost no expone capa de colisión", ghost.has_method("get_collision_layer"), false)
	var x_inicial := ghost.position.x
	ghost.avanzar(0.75)
	_comprobar("interpolación avanza", ghost.position.x > x_inicial, true)
	_comprobar("interpolación no salta al final", ghost.position.x < 2.0, true)
	ghost.avanzar(10.0)
	_comprobar("reproducción termina", ghost.finalizado(), true)
	ghost.free()


func _probar_revision_y_apagado() -> void:
	var evento := _fixture()
	var ghost := GhostRemoto3D.new()
	_comprobar("revisión incompatible se ignora", ghost.cargar_evento(evento, "calle-r2", AHORA), false)
	ghost.free()

	var transporte := TransporteFixture.new([evento])
	var servicio := GhostServicio.new(transporte, false)
	var apagado := servicio.consultar("calle", "calle-r1", AHORA)
	_comprobar("apagado total devuelve cero ghosts", apagado["ghosts"].size(), 0)
	_comprobar("apagado total es estado estable", apagado["status"], "disabled")
	servicio.habilitar(true)
	var activos := servicio.consultar("calle", "calle-r1", AHORA)
	_comprobar("servicio filtra y entrega compatible", activos["ghosts"].size(), 1)
	var incompatibles := servicio.consultar("calle", "calle-r2", AHORA)
	_comprobar("servicio descarta revisión incompatible", incompatibles["ghosts"].size(), 0)


func _probar_grabador_local() -> void:
	var grabador := GhostGrabador.new(
		"calle", "calle-r1", "test-376", "anon-local", 6.0
	)
	_comprobar("primera muestra se graba", grabador.registrar(10.0, Vector3.ZERO, 0.0), true)
	_comprobar("muestra demasiado próxima se omite", grabador.registrar(10.05, Vector3(1, 0, 0), 0.0), false)
	_comprobar("segunda muestra se graba", grabador.registrar(10.2, Vector3(1, 0, 0), 0.2, "saludo"), true)
	var exportado := grabador.exportar_evento(AHORA, "ghost-local-001")
	_comprobar("grabador exporta contrato válido", exportado["ok"], true)
	if exportado["ok"]:
		var texto := JSON.stringify(exportado["event"])
		_comprobar("paquete no contiene Partida", texto.find("Partida") == -1, true)
		_comprobar("paquete no contiene textos de expedientes", texto.find("expediente_texto") == -1, true)


func _probar_sueno_seguro() -> void:
	var frames := [
		{"t": 0.0, "position": [0.0, 0.0, 0.0], "yaw": 0.0, "gesture": ""},
		{"t": 0.5, "position": [1.0, 0.0, 0.0], "yaw": 0.0, "gesture": ""},
	]
	var inseguro := GhostDatos.crear_evento(
		"sueno/familia-laberinto",
		"sueno-r1",
		"test-376",
		"anon-sueno",
		frames,
		6.0,
		AHORA,
		"ghost-sueno-inseguro"
	)
	_comprobar("sueño rechaza coordenadas de escena global", inseguro["ok"], false)

	var seguro := GhostDatos.crear_evento(
		"sueno/familia-laberinto",
		"sueno-r1",
		"test-376",
		"anon-sueno",
		frames,
		6.0,
		AHORA,
		"ghost-sueno-seguro",
		"anchor",
		"entrada-local"
	)
	_comprobar("sueño permite anchor local explícito", seguro["ok"], true)


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
