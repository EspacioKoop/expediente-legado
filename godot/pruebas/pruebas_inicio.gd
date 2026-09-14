extends SceneTree

const Inicio := preload("res://guion/inicio_app.gd")

var _fallos := 0
var _pasadas := 0
var _ruta := ""


class InicioPrueba:
	extends "res://guion/inicio_app.gd"
	var entradas := 0

	func _entrar() -> void:
		entradas += 1


class PartidaFallida:
	extends Partida
	var falla := true

	func guardar(destino: String = RUTA) -> bool:
		if falla:
			return false
		return super.guardar(destino)


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_ruta = "user://inicio-prueba-%d.json" % Time.get_ticks_usec()
	var inicio := InicioPrueba.new()
	inicio.ruta = _ruta
	root.add_child(inicio)
	_comprobar(inicio._continuar.disabled, "sin guardado no permite continuar")
	_comprobar(not FileAccess.file_exists(_ruta), "abrir menú no crea partida")
	inicio.free()

	var anterior := Partida.new()
	anterior.estado = Partida.nueva()
	anterior.estado.jornada.dinero = 135
	anterior.estado.jornada.fase = "casa"
	_comprobar(anterior.guardar(_ruta), "prepara guardado aislado")
	var original := FileAccess.get_file_as_string(_ruta)
	inicio = InicioPrueba.new()
	inicio.ruta = _ruta
	root.add_child(inicio)
	_comprobar(not inicio._continuar.disabled, "ofrece continuar")
	_comprobar(FileAccess.get_file_as_string(_ruta) == original, "menú no modifica guardado")
	inicio._nueva.pressed.emit()
	_comprobar(inicio._confirmacion.visible, "nueva requiere confirmación")
	inicio._confirmacion.hide()
	inicio._confirmacion.canceled.emit()
	_comprobar(FileAccess.get_file_as_string(_ruta) == original, "cancelar conserva bytes")
	_comprobar(inicio.entradas == 0, "cancelar no entra al mundo")
	inicio._continuar.pressed.emit()
	_comprobar(inicio.entradas == 1, "continuar entra")
	_comprobar(FileAccess.get_file_as_string(_ruta) == original, "continuar conserva bytes")
	inicio.free()

	inicio = InicioPrueba.new()
	inicio.ruta = _ruta
	var fallida := PartidaFallida.new()
	inicio.partida = fallida
	root.add_child(inicio)
	inicio._empezar()
	_comprobar(inicio.entradas == 0, "fallo de guardado impide entrar")
	_comprobar(inicio._reinicio_pendiente, "permite reintentar estado pendiente")
	_comprobar(inicio._continuar.disabled, "no ofrece continuar sin guardado nuevo")
	_comprobar(FileAccess.get_file_as_string(_ruta + ".roto") == original, "respalda original")
	var semilla: int = fallida.estado.semilla
	fallida.falla = false
	inicio._pedir_nueva()
	_comprobar(inicio.entradas == 1, "reintentar guardado entra una vez")
	_comprobar(fallida.estado.semilla == semilla, "reintento conserva semilla")
	var nueva := Partida.new()
	nueva.cargar(_ruta)
	_comprobar(nueva.estado.jornada.dia == 1, "nueva empieza día uno")
	_comprobar(nueva.estado.jornada.dinero == Jornada.nueva().dinero, "dinero canónico")
	_comprobar(nueva.estado.jornada.fase == "archivo", "nueva empieza en archivo")
	_comprobar(nueva.estado.cinematicas_vistas.is_empty(), "entrada sin vistas anteriores")
	inicio.free()
	for sufijo in ["", ".roto", ".nuevo"]:
		if FileAccess.file_exists(_ruta + sufijo):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_ruta + sufijo))
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
