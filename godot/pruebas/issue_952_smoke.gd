## Regresión standalone del primer vertical de estrés (#952).
##
##     godot4 --headless --path godot --script pruebas/issue_952_smoke.gd
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_eventos()
	_probar_saturacion()
	_probar_normalizacion()
	_probar_persistencia_json()
	print("issue_952: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_eventos() -> void:
	var jornada := {"dia": 4, "vuelta": 1}
	_comprobar_cerca(Estres.valor(jornada), 0.0, "el estrés empieza neutro")
	_comprobar_cerca(
		Estres.aplicar(jornada, "documento_sensible"),
		12.0,
		"un documento sensible aumenta tensión",
	)
	_comprobar_cerca(
		Estres.aplicar(jornada, "oscuridad", 0.5),
		2.0,
		"la intensidad escala el mismo hecho",
	)
	_comprobar_cerca(
		Estres.aplicar(jornada, "zona_segura"),
		-6.0,
		"una zona segura reduce tensión",
	)
	var antes := Estres.valor(jornada)
	_comprobar_cerca(
		Estres.aplicar(jornada, "evento_inventado"),
		0.0,
		"un evento desconocido no altera estado",
	)
	_comprobar_cerca(Estres.valor(jornada), antes, "el evento inválido deja el valor intacto")


func _probar_saturacion() -> void:
	var jornada := {}
	for _i in 20:
		Estres.aplicar(jornada, "documento_sensible", 2.0)
	_comprobar_cerca(Estres.valor(jornada), 100.0, "la tensión satura en cien")
	_comprobar_cerca(Estres.nivel(jornada), 1.0, "el nivel público satura en uno")
	for _i in 20:
		Estres.aplicar(jornada, "autocuidado", 2.0)
	_comprobar_cerca(Estres.valor(jornada), 0.0, "la recuperación no baja de cero")


func _probar_normalizacion() -> void:
	var jornada := {Estres.CAMPO_JORNADA: {"valor": "ruido"}}
	_comprobar_cerca(Estres.valor(jornada), 0.0, "un valor corrupto vuelve a neutro")
	jornada[Estres.CAMPO_JORNADA] = {"valor": 999.0}
	_comprobar_cerca(Estres.valor(jornada), 100.0, "un guardado excesivo se acota")
	jornada[Estres.CAMPO_JORNADA] = []
	_comprobar_cerca(Estres.valor(jornada), 0.0, "un estado no diccionario se repara")


func _probar_persistencia_json() -> void:
	var jornada := {"dia": 7, "vuelta": 2}
	Estres.aplicar(jornada, "fallo_critico")
	Estres.aplicar(jornada, "sonido_inquietante")
	var restaurada: Variant = JSON.parse_string(JSON.stringify(jornada))
	_comprobar(restaurada is Dictionary, true, "el estado cabe en el guardado JSON")
	if restaurada is Dictionary:
		_comprobar_cerca(
			Estres.valor(restaurada as Dictionary),
			11.0,
			"el valor sobrevive a serializar y restaurar",
		)


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #952: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])


func _comprobar_cerca(actual: float, esperado: float, nombre: String) -> void:
	if is_equal_approx(actual, esperado):
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #952: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
