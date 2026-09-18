extends SceneTree


class ConsolaRomPrueba:
	extends "res://guion/consola_portatil_98.gd"

	var titulo_prueba := ""
	var memoria_prueba: Dictionary = {}

	func titulo_rom_activa() -> String:
		return titulo_prueba

	func leer_memoria_rom_u8(direccion: int) -> int:
		return int(memoria_prueba.get(direccion, -1))


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_handshake_deliberado()
	_probar_contrato_invalido()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_handshake_deliberado() -> void:
	var jornada := {"dia": 12}
	var consola := ConsolaRomPrueba.new()
	root.add_child(consola)

	var observador := SemillaRomVigilia.new()
	root.add_child(observador)
	(
		observador
		. configurar_contrato(
			jornada,
			consola,
			{
				"id_rom": "ryu_flow_98",
				"id_mito": "dragon_japones",
				"titulo_rom": "RYUFLOW98",
				"direccion": 0xC100,
				"valor": 0xA5,
				"intensidad": 2,
			},
		)
	)
	_comprobar(observador.is_processing(), "un contrato válido queda observando")

	consola.titulo_prueba = "OTRA_ROM"
	consola.memoria_prueba[0xC100] = 0xA5
	observador._process(0.0)
	_comprobar(not observador.registrada(), "otra cabecera no activa la semilla")
	_comprobar(
		SemillasOniricas.familias_activas(jornada).is_empty(),
		"una ROM distinta no contamina la jornada",
	)

	consola.titulo_prueba = "RYUFLOW98"
	consola.memoria_prueba[0xC100] = 0x00
	observador._process(0.0)
	_comprobar(not observador.registrada(), "arrancar o jugar a medias no basta")

	consola.memoria_prueba[0xC100] = 0xA5
	observador._process(0.0)
	_comprobar(observador.registrada(), "el marcador correcto registra la semilla")
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["dragon_japones"],
		"el adapter usa el catálogo común de familias",
	)
	var semillas := SemillasOniricas.obtener_semillas(jornada)
	_comprobar(
		semillas["semilla_onirica_dragon_japones"]["fuentes"],
		["rom:ryu_flow_98"],
		"la fuente estable procede del índice de ROMs",
	)
	_comprobar(not observador.is_processing(), "tras registrar deja de hacer polling")


func _probar_contrato_invalido() -> void:
	var consola := ConsolaRomPrueba.new()
	root.add_child(consola)
	var observador := SemillaRomVigilia.new()
	root.add_child(observador)
	(
		observador
		. configurar_contrato(
			{"dia": 2},
			consola,
			{
				"id_rom": "ryu_flow_98",
				"id_mito": "dragon_japones",
				"titulo_rom": "RYUFLOW98",
				"direccion": -1,
				"valor": 0xA5,
				"intensidad": 2,
			},
		)
	)
	_comprobar(not observador.is_processing(), "una dirección inválida no inicia polling")


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Semilla ROM vigilia: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
