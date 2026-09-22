extends SceneTree

## Integra #379 con un Dia mínimo realista sin tocar Partida ni red externa.

const DiaPresenciaCoopApp = preload("res://guion/dia_presencia_coop_app.gd")
const PresenciaDatos = preload("res://guion/red/presencia_datos.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")

const AHORA := 2_100_100_000

var pasadas := 0
var fallos := 0


class HostFalso:
	extends Node3D

	var jornada := {"fase": "trayecto"}
	var _mundo: Node3D
	var _caminante: CharacterBody3D

	func _init() -> void:
		_mundo = Node3D.new()
		_mundo.name = "Mundo"
		add_child(_mundo)

		_caminante = CharacterBody3D.new()
		_caminante.name = "Caminante"
		add_child(_caminante)


func _init() -> void:
	_probar_opt_in_y_frecuencia()
	_probar_remoto_y_gesto()
	_probar_timeout_y_salida_de_fase()
	_probar_offline_por_defecto()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _nuevo_controlador(host: HostFalso) -> DiaPresenciaCoopApp:
	var controlador := DiaPresenciaCoopApp.new()
	host.add_child(controlador)
	controlador._host = host
	return controlador


func _probar_opt_in_y_frecuencia() -> void:
	var host := HostFalso.new()
	var transporte := TransporteFixture.new()
	var controlador := _nuevo_controlador(host)

	_comprobar("empieza inactivo", controlador.estado()["activa"], false)
	controlador.procesar(1.0, AHORA)
	_comprobar("inactivo no publica", transporte.publicados().size(), 0)

	host.jornada["fase"] = "archivo"
	var fuera := controlador.activar_sala("SALA-98", transporte, "anon-local")
	_comprobar("solo activa en trayecto", fuera["status"], "fase_no_compartida")

	host.jornada["fase"] = "trayecto"
	var apertura := controlador.activar_sala("SALA-98", transporte, "anon-local")
	_comprobar("abre sala opt-in", apertura["ok"], true)
	_comprobar("actor explícito se conserva", apertura["actor_public_id"], "anon-local")

	host._caminante.position = Vector3(2, 0, -3)
	host._caminante.rotation.y = 0.75
	host._caminante.velocity = Vector3(1, 0, 0)
	controlador.procesar(0.05, AHORA)
	_comprobar("no supera 10 Hz", transporte.publicados().size(), 0)
	controlador.procesar(0.06, AHORA)
	_comprobar("publica al alcanzar intervalo", transporte.publicados().size(), 1)

	var evento: Dictionary = transporte.publicados()[0]
	_comprobar("escena real es trayecto", evento["scene_key"], "trayecto")
	_comprobar("movimiento se deriva del caminante", evento["payload"]["motion"], "walk")
	_comprobar("posición real se publica", evento["payload"]["position"], [2.0, 0.0, -3.0])
	_comprobar("yaw real se publica", is_equal_approx(evento["payload"]["yaw"], 0.75), true)

	var antes := transporte.publicados().size()
	controlador.procesar(1.0, AHORA + 1)
	_comprobar("un frame largo no crea ráfaga", transporte.publicados().size(), antes + 1)

	controlador.desactivar_sala()
	host.free()


func _probar_remoto_y_gesto() -> void:
	var host := HostFalso.new()
	var transporte := TransporteFixture.new()
	var controlador := _nuevo_controlador(host)
	controlador.activar_sala("SALA-98", transporte, "anon-local")

	var remoto := (
		PresenciaDatos
		. crear_evento(
			"trayecto",
			"test-379",
			"anon-remoto",
			"SALA-98",
			0,
			Vector3(-4, 0, 5),
			-0.5,
			"walk",
			"saludo",
			AHORA,
			"remoto-0",
		)
	)
	transporte.inyectar(remoto["event"])
	controlador.procesar(0.11, AHORA + 1)

	var raiz := host._mundo.get_node_or_null("PresenciasCoopRemotas")
	_comprobar("monta raíz remota en el mundo real", raiz != null, true)
	_comprobar("monta un avatar remoto", raiz != null and raiz.get_child_count() == 1, true)
	_comprobar("estado cuenta remoto", controlador.estado()["remotos"], 1)
	if raiz != null and raiz.get_child_count() == 1:
		var avatar = raiz.get_child(0)
		_comprobar(
			"avatar no tiene API de colisión", avatar.has_method("get_collision_layer"), false
		)
		_comprobar(
			"avatar recibe posición", avatar.estado_visual()["target_position"], Vector3(-4, 0, 5)
		)

	_comprobar("gesto cerrado aceptado", controlador.hacer_gesto("senalar"), true)
	controlador.procesar(0.11, AHORA + 2)
	var ultimo: Dictionary = transporte.publicados()[-1]
	_comprobar("gesto viaja una vez", ultimo["payload"]["gesture"], "senalar")
	controlador.procesar(0.11, AHORA + 3)
	ultimo = transporte.publicados()[-1]
	_comprobar("gesto no queda pegado", ultimo["payload"]["gesture"], "")
	_comprobar("gesto libre se rechaza", controlador.hacer_gesto("hola mundo"), false)

	controlador.desactivar_sala()
	host.free()


func _probar_timeout_y_salida_de_fase() -> void:
	var host := HostFalso.new()
	var transporte := TransporteFixture.new()
	var controlador := _nuevo_controlador(host)
	controlador.activar_sala("SALA-98", transporte, "anon-local")

	var remoto := (
		PresenciaDatos
		. crear_evento(
			"trayecto",
			"test-379",
			"anon-remoto",
			"SALA-98",
			0,
			Vector3.ZERO,
			0.0,
			"idle",
			"",
			AHORA,
			"timeout-remoto",
		)
	)
	transporte.inyectar(remoto["event"])
	controlador.procesar(0.11, AHORA + 1)
	_comprobar("remoto presente antes del timeout", controlador.estado()["remotos"], 1)

	transporte.simular_timeout(true)
	controlador.procesar(0.11, AHORA + PresenciaDatos.TTL_SEGUNDOS + 2)
	_comprobar("timeout no tumba la sesión", controlador.estado()["activa"], true)
	_comprobar("remoto obsoleto expira", controlador.estado()["remotos"], 0)

	host.jornada["fase"] = "casa"
	controlador.procesar(0.01, AHORA + 20)
	_comprobar("salir de trayecto cierra sesión", controlador.estado()["activa"], false)
	_comprobar(
		"salir de trayecto desmonta remotos",
		host._mundo.get_node_or_null("PresenciasCoopRemotas"),
		null,
	)
	host.free()


func _probar_offline_por_defecto() -> void:
	var host := HostFalso.new()
	var controlador := _nuevo_controlador(host)
	var apertura := controlador.activar_sala("LOCAL-98")
	_comprobar("sin backend conserva modo offline", apertura["ok"], true)
	_comprobar(
		"actor generado es seudónimo efímero",
		String(apertura["actor_public_id"]).begins_with("anon-"),
		true
	)
	controlador.procesar(0.11, AHORA)
	_comprobar("offline sigue activo sin bloquear", controlador.estado()["activa"], true)
	_comprobar("offline no inventa remotos", controlador.estado()["remotos"], 0)
	controlador.desactivar_sala()
	host.free()


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
