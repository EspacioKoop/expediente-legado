extends SceneTree

const Presentacion := preload("res://guion/dia_presentacion_app.gd")

var _pasadas := 0
var _fallos := 0
var _borrar_emitido := false


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var host := Node3D.new()
	root.add_child(host)
	var presentacion := Presentacion.new()

	var entorno := presentacion.montar_entorno(host, {})
	_comprobar(entorno["ambiente"] is Environment, "devuelve el ambiente común")
	_comprobar(entorno["sol"] is DirectionalLight3D, "devuelve la luz común")
	_comprobar(entorno["caminante"] is CharacterBody3D, "devuelve el caminante")
	_comprobar(entorno["voz"] is AudioStreamPlayer, "devuelve la voz 2D")
	_comprobar(entorno["pisada"] is AudioStreamPlayer3D, "devuelve la voz de pasos")
	_comprobar(bool(entorno["sol"].shadow_enabled), "la luz conserva sombras")
	_comprobar(
		is_equal_approx(float(entorno["pisada"].unit_size), 3.0),
		"los pasos conservan su atenuación",
	)
	_comprobar(entorno["caminante"].get_parent() == host, "el caminante queda en el host")
	_comprobar(
		entorno["pisada"].get_parent() == entorno["caminante"],
		"los pasos siguen pegados al caminante",
	)

	var interfaz := presentacion.montar_interfaz(host, Callable(self, "_al_borrar"))
	_comprobar(interfaz["hud"] is CanvasLayer, "devuelve el HUD base")
	_comprobar(interfaz["rotulo"] is Label, "devuelve el rótulo")
	_comprobar(interfaz["nomina"] is Label, "devuelve la nómina")
	_comprobar(interfaz["borrar"] is Button, "devuelve el botón de borrado")
	_comprobar(not interfaz["borrar"].visible, "borrar sigue oculto fuera de casa")
	_comprobar(
		String(interfaz["borrar"].text) == tr("CASA_BORRAR"),
		"el botón conserva el texto localizado",
	)
	interfaz["borrar"].pressed.emit()
	_comprobar(_borrar_emitido, "el callback de borrado sigue conectado")

	host.queue_free()
	await process_frame
	print("dia_presentacion_1761: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _al_borrar() -> void:
	_borrar_emitido = true


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #1761: %s" % mensaje)
