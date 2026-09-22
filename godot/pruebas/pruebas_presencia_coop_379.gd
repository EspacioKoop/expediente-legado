extends SceneTree

## Primer vertical ejecutable de #379 sobre el contrato offline-first de #375.

const PresenciaDatos = preload("res://guion/red/presencia_datos.gd")
const PresenciaServicio = preload("res://guion/red/presencia_servicio.gd")
const PresenciaRemota3D = preload("res://guion/red/presencia_remota_3d.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")

const AHORA := 2_100_000_000

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_contrato_cerrado()
	_probar_dos_clientes_fixture()
	_probar_avatar_no_solido_e_interpolado()
	_probar_offline_y_cierre()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_contrato_cerrado() -> void:
	var creado := PresenciaDatos.crear_evento(
		"calle",
		"test-379",
		"anon-a",
		"SALA-98",
		0,
		Vector3(1, 0, 2),
		0.5,
		"walk",
		"saludo",
		AHORA,
		"p-a-0"
	)
	_comprobar("snapshot válido", creado["ok"], true)
	_comprobar("kind presence", creado["event"]["kind"], "presence")
	_comprobar(
		"TTL corto",
		creado["event"]["expires_at"] - creado["event"]["created_at"],
		PresenciaDatos.TTL_SEGUNDOS
	)

	var con_partida: Dictionary = creado["event"].duplicate(true)
	con_partida["payload"]["partida"] = {"dinero": 999, "fase": "archivo"}
	_comprobar(
		"Partida no cabe en payload", PresenciaDatos.validar_evento(con_partida, AHORA)["ok"], false
	)

	var gesto_libre := creado["event"].duplicate(true)
	gesto_libre["payload"]["gesture"] = "texto libre"
	_comprobar(
		"gesto fuera del enum se rechaza",
		PresenciaDatos.validar_evento(gesto_libre, AHORA)["ok"],
		false
	)

	var infinito := creado["event"].duplicate(true)
	infinito["payload"]["position"] = [INF, 0.0, 0.0]
	_comprobar(
		"posición no finita se rechaza", PresenciaDatos.validar_evento(infinito, AHORA)["ok"], false
	)

	_comprobar("room id legible aceptado", PresenciaDatos.validar_room_id("AMIGOS_98-A"), true)
	_comprobar("room id arbitrario rechazado", PresenciaDatos.validar_room_id("../partida"), false)


func _probar_dos_clientes_fixture() -> void:
	var transporte_a := TransporteFixture.new()
	var transporte_b := TransporteFixture.new()
	var cliente_a := PresenciaServicio.new(transporte_a)
	var cliente_b := PresenciaServicio.new(transporte_b)

	_comprobar("A abre sala", cliente_a.abrir_sala("calle", "SALA-98", "anon-a")["ok"], true)
	_comprobar("B abre sala", cliente_b.abrir_sala("calle", "SALA-98", "anon-b")["ok"], true)

	var pub_a := cliente_a.publicar_snapshot(
		"test-379", Vector3(1, 0, 2), 0.5, "walk", "saludo", AHORA, "p-a-0"
	)
	var pub_b := cliente_b.publicar_snapshot(
		"test-379", Vector3(-2, 0, 4), -0.25, "idle", "", AHORA, "p-b-0"
	)
	_comprobar("A publica", pub_a["ok"], true)
	_comprobar("B publica", pub_b["ok"], true)

	transporte_a.inyectar(transporte_b.publicados()[0])
	transporte_b.inyectar(transporte_a.publicados()[0])
	var vistos_a := cliente_a.consultar(AHORA + 1)
	var vistos_b := cliente_b.consultar(AHORA + 1)
	_comprobar("A ve a B", vistos_a["participants"].size(), 1)
	_comprobar("B ve a A", vistos_b["participants"].size(), 1)
	_comprobar("A no se ve a sí mismo", vistos_a["participants"][0]["actor_public_id"], "anon-b")
	_comprobar(
		"pose remota preservada",
		vistos_b["participants"][0]["payload"]["position"],
		[1.0, 0.0, 2.0]
	)

	var repetido := cliente_b.consultar(AHORA + 1)
	_comprobar("snapshot repetido no reaparece", repetido["participants"].size(), 0)

	var pub_a_1 := cliente_a.publicar_snapshot(
		"test-379", Vector3(4, 0, 2), 1.0, "walk", "asentir", AHORA + 2, "p-a-1"
	)
	transporte_b.inyectar(pub_a_1["event"])
	var actualizado := cliente_b.consultar(AHORA + 2)
	_comprobar("secuencia nueva sí llega", actualizado["participants"].size(), 1)
	_comprobar("secuencia avanza", actualizado["participants"][0]["payload"]["seq"], 1)

	cliente_b.ocultar_participante("anon-a")
	var pub_a_2 := cliente_a.publicar_snapshot(
		"test-379", Vector3(5, 0, 2), 1.2, "idle", "", AHORA + 3, "p-a-2"
	)
	transporte_b.inyectar(pub_a_2["event"])
	_comprobar(
		"participante ocultado desaparece", cliente_b.consultar(AHORA + 3)["participants"].size(), 0
	)

	var otro_room := pub_b["event"].duplicate(true)
	otro_room["payload"]["room_id"] = "OTRA-SALA"
	transporte_a.inyectar(otro_room)
	_comprobar("otra sala queda filtrada", cliente_a.consultar(AHORA + 1)["participants"].size(), 0)


