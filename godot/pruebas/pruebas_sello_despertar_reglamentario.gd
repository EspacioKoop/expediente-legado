extends SceneTree

const DiaApp := preload("res://guion/dia_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_noche_pendiente()
	_probar_noche_completada()
	_probar_despertar_forzado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_noche_pendiente() -> void:
	var dia = DiaApp.new()
	dia.partida = Partida.new()
	dia.partida.estado = Partida.nueva()
	dia.jornada = Jornada.nueva()
	dia.jornada["fase"] = "casa"
	Jornada.dormir(dia.jornada)

	_comprobar(not dia.jornada["sueno_escenas"].is_empty(), "la noche tiene escenas")
	var resultado: Dictionary = dia._registrar_despertar_reglamentario()
	_comprobar(
		resultado.get("resultado", "") == "no-cumplido",
		"una noche pendiente no concede",
	)
	_comprobar(
		not Sellos.tiene_sello(dia.partida.estado, DiaApp.SELLO_DESPERTAR_REGLAMENTARIO),
		"la colección sigue intacta",
	)
	dia.free()


func _probar_noche_completada() -> void:
	var dia = DiaApp.new()
	dia.partida = Partida.new()
	dia.partida.estado = Partida.nueva()
	dia.jornada = Jornada.nueva()
	dia.jornada["fase"] = "casa"
	Jornada.dormir(dia.jornada)

	_comprobar(float(dia.jornada.get("sueno_total", 0.0)) > 0.0, "la noche tiene duración")
	dia.jornada["sueno_escenas"].clear()
	var primera: Dictionary = dia._registrar_despertar_reglamentario()
	var segunda: Dictionary = dia._registrar_despertar_reglamentario()
	_comprobar(primera.get("resultado", "") == "registrado", "completar la noche concede")
	_comprobar(segunda.get("resultado", "") == "ya-obtenido", "repetir es idempotente")
	dia.free()


func _probar_despertar_forzado() -> void:
	var dia = DiaApp.new()
	dia.partida = Partida.new()
	dia.partida.estado = Partida.nueva()
	dia.jornada = Jornada.nueva()
	dia.jornada["fase"] = "casa"
	Jornada.dormir(dia.jornada)
	Jornada.despertar_de_golpe(dia.jornada)

	var resultado: Dictionary = dia._registrar_despertar_reglamentario()
	_comprobar(
		resultado.get("resultado", "") == "no-cumplido",
		"despertar de golpe no concede",
	)
	_comprobar(
		not Sellos.tiene_sello(dia.partida.estado, DiaApp.SELLO_DESPERTAR_REGLAMENTARIO),
		"un despertar forzado no toca la colección",
	)
	dia.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SelloDespertarReglamentario: " + nombre)
