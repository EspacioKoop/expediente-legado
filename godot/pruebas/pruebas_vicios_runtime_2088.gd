## Regresión headless de Vicios personificados / ENJAMBRE (#2259).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const RUNTIME = preload("res://guion/juicio_combate_vicios_runtime_2088.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_estado_inicial()
	_probar_presupuesto_compartido()
	_probar_indices_y_ventanas()
	_probar_derrotados()
	_probar_copia_y_determinismo()
	print("vicios_runtime_2088: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_estado_inicial() -> void:
	var estado := RUNTIME.nuevo(2259)
	var unidades: Array = estado["unidades"]
	_comprobar(unidades.size() == RUNTIME.CANTIDAD, "nace con exactamente tres unidades")
	for indice in range(unidades.size()):
		_comprobar(int(unidades[indice]["determinacion"]) > 0, "cada unidad nace viva")
		_comprobar(
			String(unidades[indice]["tipo"]) == ARQUETIPOS.ENJAMBRE,
			"cada unidad reutiliza el arquetipo ENJAMBRE",
		)
	var repetido := RUNTIME.nuevo(2259)
	_comprobar(estado == repetido, "misma raíz produce grupo inicial determinista")


func _grupo_listo() -> Dictionary:
	var estado := RUNTIME.nuevo(2259)
	for unidad in estado["unidades"]:
		unidad["cooldown"] = 0.0
	return estado


func _probar_presupuesto_compartido() -> void:
	var estado := _grupo_listo()
	var maximo := HOST.presupuesto_enjambre()
	var paso := RUNTIME.avanzar(estado, 0.01)
	_comprobar(
		int(paso["atacantes_activos"]) <= maximo,
		"primer tick no supera presupuesto canónico",
	)
	var max_observado := int(paso["atacantes_activos"])
	var ataques := 0
	for _tick in range(400):
		paso = RUNTIME.avanzar(paso["estado"], 0.02)
		max_observado = maxi(max_observado, int(paso["atacantes_activos"]))
		ataques += paso["inicio_ataque"].size()
		_comprobar(
			int(paso["atacantes_activos"]) <= maximo,
			"ningún tick supera presupuesto compartido",
		)
	_comprobar(max_observado == maximo, "el grupo puede ocupar todo el presupuesto canónico")
	_comprobar(ataques > 0, "el ciclo completo llega a producir ataques")


func _probar_indices_y_ventanas() -> void:
	var estado := _grupo_listo()
	var unidades: Array = estado["unidades"]
	unidades[0]["estado"] = ARQUETIPOS.TELEGRAFIAR
	unidades[0]["temporizador"] = 0.0
	unidades[1]["estado"] = ARQUETIPOS.ATACAR
	unidades[1]["temporizador"] = 0.0
	var paso := RUNTIME.avanzar(estado, 0.01)
	_comprobar(paso["inicio_ataque"] == [0], "inicio de ataque conserva índice original")
	_comprobar(paso["abrir_ventana"] == [1], "ventana conserva índice original")
	_comprobar(
		paso["resultados"].size() == RUNTIME.CANTIDAD,
		"resultados conservan alineación con las tres unidades",
	)
	paso = RUNTIME.avanzar(paso["estado"], 0.01)
	_comprobar(paso["inicio_ataque"].is_empty(), "mantener ATACAR no duplica inicio")
	_comprobar(paso["abrir_ventana"].is_empty(), "mantener RECUPERAR no duplica ventana")


func _probar_derrotados() -> void:
	for indice_muerto in range(RUNTIME.CANTIDAD):
		var estado := _grupo_listo()
		var unidades: Array = estado["unidades"]
		unidades[indice_muerto]["determinacion"] = 0
		unidades[indice_muerto]["estado"] = ARQUETIPOS.ATACAR
		unidades[indice_muerto]["temporizador"] = 0.0
		var muerto: Dictionary = unidades[indice_muerto].duplicate(true)
		var paso := RUNTIME.avanzar(estado, 0.01)
		_comprobar(int(paso["vivos"]) == RUNTIME.CANTIDAD - 1, "derrotado reduce contador de vivos")
		_comprobar(
			paso["resultados"][indice_muerto] == {},
			"derrotado queda fuera de resultados activos",
		)
		_comprobar(
			not paso["inicio_ataque"].has(indice_muerto),
			"derrotado no puede iniciar ataque",
		)
		_comprobar(
			not paso["abrir_ventana"].has(indice_muerto),
			"derrotado no puede abrir ventana",
		)
		_comprobar(
			paso["estado"]["unidades"][indice_muerto] == muerto,
			"derrotado conserva índice y no reaparece",
		)

	var todas := _grupo_listo()
	for unidad in todas["unidades"]:
		unidad["determinacion"] = 0
	var final := RUNTIME.avanzar(todas, 10.0)
	_comprobar(int(final["vivos"]) == 0, "grupo completamente derrotado queda a cero")
	_comprobar(int(final["atacantes_activos"]) == 0, "grupo derrotado no consume presupuesto")
	_comprobar(final["inicio_ataque"].is_empty(), "grupo derrotado no ataca")
	_comprobar(final["abrir_ventana"].is_empty(), "grupo derrotado no abre ventanas")


func _probar_copia_y_determinismo() -> void:
	var estado := _grupo_listo()
	var original := estado.duplicate(true)
	var a := RUNTIME.avanzar(estado, 0.01)
	var b := RUNTIME.avanzar(estado, 0.01)
	_comprobar(a == b, "misma entrada produce salida idéntica")
	_comprobar(estado == original, "avanzar no muta estado de entrada")
	a["estado"]["unidades"][0]["determinacion"] = 0
	_comprobar(estado == original, "salida no comparte unidades con entrada")
	_comprobar(
		int(b["estado"]["unidades"][0]["determinacion"]) > 0,
		"resultados de ticks separados son independientes",
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2259 Vicios: " + mensaje)
