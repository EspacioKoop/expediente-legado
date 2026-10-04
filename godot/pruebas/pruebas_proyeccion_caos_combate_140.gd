## Regresión pura del remate CAOS de la cámara onírica (#140/#2336).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_gate()
	_probar_objetivo()
	_probar_duracion()
	print("proyeccion_caos_combate_140: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_gate() -> void:
	_comprobar(
		ProyeccionCaosCombate140.debe_abrir({"cinta_onirica": {"estado": "caos"}}),
		"caos abre pelea",
	)
	for estado in ["valida", "contaminada", "blanco", ""]:
		_comprobar(
			not ProyeccionCaosCombate140.debe_abrir({"cinta_onirica": {"estado": estado}}),
			"%s no abre pelea" % estado,
		)
	_comprobar(
		not ProyeccionCaosCombate140.debe_abrir({}),
		"resultado sin cinta conserva flujo normal",
	)


func _probar_objetivo() -> void:
	var objetivo := ProyeccionCaosCombate140.objetivo_publico()
	_comprobar(
		String(objetivo.get("id", "")) == ProyeccionCaosCombate140.ID_PUBLICO,
		"el rival tiene identidad estable",
	)
	_comprobar(
		String(objetivo.get("nombre", "")) == ProyeccionCaosCombate140.CLAVE_NOMBRE_PUBLICO,
		"el nombre visible usa clave traducible",
	)


func _probar_duracion() -> void:
	_comprobar(
		JuicioCombateReglas.determinacion_rival(ProyeccionCaosCombate140.BONO_COMBATE_BREVE)
		== JuicioCombateReglas.DETERMINACION_MINIMA_RIVAL,
		"el remate usa la duracion minima del Juicio comun",
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #2336: " + mensaje)
