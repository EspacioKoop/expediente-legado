extends SceneTree

const SuenoReligion = preload("res://guion/religion_sueno_935.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_canales_distintos()
	_probar_rom_no_infiere_conviccion()
	_probar_jornada_y_reproducibilidad()
	_probar_reduccion_movimiento()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_canales_distintos() -> void:
	var registro := ReligionEventos.nuevo()
	_registrar(registro, "vista", ReligionEventos.CANAL_EXPOSICION, 3)
	_registrar(registro, "practica", ReligionEventos.CANAL_PRACTICA, 3)
	var capas := SuenoReligion.modificadores(registro, 3)
	_comprobar(capas.size() == 2, "dos canales producen dos capas")
	_comprobar(_capa(capas, "religion:exposicion").has("parametros"), "exposición llega al sueño")
	_comprobar(_capa(capas, "religion:practica").has("parametros"), "práctica llega al sueño")
	_comprobar(
		(
			_capa(capas, "religion:exposicion")["parametros"]
			!= _capa(capas, "religion:practica")["parametros"]
		),
		"exposición y práctica tienen efectos distintos",
	)


func _probar_rom_no_infiere_conviccion() -> void:
	var registro := ReligionEventos.nuevo()
	var evento := (
		ReligionEventos
		. crear_evento(
			"rom:jardines:completa",
			ReligionEventos.CANAL_EXPOSICION,
			"rom:JARDINES98",
			"portatil_color_98",
			5,
			"",
			["rom", "cultura_material"],
			[],
			false,
			[],
			{"procedencia": "rom:handshake"},
		)
	)
	_comprobar(ReligionEventos.registrar(registro, evento), "la ROM registra exposición")
	var capas := SuenoReligion.modificadores(registro, 5)
	_comprobar(
		_capa(capas, "religion:exposicion").has("parametros"), "la ROM aporta material onírico"
	)
	_comprobar(_capa(capas, "religion:conviccion").is_empty(), "la ROM no inventa convicción")
	_comprobar(
		ReligionEventos.eventos(registro, ReligionEventos.CANAL_CONVICCION).is_empty(),
		"el registro de convicción sigue vacío",
	)


func _probar_jornada_y_reproducibilidad() -> void:
	var registro := ReligionEventos.nuevo()
	_registrar(registro, "ayer", ReligionEventos.CANAL_VINCULO, 2)
	_registrar(registro, "hoy", ReligionEventos.CANAL_EXPOSICION, 3)
	var primera := SuenoReligion.modificadores(registro, 3)
	var segunda := SuenoReligion.modificadores(registro, 3)
	_comprobar(primera == segunda, "la misma entrada produce la misma reacción")
	_comprobar(primera.size() == 1, "solo consume hechos de la jornada actual")
	_comprobar(
		String(primera[0].get("origen", "")) == "religion:exposicion",
		"un hecho histórico de otra jornada no se filtra",
	)


func _probar_reduccion_movimiento() -> void:
	var registro := ReligionEventos.nuevo()
	_registrar(registro, "vista", ReligionEventos.CANAL_EXPOSICION, 4)
	var normal := _capa(SuenoReligion.modificadores(registro, 4, false), "religion:exposicion")
	var reducido := _capa(SuenoReligion.modificadores(registro, 4, true), "religion:exposicion")
	_comprobar(
		float(reducido["parametros"]["cirros"]) < float(normal["parametros"]["cirros"]),
		"reducción de movimiento baja el peso animado",
	)
	_comprobar(
		reducido["parametros"].has("estrellas_secundarias"),
		"reducción de movimiento conserva la regla del canal",
	)


func _registrar(registro: Dictionary, id: String, canal: String, dia: int) -> void:
	var evento := ReligionEventos.crear_evento(id, canal, "fixture", "", dia)
	_comprobar(ReligionEventos.registrar(registro, evento), "registra fixture %s" % id)


func _capa(capas: Array, origen: String) -> Dictionary:
	for capa_cruda in capas:
		if typeof(capa_cruda) != TYPE_DICTIONARY:
			continue
		var capa: Dictionary = capa_cruda
		if String(capa.get("origen", "")) == origen:
			return capa
	return {}


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO #935: %s" % nombre)
