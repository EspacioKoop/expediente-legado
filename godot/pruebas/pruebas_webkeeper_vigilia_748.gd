extends SceneTree

## Regresión del handshake de WEBKEEPER 98 hacia Anansi akan (#748).

class ConsolaWebkeeperPrueba:
	extends ConsolaPortatil98

	var titulo_prueba := ""
	var memoria_prueba: Dictionary = {}

	func titulo_rom_activa() -> String:
		return titulo_prueba

	func leer_memoria_rom_u8(direccion: int) -> int:
		return int(memoria_prueba.get(direccion, -1))


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_handshake_webkeeper()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_handshake_webkeeper() -> void:
	var jornada := {"dia": 17}
	var consola := ConsolaWebkeeperPrueba.new()
	root.add_child(consola)

	var observador := Webkeeper98Vigilia.new()
	root.add_child(observador)
	observador.configurar(jornada, consola)
	_comprobar(observador.is_processing(), "el observer empieza activo")

	consola.titulo_prueba = "OTRA_ROM"
	consola.memoria_prueba[Webkeeper98Vigilia.DIRECCION_COMPLETADO] = (
		Webkeeper98Vigilia.MARCA_COMPLETADO
	)
	observador._process(0.0)
	_comprobar(not observador.registrada(), "otra cabecera no activa Anansi")
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada).is_empty(),
		"una ROM distinta no escribe semillas",
	)

	consola.titulo_prueba = Webkeeper98Vigilia.TITULO_ROM
	consola.memoria_prueba[Webkeeper98Vigilia.DIRECCION_COMPLETADO] = 0
	observador._process(0.0)
	_comprobar(not observador.registrada(), "arrancar o jugar a medias no basta")

	consola.memoria_prueba[Webkeeper98Vigilia.DIRECCION_COMPLETADO] = (
		Webkeeper98Vigilia.MARCA_COMPLETADO
	)
	observador._process(0.0)
	_comprobar(observador.registrada(), "ganar la final registra la semilla")
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["anansi_akan"],
		"usa la familia común Anansi akan",
	)

	var semillas := SemillasOniricas.obtener_semillas(jornada)
	var entrada: Dictionary = semillas[SemillasOniricas.clave("anansi_akan")]
	_comprobar(
		entrada["fuentes"],
		["rom:webkeeper_98"],
		"la procedencia queda ligada a la ROM",
	)
	_comprobar(entrada["intensidad"], 2, "la intensidad es declarativa")
	_comprobar(not observador.is_processing(), "tras registrar deja de hacer polling")

	consola.memoria_prueba[Webkeeper98Vigilia.DIRECCION_COMPLETADO] = 0
	observador._process(0.0)
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada)[SemillasOniricas.clave("anansi_akan")]["fuentes"],
		["rom:webkeeper_98"],
		"el registro permanece idempotente",
	)


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Webkeeper #748: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
