extends SceneTree

const RUTA_PRUEBA := "user://prueba_sellos_189.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar_temporales()

	var partida := Partida.new()
	partida.estado = Partida.nueva()
	_comprobar(
		partida.estado.get("sellos_obtenidos", []).is_empty(),
		"una partida nueva empieza sin sellos"
	)

	var primera := Sellos.registrar_sello(partida.estado, "planta-en-orden")
	_comprobar(primera.get("resultado", "") == "registrado", "registra un sello conocido")

	var segunda := Sellos.registrar_sello(partida.estado, "planta-en-orden")
	_comprobar(
		segunda.get("resultado", "") == "ya-obtenido",
		"la segunda concesión se reconoce como duplicada"
	)
	_comprobar(
		partida.estado.get("sellos_obtenidos", []).count("planta-en-orden") == 1,
		"el estado mantiene una sola copia"
	)

	var antes_invalido: Array = partida.estado.get("sellos_obtenidos", []).duplicate()
	var invalido := Sellos.registrar_sello(partida.estado, "sello-que-no-existe")
	_comprobar(
		invalido.get("resultado", "") == "desconocido",
		"una clave desconocida devuelve error controlado"
	)
	_comprobar(
		partida.estado.get("sellos_obtenidos", []) == antes_invalido,
		"una clave desconocida no modifica el estado"
	)

	_comprobar(partida.guardar(RUTA_PRUEBA), "la partida con sello se guarda")

	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA_PRUEBA)
	_comprobar(carga.get("resultado", "") == "cargada", "la partida vuelve a cargar")
	var obtenidos: Array = recargada.estado.get("sellos_obtenidos", [])
	_comprobar(
		obtenidos.count("planta-en-orden") == 1, "guardar y recargar conserva exactamente una copia"
	)
	_comprobar(
		Sellos.tiene_sello(recargada.estado, "planta-en-orden"),
		"la consulta reconoce el sello persistido"
	)
	_comprobar(
		not Sellos.tiene_sello(recargada.estado, "sello-que-no-existe"),
		"la consulta rechaza claves no obtenidas"
	)

	_limpiar_temporales()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _limpiar_temporales() -> void:
	for ruta in [RUTA_PRUEBA, RUTA_PRUEBA + ".nuevo"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SellosPersistencia: " + nombre)
