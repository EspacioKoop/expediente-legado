extends SceneTree

const DiaApp := preload("res://guion/dia_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_primera_vuelta()
	_probar_reincorporacion()
	_probar_idempotencia()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _nuevo_dia() -> Node:
	var dia := DiaApp.new()
	dia.partida = Partida.new()
	dia.partida.estado = Partida.nueva()
	dia.jornada = Jornada.nueva()
	return dia


func _probar_primera_vuelta() -> void:
	var dia := _nuevo_dia()
	var resultado: Dictionary = dia._registrar_reincorporacion()
	_comprobar(resultado.get("resultado", "") == "no-cumplido", "primera vuelta no concede")
	_comprobar(
		not Sellos.tiene_sello(dia.partida.estado, DiaApp.SELLO_REINCORPORACION),
		"una partida nueva no tiene reincorporación",
	)
	dia.free()


func _probar_reincorporacion() -> void:
	var dia := _nuevo_dia()
	Jornada.reiniciar_vuelta(dia.jornada)
	_comprobar(int(dia.jornada.get("vuelta", 1)) == 2, "reasignar incrementa la vuelta")
	var resultado: Dictionary = dia._registrar_reincorporacion()
	_comprobar(resultado.get("resultado", "") == "registrado", "segunda vuelta concede")
	_comprobar(
		Sellos.tiene_sello(dia.partida.estado, DiaApp.SELLO_REINCORPORACION),
		"el sello queda en Partida",
	)
	dia.free()


func _probar_idempotencia() -> void:
	var dia := _nuevo_dia()
	dia.jornada["vuelta"] = 3
	var primera: Dictionary = dia._registrar_reincorporacion()
	var segunda: Dictionary = dia._registrar_reincorporacion()
	_comprobar(primera.get("resultado", "") == "registrado", "tercera vuelta registra")
	_comprobar(segunda.get("resultado", "") == "ya-obtenido", "repetir es idempotente")
	var obtenidos: Array = dia.partida.estado.get(Sellos.CLAVE_ESTADO, [])
	_comprobar(
		obtenidos.count(DiaApp.SELLO_REINCORPORACION) == 1,
		"no duplica la colección",
	)
	dia.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SelloReincorporacion: " + nombre)
