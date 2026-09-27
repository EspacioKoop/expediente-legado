extends SceneTree

const DiaSenalesMultiplayerApp = preload("res://guion/dia_senales_multiplayer_app.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")

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
	var fixture := TransporteFixture.new()
	var controller := DiaSenalesMultiplayerApp.new()
	host.add_child(controller)
	await process_frame

	var activacion := controller.activar(fixture, [], "anon-compositor")
	_comprobar("activación con identidad explícita", activacion["ok"])
	_comprobar("dos anchors interactivos", controller.estado()["anchors_interactivos"] == 2)

	var raiz := host._mundo.get_node_or_null("SenalesMultiplayerCalle")
	var interactuable := (
		raiz.get_node_or_null("CrearSenal_calle_escaparate") if raiz != null else null
	)
	_comprobar("escaparate permite abrir compositor", interactuable != null)
	_comprobar(
		"anchor tiene colisión de interacción",
		interactuable != null and interactuable.get_node_or_null("Colision") != null,
	)

	var interactuado := interactuable != null and interactuable.interactuar(host)
	_comprobar("interactuar con anchor abre compositor", interactuado)
	await process_frame

	var compositor := host.get_node_or_null("SenalCompositorUI")
	_comprobar("compositor vive en Dia, no en Partida", compositor != null)
	_comprobar(
		"no existe entrada de texto libre",
		compositor != null and not _contiene_line_edit(compositor),
	)
	var estado_ui: Dictionary = compositor.estado() if compositor != null else {}
	_comprobar("ofrece frases cerradas", int(estado_ui.get("opciones", 0)) > 0)
	_comprobar(
		"token bloqueado no aparece sin conocimiento",
		not _textos_contienen(estado_ui.get("textos", []), "símbolo amarillo"),
	)

	var opciones: Array = compositor.opciones() if compositor != null else []
	var opcion: Dictionary = opciones[0] if not opciones.is_empty() else {}
	_comprobar(
		"opción contiene solo IDs catalogados",
		opcion.has("plantilla_id") and opcion.has("tokens") and not opcion.has("texto_libre"),
	)
	if compositor != null and not opciones.is_empty():
		compositor.seleccionar_opcion(0)
	await process_frame
	_comprobar("publicar cierra compositor", not controller.estado()["compositor_abierto"])
	_comprobar("publicación llega al transporte", fixture.publicados().size() == 1)
	if fixture.publicados().size() == 1:
		var evento: Dictionary = fixture.publicados()[0]
		var payload: Dictionary = evento.get("payload", {})
		_comprobar("evento publicado es signal", String(evento.get("kind", "")) == "signal")
		_comprobar(
			"publicación conserva anchor seleccionado",
			String(payload.get("anchor_id", "")) == "calle_escaparate",
		)

	var invalida := controller.abrir_compositor("siga_archivo")
	_comprobar(
		"SIGA no puede abrir compositor",
		not invalida["ok"] and invalida["status"] == "unknown_anchor",
	)

	host.jornada["fase"] = "oficina"
	controller.procesar(0.1)
	await process_frame
	_comprobar("salir de trayecto desactiva compositor", not controller.estado()["activa"])
	_comprobar("salir de trayecto retira UI", host.get_node_or_null("SenalCompositorUI") == null)

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


func _textos_contienen(textos: Array, aguja: String) -> bool:
	for texto in textos:
		if String(texto).contains(aguja):
			return true
	return false


func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		pasadas += 1
		print("OK: ", nombre)
	else:
		fallos += 1
		printerr("FALLO: ", nombre)
