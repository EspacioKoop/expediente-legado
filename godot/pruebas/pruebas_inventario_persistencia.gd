extends SceneTree

const RUTA := "user://prueba_inventario_persistencia_97.json"
const RUTA_ANTIGUA := "user://prueba_inventario_persistencia_97_antigua.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar()
	_probar_partida_nueva()
	_probar_guardado_y_recarga()
	_probar_migracion_partida_antigua()
	_probar_validacion()
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_partida_nueva() -> void:
	var estado := Partida.nueva()
	_comprobar(estado.has("inventario"), "una partida nueva crea el inventario persistente")
	_comprobar(
		typeof(estado["inventario"]) == TYPE_DICTIONARY,
		"el inventario persistente es un diccionario"
	)
	_comprobar(
		estado["inventario"][Inventario.CARRIED].is_empty(),
		"una partida nueva no lleva objetos"
	)
	_comprobar(
		estado["inventario"][Inventario.HOME_STORAGE].is_empty(),
		"una partida nueva no tiene objetos guardados en casa"
	)


func _probar_guardado_y_recarga() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var inventario: Dictionary = partida.estado["inventario"]
	var sello := {
		"id": "sello_oficina",
		"origen": "archivo",
		"usos": ["archivo"],
		"vendible": true,
		"precio": 12,
	}
	var llave := {
		"id": "llave_casa",
		"origen": "casa",
		"usos": ["casa"],
		"vendible": false,
	}

	_comprobar(Inventario.recoger(inventario, sello), "recoge el objeto llevado")
	_comprobar(Inventario.recoger(inventario, llave), "recoge el objeto que se guardará")
	_comprobar(
		Inventario.guardar_en_casa(inventario, "llave_casa"),
		"mueve un objeto al almacenamiento doméstico"
	)
	_comprobar(partida.guardar(RUTA), "guarda una partida con inventario")

	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA)
	_comprobar(carga.get("resultado", "") == "cargada", "recarga la partida con inventario")
	var recuperado: Dictionary = recargada.estado["inventario"]
	_comprobar(
		_contar_id(recuperado, "sello_oficina") == 1,
		"el objeto llevado persiste exactamente una vez"
	)
	_comprobar(
		_contar_id(recuperado, "llave_casa") == 1,
		"el objeto doméstico persiste exactamente una vez"
	)
	_comprobar(
		String(recuperado[Inventario.CARRIED][0].get("origen", "")) == "archivo",
		"la recarga conserva metadatos del objeto"
	)
	_comprobar(
		String(recuperado[Inventario.HOME_STORAGE][0].get("id", "")) == "llave_casa",
		"la recarga conserva la ubicación doméstica"
	)

	_comprobar(recargada.guardar(RUTA), "volver a guardar el estado recargado funciona")
	var segunda := Partida.new()
	var segunda_carga := segunda.cargar(RUTA)
	_comprobar(
		segunda_carga.get("resultado", "") == "cargada",
		"una segunda recarga sigue siendo válida"
	)
	_comprobar(
		_contar_id(segunda.estado["inventario"], "sello_oficina") == 1,
		"guardar y cargar repetidamente no duplica carried"
	)
	_comprobar(
		_contar_id(segunda.estado["inventario"], "llave_casa") == 1,
		"guardar y cargar repetidamente no duplica home_storage"
	)


func _probar_migracion_partida_antigua() -> void:
	var antigua := Partida.nueva()
	antigua.erase("inventario")
	_comprobar(_escribir_json(RUTA_ANTIGUA, antigua), "prepara una partida antigua sin inventario")

	var migrada := Partida.new()
	var carga := migrada.cargar(RUTA_ANTIGUA)
	_comprobar(carga.get("resultado", "") == "cargada", "la partida antigua sigue cargando")
	_comprobar(
		migrada.estado.has("inventario"),
		"la carga completa la clave inventario que faltaba"
	)
	_comprobar(
		migrada.estado["inventario"][Inventario.CARRIED].is_empty(),
		"la migración no inventa objetos llevados"
	)
	_comprobar(
		migrada.estado["inventario"][Inventario.HOME_STORAGE].is_empty(),
		"la migración no inventa objetos domésticos"
	)


func _probar_validacion() -> void:
	var forma_invalida := Partida.validar({"version": Partida.VERSION, "inventario": []})
	_comprobar(
		forma_invalida.has("inventario no es un objeto"),
		"rechaza un inventario con forma incompatible"
	)

	var duplicado := {
		"version": Partida.VERSION,
		"inventario": {
			Inventario.CARRIED: [{"id": "mismo"}],
			Inventario.HOME_STORAGE: [{"id": "mismo"}],
		}
	}
	var errores_duplicado := Partida.validar(duplicado)
	_comprobar(
		errores_duplicado.has("inventario contiene id duplicado: mismo"),
		"el guardado no acepta el mismo objeto en dos ubicaciones"
	)


func _contar_id(inventario: Dictionary, objeto_id: String) -> int:
	var total := 0
	for objeto in Inventario.visibles(inventario, true):
		if String(objeto.get("id", "")) == objeto_id:
			total += 1
	return total


func _escribir_json(ruta: String, datos: Dictionary) -> bool:
	var fichero := FileAccess.open(ruta, FileAccess.WRITE)
	if fichero == null:
		return false
	fichero.store_string(JSON.stringify(datos, "\t"))
	fichero.close()
	return true


func _limpiar() -> void:
	for ruta in [RUTA, RUTA + ".nuevo", RUTA + ".roto", RUTA_ANTIGUA, RUTA_ANTIGUA + ".roto"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO InventarioPersistencia: " + nombre)
