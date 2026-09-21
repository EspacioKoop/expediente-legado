extends SceneTree


class ConsolaRomPrueba:
	extends "res://guion/consola_portatil_98.gd"

	var titulo_prueba := ""
	var memoria_prueba: Dictionary = {}

	func titulo_rom_activa() -> String:
		return titulo_prueba

	func leer_memoria_rom_u8(direccion: int) -> int:
		return int(memoria_prueba.get(direccion, -1))


var pasadas := 0
var fallos := 0


func _initialize() -> void:
	_probar_handshake_y_exposicion()
	_probar_consumidor_posterior()
	_probar_segundo_contrato_vitral()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_handshake_y_exposicion() -> void:
	var registro := ReligionEventos.nuevo()
	var jornada := {"dia": 4}
	var consola := ConsolaRomPrueba.new()
	root.add_child(consola)

	var observador := Jali98Vigilia.new()
	root.add_child(observador)
	observador.configurar(registro, jornada, consola)
	_comprobar(observador.is_processing(), "el observer queda activo con contrato válido")

	consola.titulo_prueba = "JALI98"
	consola.memoria_prueba[0xC100] = 0
	observador._process(0.0)
	_comprobar(not observador.registrada(), "arrancar o jugar parcialmente no registra")
	_comprobar(
		ReligionEventos.eventos(registro, ReligionEventos.CANAL_EXPOSICION).is_empty(),
		"sin completar no hay exposición",
	)

	consola.titulo_prueba = "OTRAROM"
	consola.memoria_prueba[0xC100] = 0xA5
	observador._process(0.0)
	_comprobar(not observador.registrada(), "otra ROM no activa el contrato")

	consola.titulo_prueba = "JALI98"
	observador._process(0.0)
	_comprobar(observador.registrada(), "resolver JALI 98 registra exposición")
	_comprobar(not observador.is_processing(), "tras registrar se detiene el polling")

	var exposiciones := ReligionEventos.eventos(registro, ReligionEventos.CANAL_EXPOSICION)
	_comprobar(exposiciones.size() == 1, "solo se registra un hecho")
	var evento: Dictionary = exposiciones[0]
	_comprobar(String(evento["fuente"]) == "rom:jali_98", "la fuente es estable")
	_comprobar(String(evento["tradicion"]) == "islam", "la tradición queda documentada")
	_comprobar(
		String(evento["contexto"]) == "mughal_india:agra:segunda_mitad_siglo_xvi",
		"lugar y periodo no se vuelven estética genérica",
	)
	_comprobar(evento["etiquetas"].has("jali"), "el hecho conserva la materialidad")
	_comprobar(
		ReligionEventos.eventos(registro, ReligionEventos.CANAL_PRACTICA).is_empty(),
		"jugar la ROM no registra práctica",
	)
	_comprobar(
		ReligionEventos.eventos(registro, ReligionEventos.CANAL_CONVICCION).is_empty(),
		"jugar la ROM no infiere convicción",
	)

	observador.free()
	consola.free()


func _probar_consumidor_posterior() -> void:
	var registro := ReligionEventos.nuevo()
	_comprobar(
		ReligionRecuerdoJali932.recuerdo_para_sueno(registro).is_empty(),
		"sin exposición no existe recuerdo posterior",
	)
	var evento := ReligionEventos.crear_evento(
		"exposicion:rom:jali_98:jornada:7",
		ReligionEventos.CANAL_EXPOSICION,
		"rom:jali_98",
		"mughal_india:agra:segunda_mitad_siglo_xvi",
		7,
		"islam",
		["jali", "geometria", "luz_sombra"]
	)
	ReligionEventos.registrar(registro, evento)
	var recuerdo := ReligionRecuerdoJali932.recuerdo_para_sueno(registro)
	_comprobar(not recuerdo.is_empty(), "la experiencia completada tiene consumidor externo")
	_comprobar(
		recuerdo["motivos"] == ["geometria", "luz", "sombra", "calado"],
		"solo reutiliza motivos vistos"
	)
	_comprobar(not bool(recuerdo["hechos_nuevos"]), "el consumidor no introduce hechos nuevos")
	_comprobar(not bool(recuerdo["asume_conviccion"]), "el consumidor no asume convicción")

	var mundo := Node3D.new()
	root.add_child(mundo)
	_comprobar(
		ReligionRecuerdoJali9323D.montar(mundo, {}) == null,
		"sin exposición no aparece geometría onírica",
	)
	var firma := ReligionRecuerdoJali9323D.montar(mundo, recuerdo)
	_comprobar(firma != null, "el recuerdo se materializa en el sueño")
	_comprobar(firma.name == "RecuerdoJali98", "la consecuencia tiene identidad estable")
	_comprobar(firma.get_child_count() == 12, "la proyección reutiliza una geometría legible")
	_comprobar(
		String(firma.get_meta("fuente_cultural", "")) == "rom:jali_98",
		"la proyección conserva su procedencia",
	)
	_comprobar(
		not bool(firma.get_meta("asume_conviccion", true)), "la geometría no infiere convicción"
	)
	_comprobar(
		ReligionRecuerdoJali9323D.montar(mundo, recuerdo) == firma,
		"el mismo mundo no duplica el recuerdo",
	)
	mundo.free()


func _probar_segundo_contrato_vitral() -> void:
	var registro := ReligionEventos.nuevo()
	var jornada := {"dia": 8}
	var consola := ConsolaRomPrueba.new()
	root.add_child(consola)

	var observador := Vitral98Vigilia.new()
	root.add_child(observador)
	observador.configurar(registro, jornada, consola)

	consola.titulo_prueba = "VITRAL98"
	consola.memoria_prueba[0xC100] = 0
	observador._process(0.0)
	_comprobar(not observador.registrada(), "VITRAL 98 parcial no registra exposición")

	consola.memoria_prueba[0xC100] = 0xA5
	observador._process(0.0)
	_comprobar(observador.registrada(), "VITRAL 98 completo usa el observer común")

	var exposiciones := ReligionEventos.eventos(registro, ReligionEventos.CANAL_EXPOSICION)
	_comprobar(exposiciones.size() == 1, "VITRAL 98 registra un único hecho")
	var evento: Dictionary = exposiciones[0]
	_comprobar(String(evento["fuente"]) == "rom:vitral_98", "la segunda ROM conserva su fuente")
	_comprobar(
		String(evento["tradicion"]) == "cristianismo",
		"la procedencia cristiana queda explícita sin asignarla al jugador",
	)
	_comprobar(
		String(evento["contexto"]) == "europa_cristiana:vidriera_taller:ca_1375",
		"la segunda ROM conserva medio y periodo",
	)
	_comprobar(evento["etiquetas"].has("red_plomo"), "la exposición conserva la materialidad")
	_comprobar(
		ReligionEventos.eventos(registro, ReligionEventos.CANAL_PRACTICA).is_empty(),
		"VITRAL 98 tampoco convierte juego en práctica",
	)
	_comprobar(
		ReligionEventos.eventos(registro, ReligionEventos.CANAL_CONVICCION).is_empty(),
		"VITRAL 98 tampoco infiere convicción",
	)

	observador.free()
	consola.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO #932: %s" % nombre)
