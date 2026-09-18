extends SceneTree

const DiaApp := preload("res://guion/dia_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_emisor()
	_probar_senal_de_acusacion()
	_probar_reset_diario()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_emisor() -> void:
	var dia := DiaApp.new()
	dia.partida = Partida.new()
	dia.partida.estado = Partida.nueva()
	dia.jornada = Jornada.nueva()

	var vacia: Dictionary = dia._registrar_firma_sin_prisa()
	_comprobar(vacia.get("resultado", "") == "no-cumplido", "cero cierres no concede")
	_comprobar(
		not Sellos.tiene_sello(dia.partida.estado, "firma-sin-prisa"),
		"cero cierres no toca la colección",
	)

	dia.jornada["cerrados_hoy"] = 2
	var limpia: Dictionary = dia._registrar_firma_sin_prisa()
	_comprobar(limpia.get("resultado", "") == "registrado", "jornada limpia concede")
	_comprobar(
		Sellos.tiene_sello(dia.partida.estado, "firma-sin-prisa"),
		"la concesión usa la colección persistente",
	)
	var repetida: Dictionary = dia._registrar_firma_sin_prisa()
	_comprobar(repetida.get("resultado", "") == "ya-obtenido", "repetir es idempotente")

	var bloqueada := DiaApp.new()
	bloqueada.partida = Partida.new()
	bloqueada.partida.estado = Partida.nueva()
	bloqueada.jornada = Jornada.nueva()
	bloqueada.jornada["cerrados_hoy"] = 1
	bloqueada.jornada["acusaciones_precipitadas_hoy"] = 1
	var fallo: Dictionary = bloqueada._registrar_firma_sin_prisa()
	_comprobar(fallo.get("resultado", "") == "no-cumplido", "una precipitada bloquea")
	_comprobar(
		not Sellos.tiene_sello(bloqueada.partida.estado, "firma-sin-prisa"),
		"una precipitada no concede",
	)

	dia.free()
	bloqueada.free()


func _probar_senal_de_acusacion() -> void:
	var sospechoso := {"id": "s1", "nombre": "S1", "desenlace": ""}
	var caso := {
		"id": "caso-prueba",
		"pistas": [{"id": "p1"}],
		"sospechosos": [sospechoso],
	}

	var estado_precipitado := Partida.nueva()
	var jornada_precipitada := Jornada.nueva()
	var precipitada := Acusacion.acusar(
		estado_precipitado, jornada_precipitada, caso, sospechoso, []
	)
	_comprobar(bool(precipitada.get("precipitada", false)), "la prueba produce precipitada")
	_comprobar(
		int(jornada_precipitada.get("acusaciones_precipitadas_hoy", 0)) == 1,
		"la precipitada deja una señal diaria",
	)

	var estado_limpio := Partida.nueva()
	var jornada_limpia := Jornada.nueva()
	var limpia := Acusacion.acusar(estado_limpio, jornada_limpia, caso, sospechoso, ["p1"])
	_comprobar(not bool(limpia.get("precipitada", true)), "evidencia suficiente no precipita")
	_comprobar(
		int(jornada_limpia.get("acusaciones_precipitadas_hoy", 0)) == 0,
		"una firma limpia no incrementa la señal",
	)


func _probar_reset_diario() -> void:
	var jornada := Jornada.nueva()
	jornada["fase"] = "sueño"
	jornada["acusaciones_precipitadas_hoy"] = 3
	Jornada.despertar(jornada)
	_comprobar(
		int(jornada.get("acusaciones_precipitadas_hoy", -1)) == 0,
		"despertar limpia la señal diaria",
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SelloFirmaSinPrisa: " + nombre)
