extends SceneTree

const DiaSenalesMultiplayerApp = preload("res://guion/dia_senales_multiplayer_app.gd")
const SenalDatos = preload("res://guion/red/senal_datos.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")

const AHORA := 2_000_000_100


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


func _initialize() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var host := HostFalso.new()
	root.add_child(host)
	var evento_a := (
		SenalDatos
		. crear_evento(
			"calle",
			"test",
			"anon-a",
			"calle_escaparate",
			"cuidado_con",
			["trampa"],
			AHORA,
			[],
			-1,
			"sig-mod-a",
		)
	)
	var evento_b := (
		SenalDatos
		. crear_evento(
			"calle",
			"test",
			"anon-b",
			"calle_portal",
			"sigue",
			["derecha"],
			AHORA + 1,
			[],
			-1,
			"sig-mod-b",
		)
	)
	_comprobar("fixtures de moderación válidos", evento_a["ok"] and evento_b["ok"])

	var fixture := TransporteFixture.new([evento_a["event"], evento_b["event"]])
	var controller := DiaSenalesMultiplayerApp.new()
	host.add_child(controller)
	await process_frame
	var activacion := controller.activar(fixture, [], "anon-moderador")
	_comprobar("moderación parte del vertical opt-in", activacion["ok"])
	controller.procesar(1.0, AHORA + 2)
	await process_frame

	var raiz := host._mundo.get_node_or_null("SenalesMultiplayerCalle") as Node3D
	var escaparate := (
		raiz.get_node_or_null("Senal_calle_escaparate") as SenalPlayer if raiz != null else null
	)
	_comprobar(
		"señal visible conserva event_id",
		escaparate != null and escaparate.evento_id() == "sig-mod-a"
	)
	_comprobar(
		"señal visible se puede examinar",
		escaparate != null and escaparate.get_node_or_null("Moderar") != null
	)

	var moderador_a := (
		escaparate.get_node_or_null("Moderar") as Interactuable3D if escaparate != null else null
	)
	var interactuado_a := moderador_a.interactuar(host) if moderador_a != null else false
	_comprobar("examinar señal abre moderación", interactuado_a)
	await process_frame

	var ui := host.get_node_or_null("SenalModeracionUI") as SenalModeracionUI
	_comprobar("UI de moderación vive fuera de Partida", ui != null)
	_comprobar(
		"UI de moderación no contiene texto libre", ui != null and not _contiene_line_edit(ui)
	)
	_comprobar(
		"UI apunta al evento mostrado",
		ui != null and String(ui.estado().get("event_id", "")) == "sig-mod-a",
	)
	_comprobar(
		"moderación entrega foco inicial a Ocultar",
		ui != null
		and ui.get_viewport().gui_get_focus_owner() != null
		and ui.get_viewport().gui_get_focus_owner().name == "Ocultar",
	)
	if ui != null:
		ui.solicitar_ocultar()
	await process_frame
	_comprobar(
		"ocultar retira la señal inmediatamente",
		escaparate != null and not escaparate.esta_visible()
	)
	_comprobar("ocultar cierra el panel", not controller.estado()["moderacion_abierta"])

	controller.procesar(1.0, AHORA + 3)
	await process_frame
	_comprobar(
		"señal ocultada no reaparece al refrescar",
		escaparate != null and not escaparate.esta_visible(),
	)

	var portal := (
		raiz.get_node_or_null("Senal_calle_portal") as SenalPlayer if raiz != null else null
	)
	var moderador_b := (
		portal.get_node_or_null("Moderar") as Interactuable3D if portal != null else null
	)
	var interactuado_b := moderador_b.interactuar(host) if moderador_b != null else false
	_comprobar("segunda señal también abre moderación", interactuado_b)
	await process_frame
	ui = host.get_node_or_null("SenalModeracionUI") as SenalModeracionUI
	if ui != null:
		var cancelar := InputEventAction.new()
		cancelar.action = "ui_cancel"
		cancelar.pressed = true
		ui._unhandled_input(cancelar)
	_comprobar("ui_cancel cierra la moderación", not controller.estado()["moderacion_abierta"])
	var reabierto_b := moderador_b.interactuar(host) if moderador_b != null else false
	_comprobar("la señal puede reabrirse tras cancelar", reabierto_b)
	await process_frame
	ui = host.get_node_or_null("SenalModeracionUI") as SenalModeracionUI
	if ui != null:
		ui.solicitar_reportar()
	await process_frame
	_comprobar("reportar también oculta localmente", portal != null and not portal.esta_visible())
	controller.procesar(1.0, AHORA + 4)
	await process_frame
	_comprobar(
		"reportada no reaparece en consultas posteriores",
		portal != null and not portal.esta_visible(),
	)

	host.jornada["fase"] = "oficina"
	controller.procesar(0.1, AHORA + 5)
	await process_frame
	_comprobar(
		"salir de trayecto desmonta moderación", host.get_node_or_null("SenalModeracionUI") == null
	)

	host.queue_free()
	await process_frame
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _contiene_line_edit(nodo: Node) -> bool:
	if nodo is LineEdit:
		return true
	for hijo in nodo.get_children():
		if _contiene_line_edit(hijo):
			return true
	return false


func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		pasadas += 1
		print("OK: ", nombre)
	else:
		fallos += 1
		printerr("FALLO: ", nombre)
