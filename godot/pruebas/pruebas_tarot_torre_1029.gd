extends SceneTree

const RUTA := "user://prueba_tarot_torre_1029.json"

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_limpiar()

	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var estado := partida.estado
	var reloj := InactividadPrometeo.new()
	reloj.iniciar(estado)

	var firma_inicial := InactividadPrometeo.firma_progreso(estado)
	estado["jornada"]["fase"] = "trayecto"
	_comprobar(
		InactividadPrometeo.firma_progreso(estado) == firma_inicial,
		"moverse o cambiar de fase no cuenta como progreso de Prometeo",
	)

	_comprobar(
		not reloj.avanzar(estado, 300.0),
		"cinco minutos sin progreso no disparan el final",
	)
	_desbloquear_logro_prueba(estado)
	_comprobar(
		not reloj.avanzar(estado, 500.0),
		"un logro nuevo reinicia el reloj sin consumir el delta de ese cambio",
	)
	_comprobar(
		not reloj.avanzar(estado, InactividadPrometeo.SEGUNDOS_FINAL - 0.1),
		"el final no aparece antes de doce minutos sin progreso",
	)
	_comprobar(
		reloj.avanzar(estado, 0.2),
		"el final aparece al superar doce minutos sin progreso",
	)

	_comprobar(
		Prometeo.desbloquear_carta_en_estado(estado, "la-torre"),
		"el evento real adquiere La Torre por la frontera común",
	)
	_comprobar(
		InactividadPrometeo.desbloquear_logro_final(estado),
		"el mismo final recupera el logro permanente del legado",
	)
	_comprobar(_carta_recogida(estado, "la-torre"), "La Torre queda recogida")
	_comprobar(
		estado.get("cartas_conocidas", []).has("la-torre"),
		"La Torre entra en memoria fantasma",
	)
	_comprobar(
		not Prometeo.desbloquear_carta_en_estado(estado, "la-torre"),
		"repetir el evento no duplica la adquisición",
	)
	_comprobar(
		not InactividadPrometeo.desbloquear_logro_final(estado),
		"repetir el final no duplica el logro",
	)

	_comprobar(partida.guardar(RUTA), "el estado del final se puede persistir")
	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA)
	_comprobar(carga.get("resultado", "") == "cargada", "la partida del final se recarga")
	_comprobar(
		_carta_recogida(recargada.estado, "la-torre"),
		"La Torre persiste al recargar",
	)
	_comprobar(
		recargada.estado.get("cartas_conocidas", []).has("la-torre"),
		"la memoria fantasma persiste al recargar",
	)
	_comprobar(
		_logro_desbloqueado(recargada.estado, InactividadPrometeo.LOGRO_FINAL),
		"el logro del final persiste al recargar",
	)

	var reloj_recarga := InactividadPrometeo.new()
	reloj_recarga.iniciar(recargada.estado)
	_comprobar(
		not reloj_recarga.avanzar(recargada.estado, 0.0),
		"cargar una partida no dispara el final ni Tarot",
	)

	Prometeo.reiniciar_vuelta(recargada.estado, Partida.VIDA_MAXIMA)
	_comprobar(
		not _carta_recogida(recargada.estado, "la-torre"),
		"una nueva vuelta retira la posesión de La Torre",
	)
	_comprobar(
		recargada.estado.get("cartas_conocidas", []).has("la-torre"),
		"una nueva vuelta conserva la memoria de La Torre",
	)
	_comprobar(
		_logro_desbloqueado(recargada.estado, InactividadPrometeo.LOGRO_FINAL),
		"el logro permanente sobrevive a la nueva vuelta",
	)

	var reloj_nueva_vuelta := InactividadPrometeo.new()
	reloj_nueva_vuelta.iniciar(recargada.estado)
	var segundos_final := InactividadPrometeo.SEGUNDOS_FINAL
	var final_nueva_vuelta := reloj_nueva_vuelta.avanzar(recargada.estado, segundos_final)
	_comprobar(final_nueva_vuelta, "la nueva vuelta rearma el final por inactividad")
	_comprobar(
		Prometeo.desbloquear_carta_en_estado(recargada.estado, "la-torre"),
		"La Torre se puede volver a adquirir en la nueva vuelta",
	)

	_limpiar()
	print("tarot_torre_1029: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _desbloquear_logro_prueba(estado: Dictionary) -> void:
	for logro in estado.get("logros", []):
		if String(logro.get("id", "")) == "sospecha":
			logro["desbloqueado"] = true
			return
	for logro in estado.get("logros", []):
		if typeof(logro) == TYPE_DICTIONARY:
			logro["desbloqueado"] = true
			return


func _carta_recogida(estado: Dictionary, carta_id: String) -> bool:
	for carta in estado.get("tarot", []):
		if String(carta.get("id", "")) == carta_id:
			return bool(carta.get("recogida", false))
	return false


func _logro_desbloqueado(estado: Dictionary, logro_id: String) -> bool:
	for logro in estado.get("logros", []):
		if String(logro.get("id", "")) == logro_id:
			return bool(logro.get("desbloqueado", false))
	return false


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("tarot_torre_1029: " + mensaje)


func _limpiar() -> void:
	if FileAccess.file_exists(RUTA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
