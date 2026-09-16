extends SceneTree

const Salida := preload("res://guion/salida_partida.gd")
const RUTA_OK := "user://prueba_salida_partida.json"
const RUTA_FALLO := "user://__salida_partida_directorio_ausente__/partida.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar()
	_probar_guardado_correcto()
	_probar_guardado_fallido()
	_probar_partida_ausente()
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_guardado_correcto() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	partida.estado["vida"] = 2
	var resultado := Salida.guardar(partida, RUTA_OK)
	_comprobar(bool(resultado.get("ok", false)), "el guardado correcto permite continuar")
	_comprobar(String(resultado.get("motivo", "x")).is_empty(), "el éxito no arrastra motivo")
	_comprobar(FileAccess.file_exists(RUTA_OK), "el guardado queda escrito en disco")

	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA_OK)
	_comprobar(carga.get("resultado", "") == "cargada", "la salida usa un guardado recargable")
	_comprobar(recargada.estado.get("vida", 0) == 2, "el estado escrito es el estado vigente")


func _probar_guardado_fallido() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	partida.estado["vida"] = 1
	var resultado := Salida.guardar(partida, RUTA_FALLO)
	_comprobar(not bool(resultado.get("ok", true)), "un fallo de disco bloquea la salida")
	_comprobar(not String(resultado.get("motivo", "")).is_empty(), "el fallo conserva su motivo")
	_comprobar(partida.guardado_pendiente, "Partida mantiene pendiente el guardado fallido")
	_comprobar(partida.estado.get("vida", 0) == 1, "fallar al guardar no altera el estado en memoria")


func _probar_partida_ausente() -> void:
	var resultado := Salida.guardar(null, RUTA_OK)
	_comprobar(not bool(resultado.get("ok", true)), "sin partida no se autoriza abandonar")
	_comprobar(
		resultado.get("motivo", "") == Salida.MOTIVO_PARTIDA_NO_DISPONIBLE,
		"la ausencia de partida tiene un motivo estable"
	)


func _limpiar() -> void:
	for ruta in [RUTA_OK, RUTA_OK + ".nuevo"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SalidaPartida: " + nombre)
