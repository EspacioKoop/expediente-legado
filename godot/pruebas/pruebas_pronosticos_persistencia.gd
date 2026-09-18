extends SceneTree

const RUTA := "user://prueba_pronosticos_persistencia_153.json"
const RUTA_ANTIGUA := "user://prueba_pronosticos_persistencia_153_antigua.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar()
	_probar_guardado_y_recarga()
	_probar_migracion_partida_antigua()
	_probar_reasignacion()
	_probar_validacion()
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_guardado_y_recarga() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var pronosticos: Dictionary = partida.estado["pronosticos"]
	_comprobar(
		Pronosticos.crear(pronosticos, "caso@1", "habra_duelo", true),
		"crea un pronóstico persistible",
	)
	_comprobar(
		Pronosticos.crear(pronosticos, "caso@2", "cierre_hoy", false),
		"crea un segundo pronóstico",
	)
	_comprobar(
		Pronosticos.resolver(pronosticos, "caso@1", true) == Pronosticos.ESTADO_ACERTADO,
		"resuelve un acierto antes de guardar",
	)
	_comprobar(Pronosticos.abandonar(pronosticos, "caso@2"), "abandona sin convertirlo en fallo")
	_comprobar(partida.guardar(RUTA), "guarda una partida con pronósticos")

	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA)
	_comprobar(carga.get("resultado", "") == "cargada", "recarga la partida con pronósticos")
	var restaurados: Dictionary = recargada.estado["pronosticos"]
	_comprobar(
		Pronosticos.estado_de(restaurados, "caso@1") == Pronosticos.ESTADO_ACERTADO,
		"la recarga conserva el acierto",
	)
	_comprobar(
		Pronosticos.estado_de(restaurados, "caso@2") == Pronosticos.ESTADO_ABANDONADO,
		"la recarga conserva el abandono",
	)
	var historial := Pronosticos.historial(restaurados)
	_comprobar(historial.size() == 2, "la recarga conserva el historial completo")
	_comprobar(historial[0]["expediente"] == "caso@1", "el historial sigue siendo determinista")


func _probar_migracion_partida_antigua() -> void:
	var antigua := Partida.nueva()
	antigua.erase("pronosticos")
	_comprobar(_escribir_json(RUTA_ANTIGUA, antigua), "prepara una partida antigua sin pronósticos")

	var migrada := Partida.new()
	var carga := migrada.cargar(RUTA_ANTIGUA)
	_comprobar(carga.get("resultado", "") == "cargada", "la partida antigua sigue cargando")
	_comprobar(migrada.estado.has("pronosticos"), "la migración repone la clave pronosticos")
	_comprobar(
		Pronosticos.historial(migrada.estado["pronosticos"]).is_empty(),
		"la migración no inventa pronósticos",
	)


func _probar_reasignacion() -> void:
	var estado := Partida.nueva()
	_comprobar(
		Pronosticos.crear(estado["pronosticos"], "caso@reasignado", "arrastra_manana", true),
		"registra el pronóstico previo a una reasignación",
	)
	Prometeo.reiniciar_vuelta(estado, Partida.VIDA_MAXIMA)
	Jornada.reiniciar_vuelta(estado["jornada"])
	_comprobar(
		(
			Pronosticos.estado_de(estado["pronosticos"], "caso@reasignado")
			== Pronosticos.ESTADO_ABIERTO
		),
		"la reasignación conserva el historial del auditor",
	)


func _probar_validacion() -> void:
	var errores_raiz := Partida.validar({"version": Partida.VERSION, "pronosticos": []})
	_comprobar(
		errores_raiz.has("pronosticos no es un objeto"),
		"rechaza una raíz de pronósticos incompatible",
	)

	var errores_estado := Partida.validar(
		{
			"version": Partida.VERSION,
			"pronosticos":
			{
				"por_expediente":
				{"caso@1": {"tipo": "habra_duelo", "valor": true, "estado": "inventado"}}
			}
		}
	)
	_comprobar(
		errores_estado.has("pronosticos.caso@1.estado inválido"),
		"rechaza estados de resolución desconocidos",
	)

	var errores_valor := Partida.validar(
		{
			"version": Partida.VERSION,
			"pronosticos":
			{"por_expediente": {"caso@1": {"tipo": "habra_duelo", "estado": "abierto"}}}
		}
	)
	_comprobar(
		errores_valor.has("pronosticos.caso@1.valor ausente"),
		"rechaza pronósticos sin valor",
	)


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
	push_error("FALLO PronosticosPersistencia: " + nombre)