func _probar_avatar_no_solido_e_interpolado() -> void:
	var primero := PresenciaDatos.crear_evento(
		"calle",
		"test-379",
		"anon-remoto",
		"SALA-98",
		0,
		Vector3.ZERO,
		0.0,
		"idle",
		"",
		AHORA,
		"avatar-0"
	)
	var segundo := PresenciaDatos.crear_evento(
		"calle",
		"test-379",
		"anon-remoto",
		"SALA-98",
		1,
		Vector3(10, 0, 0),
		1.0,
		"walk",
		"senalar",
		AHORA + 1,
		"avatar-1"
	)
	var avatar := PresenciaRemota3D.new()
	_comprobar("avatar acepta primera muestra", avatar.aplicar_evento(primero["event"]), true)
	_comprobar(
		"avatar visible tiene malla",
		avatar.get_child_count() > 0 and avatar.get_child(0) is MeshInstance3D,
		true
	)
	_comprobar("avatar no es cuerpo de colisión", avatar is CollisionObject3D, false)
	_comprobar("avatar acepta segunda muestra", avatar.aplicar_evento(segundo["event"]), true)
	avatar.avanzar(0.05)
	_comprobar(
		"interpolación no teleporta", avatar.position.x > 0.0 and avatar.position.x < 10.0, true
	)
	_comprobar("gesto visual cerrado llega", avatar.gesture, "senalar")
	avatar.free()


func _probar_offline_y_cierre() -> void:
	var offline := PresenciaServicio.new(TransporteNulo.new())
	var apertura := offline.abrir_sala("calle", "LOCAL-98", "anon-offline")
	_comprobar("offline permite continuar sin error", apertura["ok"], true)
	var publicacion := offline.publicar_snapshot(
		"test-379", Vector3.ZERO, 0.0, "idle", "", AHORA, "offline-0"
	)
	_comprobar("offline descarta explícitamente", publicacion["status"], "discarded_offline")
	_comprobar(
		"offline no inventa participantes", offline.consultar(AHORA)["participants"].size(), 0
	)
	_comprobar("servicio estaba activo", offline.activa(), true)
	var cierre := offline.cerrar_sala()
	_comprobar("cerrar sala es seguro", cierre["ok"], true)
	_comprobar("servicio queda inactivo", offline.activa(), false)
	_comprobar("consulta inactiva es vacía", offline.consultar(AHORA)["participants"].size(), 0)


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
