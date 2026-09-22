class_name PruebasJuicioDoctrina
extends RefCounted


static func todo(comprobar: Callable) -> void:
	var cargas := {
		"comunismo": 1,
		"centrista": 1,
		"socialdemocrata": 1,
		"neoliberal": 1,
	}
	var rechazada := JuicioCombateDoctrina.intentar_activar(
		"comunismo", cargas, {}, true, true, "", false
	)
	_caso(comprobar, "doctrina: combate acabado bloquea activación", rechazada["aceptada"], false)
	_caso(comprobar, "doctrina: rechazo no consume carga", cargas["comunismo"], 1)

	var temporizada := JuicioCombateDoctrina.intentar_activar(
		"comunismo", cargas, {}, false, true, "", false
	)
	_caso(comprobar, "doctrina: activación válida consume carga", temporizada["aceptada"], true)
	_caso(comprobar, "doctrina: carga se consume en copia", temporizada["cargas"]["comunismo"], 0)
	_caso(comprobar, "doctrina: original permanece intacto", cargas["comunismo"], 1)
	_caso(
		comprobar,
		"doctrina: comunismo activa estado temporizado",
		temporizada["doctrina_activa"],
		"comunismo",
	)
	_caso(
		comprobar,
		"doctrina: conserva duración base",
		temporizada["doctrina_tiempo"],
		JuicioCombateReglas.DURACION_DOCTRINA,
	)

	var mesa := JuicioCombateDoctrina.intentar_activar(
		"centrista", cargas, {}, false, true, "", false
	)
	_caso(
		comprobar,
		"doctrina: centrista delega mesa",
		mesa["accion"],
		JuicioCombateDoctrina.ACCION_MESA,
	)

	var comision := JuicioCombateDoctrina.intentar_activar(
		"socialdemocrata", cargas, {}, false, true, "", false
	)
	_caso(
		comprobar,
		"doctrina: socialdemocracia delega comisión",
		comision["accion"],
		JuicioCombateDoctrina.ACCION_COMISION,
	)

	var pendiente := JuicioCombateDoctrina.plan_comision(false, 0.0, 0.45, {})
	_caso(comprobar, "doctrina: comisión espera próximo ataque", pendiente["comision_pendiente"], true)
	_caso(
		comprobar,
		"doctrina: espera no altera total",
		is_equal_approx(float(pendiente["telegrafo_total"]), 0.45),
		true,
	)

	var activa := JuicioCombateDoctrina.plan_comision(
		true,
		0.20,
		JuicioCombateReglas.TELEGRAFO_RIVAL,
		{"tags": ["telegraph"]},
	)
	_caso(
		comprobar,
		"doctrina: comisión inmediata deja de estar pendiente",
		activa["comision_pendiente"],
		false,
	)
	_caso(comprobar, "doctrina: comisión pasa a activa", activa["doctrina_activa"], "socialdemocrata")
	_caso(
		comprobar,
		"doctrina: ritual amplía total de telegrafiado",
		is_equal_approx(float(activa["telegrafo_total"]), 1.25),
		true,
	)
	_caso(
		comprobar,
		"doctrina: HUD representa comisión pendiente",
		JuicioCombateDoctrina.eje_estado("", true),
		"socialdemocrata",
	)
	_caso(
		comprobar,
		"doctrina: estado activo bloquea otra doctrina",
		JuicioCombateDoctrina.bloqueada("neoliberal", false),
		true,
	)


static func _caso(comprobar: Callable, nombre: String, obtenido, esperado) -> void:
	comprobar.call(nombre, obtenido, esperado)
