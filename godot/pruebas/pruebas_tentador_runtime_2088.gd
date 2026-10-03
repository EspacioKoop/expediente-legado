## Regresión headless del Tentador miniado / MIMÉTICO (#2254).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const RUNTIME = preload("res://guion/juicio_combate_tentador_runtime_2088.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_estado_inicial_e_invalidos()
	_probar_patrones_permitidos()
	_probar_patron_congelado_y_ciclo()
	_probar_copia_y_determinismo()
	print("tentador_runtime_2088: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_estado_inicial_e_invalidos() -> void:
	var estado := RUNTIME.nuevo(2254)
	var unidad: Dictionary = estado["unidad"]
	_comprobar(unidad["estado"] == ARQUETIPOS.OBSERVAR, "nace observando")
	_comprobar(String(unidad["patron_eco"]) == "", "nace sin patrón eco")

	for patron in ["", "desconocido", "guardia", "vulnerable"]:
		var paso := RUNTIME.avanzar(estado, 0.5, patron)
		var nueva: Dictionary = paso["estado"]["unidad"]
		_comprobar(nueva["estado"] == ARQUETIPOS.OBSERVAR, "patrón inválido no abandona OBSERVAR")
		_comprobar(String(nueva["patron_eco"]) == "", "patrón inválido no deja eco")
		_comprobar(String(paso["telegraph"]) == "", "patrón inválido no inventa telegraph")
		_comprobar(not bool(paso["ventana_respuesta"]), "patrón inválido no abre ventana")


func _probar_patrones_permitidos() -> void:
	for patron in ARQUETIPOS.MIMETICO_PATRONES_PERMITIDOS:
		var paso := RUNTIME.avanzar(RUNTIME.nuevo(2254), 0.0, patron)
		var unidad: Dictionary = paso["estado"]["unidad"]
		_comprobar(unidad["estado"] == ARQUETIPOS.TELEGRAFIAR_ECO, "permitido entra en telegraph")
		_comprobar(
			String(paso["telegraph"]) == String(patron), "telegraph publica patrón observado"
		)
		_comprobar(String(paso["patron_eco"]) == String(patron), "congela patrón permitido")
		_comprobar(not bool(paso["ventana_respuesta"]), "telegraph no es ventana vulnerable")


func _probar_patron_congelado_y_ciclo() -> void:
	var paso := RUNTIME.avanzar(RUNTIME.nuevo(2254), 0.0, "linea")
	paso = RUNTIME.avanzar(paso["estado"], 0.10, "zona")
	_comprobar(
		String(paso["patron_eco"]) == "linea", "cambiar observado no altera eco en telegraph"
	)
	_comprobar(String(paso["telegraph"]) == "linea", "telegraph conserva patrón congelado")
	_comprobar(
		paso["estado"]["unidad"]["estado"] == ARQUETIPOS.TELEGRAFIAR_ECO,
		"permanece telegrafiando antes de agotar tiempo",
	)

	paso = (
		RUNTIME
		. avanzar(
			paso["estado"],
			ARQUETIPOS.MIMETICO_TELEGRAFO,
			"ataque_corto",
		)
	)
	_comprobar(paso["estado"]["unidad"]["estado"] == ARQUETIPOS.REPETIR, "entra en REPETIR")
	_comprobar(String(paso["patron_eco"]) == "linea", "repetición conserva eco")
	_comprobar(String(paso["telegraph"]) == "linea", "repetición expone mismo patrón")
	_comprobar(not bool(paso["ventana_respuesta"]), "repetición no abre ventana")

	paso = (
		RUNTIME
		. avanzar(
			paso["estado"],
			ARQUETIPOS.MIMETICO_REPETICION,
			"carga_lineal",
		)
	)
	_comprobar(paso["estado"]["unidad"]["estado"] == ARQUETIPOS.RECUPERAR, "entra en RECUPERAR")
	_comprobar(String(paso["telegraph"]) == "vulnerable", "recuperación comunica vulnerabilidad")
	_comprobar(bool(paso["ventana_respuesta"]), "recuperación abre ventana de respuesta")
	_comprobar(String(paso["patron_eco"]) == "linea", "recuperación aún conserva patrón")

	paso = (
		RUNTIME
		. avanzar(
			paso["estado"],
			ARQUETIPOS.MIMETICO_RECUPERACION - 0.01,
			"zona",
		)
	)
	_comprobar(
		paso["estado"]["unidad"]["estado"] == ARQUETIPOS.RECUPERAR, "no sale antes de tiempo"
	)
	_comprobar(bool(paso["ventana_respuesta"]), "ventana dura toda la recuperación")
	_comprobar(String(paso["patron_eco"]) == "linea", "observado nuevo no altera recuperación")

	paso = RUNTIME.avanzar(paso["estado"], 0.02, "zona")
	_comprobar(paso["estado"]["unidad"]["estado"] == ARQUETIPOS.OBSERVAR, "vuelve a OBSERVAR")
	_comprobar(String(paso["patron_eco"]) == "", "limpia eco al cerrar ciclo")
	_comprobar(String(paso["telegraph"]) == "", "cierre de ciclo limpia telegraph")
	_comprobar(not bool(paso["ventana_respuesta"]), "cierre de ciclo cierra ventana")


func _probar_copia_y_determinismo() -> void:
	var estado := RUNTIME.nuevo(2254, 2)
	var original := estado.duplicate(true)
	var a := RUNTIME.avanzar(estado, 0.0, "zona")
	var b := RUNTIME.avanzar(estado, 0.0, "zona")
	_comprobar(a == b, "misma entrada produce salida completa idéntica")
	_comprobar(estado == original, "tick no muta estado de entrada")
	a["estado"]["unidad"]["patron_eco"] = "ataque_corto"
	_comprobar(estado == original, "salida no comparte diccionarios con entrada")
	_comprobar(String(b["patron_eco"]) == "zona", "ticks separados son independientes")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2254 Tentador: " + mensaje)
