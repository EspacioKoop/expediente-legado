extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_selector_sin_efectos()
	_probar_consulta_de_estado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_selector_sin_efectos() -> void:
	var estado := Partida.nueva()
	var antes := JSON.stringify(estado[Auditorias.CLAVE_ESTADO])
	var panel := AuditoriasSiga.new()
	panel.configurar_estado(estado, true)
	root.add_child(panel)

	var check := (
		panel.get_node_or_null("Bloque_accion_sobrante/Condicion_accion_sobrante") as CheckBox
	)
	_comprobar(check != null, "el selector construye la condición disponible")
	if check != null:
		_comprobar(not check.disabled, "la condición se puede elegir durante el alta")
		check.set_pressed_no_signal(true)

	var seleccion := panel.seleccion()
	_comprobar(
		seleccion == [Auditorias.ACCION_SOBRANTE],
		"la selección devuelve el id estable de la condición",
	)
	_comprobar(
		JSON.stringify(estado[Auditorias.CLAVE_ESTADO]) == antes,
		"marcar la UI no modifica Partida antes de guardar",
	)

	estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva(seleccion)
	_comprobar(
		Auditorias.estado(estado[Auditorias.CLAVE_ESTADO], Auditorias.ACCION_SOBRANTE) == "activa",
		"el owner puede persistir la selección al aceptar el alta",
	)
	panel.free()


func _probar_consulta_de_estado() -> void:
	var estado := Partida.nueva()
	estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([Auditorias.ACCION_SOBRANTE])
	var panel := AuditoriasSiga.new()
	panel.configurar_estado(estado, false)
	root.add_child(panel)

	var check := (
		panel.get_node_or_null("Bloque_accion_sobrante/Condicion_accion_sobrante") as CheckBox
	)
	var rotulo := panel.get_node_or_null("Bloque_accion_sobrante/Estado_accion_sobrante") as Label
	_comprobar(check != null and check.disabled, "SIGA presenta la condición en solo lectura")
	_comprobar(check != null and check.button_pressed, "SIGA refleja la condición activa")
	_comprobar(rotulo != null and not rotulo.text.is_empty(), "SIGA muestra un estado textual")

	var texto_activo := rotulo.text if rotulo != null else ""
	Auditorias.fallar(estado[Auditorias.CLAVE_ESTADO], Auditorias.ACCION_SOBRANTE, "prueba")
	panel.configurar_estado(estado, false)
	_comprobar(
		rotulo != null and rotulo.text != texto_activo,
		"la consulta se refresca cuando el estado canónico cambia",
	)
	_comprobar(panel.seleccion().is_empty(), "el modo consulta no devuelve una nueva selección")
	panel.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO AuditoriasSiga152: " + nombre)
