extends SceneTree

const DiaSenalesMultiplayerApp = preload("res://guion/dia_senales_multiplayer_app.gd")
const SenalDatos = preload("res://guion/red/senal_datos.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")

const AHORA := 2_000_000_000


class HostFalso:
	extends Node3D
	var jornada := {"fase": "trayecto"}
	var _mundo: Node3D

	func _init() -> void:
		_mundo = Node3D.new()
		_mundo.name = "Mundo"
		add_child(_mundo)


var pasadas := 0
var fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var host := HostFalso.new()
	root.add_child(host)
	var controller := DiaSenalesMultiplayerApp.new()
	host.add_child(controller)
	await process_frame

	var evento_escaparate := SenalDatos.crear_evento(
		"calle",
		"test",
		"anon-a",
		"calle_escaparate",
		"cuidado_con",
		["trampa"],
		AHORA,
		[],
		-1,
		"sig-1"
	)
	var evento_portal := SenalDatos.crear_evento(
		"calle", "test", "anon-b", "calle_portal", "sigue", ["derecha"], AHORA + 1, [], -1, "sig-2"
	)
	_comprobar("fixtures válidos", evento_escaparate["ok"] and evento_portal["ok"])
	var fixture := TransporteFixture.new([evento_escaparate["event"], evento_portal["event"]])
	var activacion := controller.activar(fixture)
	_comprobar("activación opt-in", activacion["ok"])
	controller.procesar(1.0, AHORA + 2)
	await process_frame

	var raiz := host._mundo.get_node_or_null("SenalesMultiplayerCalle") as Node3D
	_comprobar("raíz montada en calle", raiz != null)
	_comprobar("dos anchors visibles", controller.estado()["visibles"] == 2)
	_comprobar(
		"escaparate anclado",
		raiz != null and raiz.get_node_or_null("Senal_calle_escaparate") != null,
	)
	_comprobar(
		"portal anclado",
		raiz != null and raiz.get_node_or_null("Senal_calle_portal") != null,
	)

	var publicacion := controller.publicar_en_anchor(
		"anon-local", "calle_escaparate", "cuidado_con", ["alarma"], AHORA + 3, -1, "sig-3"
	)
	_comprobar("publicación usa servicio existente", publicacion["ok"])
	var invalida := controller.publicar_en_anchor(
		"anon-local", "siga_archivo", "cuidado_con", ["alarma"], AHORA + 6
	)
	_comprobar(
		"SIGA no admite anchors", not invalida["ok"] and invalida["status"] == "unknown_anchor"
	)

	host.jornada["fase"] = "oficina"
	controller.procesar(0.1, AHORA + 7)
	_comprobar("salir de trayecto desactiva", not controller.estado()["activa"])
	_comprobar(
		"salir desmonta señales", host._mundo.get_node_or_null("SenalesMultiplayerCalle") == null
	)

	host.queue_free()
	await process_frame
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		pasadas += 1
		print("OK: ", nombre)
	else:
		fallos += 1
		printerr("FALLO: ", nombre)
