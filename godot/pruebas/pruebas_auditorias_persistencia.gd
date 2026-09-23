extends SceneTree

const RUTA := "user://prueba_auditorias_152.json"
const RUTA_ANTIGUA := "user://prueba_auditorias_152_antigua.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar()
	_probar_guardado_y_recarga()
	_probar_predicado_accion_sobrante()
	_probar_predicado_gato_diario()
	_probar_cierre_historial()
	_probar_reasignacion()
	_probar_migracion_partida_antigua()
	_probar_validacion()
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_guardado_y_recarga() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	partida.estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([Auditorias.ACCION_SOBRANTE])
	var auditoria: Dictionary = partida.estado[Auditorias.CLAVE_ESTADO]
	var estado_inicial := Auditorias.estado(auditoria, Auditorias.ACCION_SOBRANTE)
	_comprobar(estado_inicial == "activa", "la condición se activa antes de empezar la vida")
	_comprobar(partida.guardar(RUTA), "guarda una partida con auditoría activa")

	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA)
	_comprobar(carga.get("resultado", "") == "cargada", "recarga la partida con auditoría")
	var restaurada: Dictionary = recargada.estado[Auditorias.CLAVE_ESTADO]
	var estado_recargado := Auditorias.estado(restaurada, Auditorias.ACCION_SOBRANTE)
	_comprobar(estado_recargado == "activa", "la recarga conserva la condición activa")


func _probar_predicado_accion_sobrante() -> void:
	var estado := Partida.nueva()
	estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([Auditorias.ACCION_SOBRANTE])
	var jornada: Dictionary = estado["jornada"]

	jornada["acciones"] = 1
	var cumple := Auditorias.resolver_fin_archivo(estado)
	_comprobar(cumple.get("resultado", "") == "activa", "una acción sobrante mantiene el reto")
	var auditoria: Dictionary = estado[Auditorias.CLAVE_ESTADO]
	var estado_cumplido := Auditorias.estado(auditoria, Auditorias.ACCION_SOBRANTE)
	_comprobar(estado_cumplido == "activa", "cumplir un día no completa prematuramente la vida")

	jornada["acciones"] = 0
	var falla := Auditorias.resolver_fin_archivo(estado)
	_comprobar(falla.get("resultado", "") == "fallida", "cero acciones falla la condición")
	var motivo := String(auditoria["fallidas"].get(Auditorias.ACCION_SOBRANTE, ""))
	_comprobar(motivo == "sin_accion_al_fichar", "el fallo conserva un motivo técnico estable")

	jornada["acciones"] = 2
	var terminal := Auditorias.resolver_fin_archivo(estado)
	_comprobar(
		terminal.get("resultado", "") == "fallida",
		"un día posterior no revive una condición ya fallida",
	)


func _probar_predicado_gato_diario() -> void:
	var estado := Partida.nueva()
	estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([Auditorias.GATO_DIARIO])
	var jornada: Dictionary = estado["jornada"]

	jornada["gato"]["presente"] = true
	jornada["gato"]["dias_sin_comer"] = 0
	var cumple := Auditorias.resolver_fin_casa(estado)
	_comprobar(cumple.get("resultado", "") == "activa", "gato atendido mantiene el reto")
	var auditoria: Dictionary = estado[Auditorias.CLAVE_ESTADO]
	_comprobar(
		Auditorias.estado(auditoria, Auditorias.GATO_DIARIO) == "activa",
		"cumplir una noche no completa prematuramente la vida",
	)

	jornada["gato"]["dias_sin_comer"] = 1
	var falla := Auditorias.resolver_fin_casa(estado)
	_comprobar(falla.get("resultado", "") == "fallida", "hambre pendiente falla gato diario")
	_comprobar(
		String(auditoria["fallidas"].get(Auditorias.GATO_DIARIO, ""))
		== "gato_sin_comer_al_dormir",
		"el fallo del gato conserva motivo técnico estable",
	)

	jornada["gato"]["dias_sin_comer"] = 0
	var terminal := Auditorias.resolver_fin_casa(estado)
	_comprobar(
		terminal.get("resultado", "") == "fallida",
		"alimentarlo después no revive una condición ya fallida",
	)

	var ausente := Partida.nueva()
	ausente[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([Auditorias.GATO_DIARIO])
	ausente["jornada"]["gato"]["presente"] = false
	var sin_gato := Auditorias.resolver_fin_casa(ausente)
	_comprobar(sin_gato.get("resultado", "") == "fallida", "gato ausente falla la condición")
	_comprobar(
		String(
			ausente[Auditorias.CLAVE_ESTADO]["fallidas"].get(Auditorias.GATO_DIARIO, "")
		)
		== "gato_ausente_al_dormir",
		"ausencia del gato conserva un motivo técnico estable",
	)


func _probar_cierre_historial() -> void:
	var estado := Partida.nueva()
	estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([Auditorias.ACCION_SOBRANTE])
	estado["jornada"]["acciones"] = 1
	Auditorias.resolver_fin_archivo(estado)

	var registro := Auditorias.cerrar_vuelta(estado, 1, "reasignacion")
	_comprobar(
		registro.get("completadas", []).has(Auditorias.ACCION_SOBRANTE),
		"cerrar la vida completa el reto que seguia activo",
	)
	_comprobar(
		(
			Auditorias.estado(estado[Auditorias.CLAVE_ESTADO], Auditorias.ACCION_SOBRANTE)
			== "completada"
		),
		"el estado vivo queda completado antes del reset",
	)
	var repetido := Auditorias.cerrar_vuelta(estado, 1, "reasignacion")
	_comprobar(repetido == registro, "cerrar dos veces la misma vuelta es idempotente")
	_comprobar(Auditorias.historial(estado).size() == 1, "el historial no duplica la vuelta")

	Prometeo.reiniciar_vuelta(estado, Partida.VIDA_MAXIMA)
	_comprobar(
		(
			Auditorias.estado(estado[Auditorias.CLAVE_ESTADO], Auditorias.ACCION_SOBRANTE)
			== "inactiva"
		),
		"el reset limpia la seleccion activa",
	)
	_comprobar(Auditorias.historial(estado).size() == 1, "el reset conserva el historial sellado")

	var partida := Partida.new()
	partida.estado = estado
	_comprobar(partida.guardar(RUTA), "el historial sellado se puede guardar")
	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA)
	_comprobar(carga.get("resultado", "") == "cargada", "el historial sellado se puede recargar")
	_comprobar(
		Auditorias.historial(recargada.estado).size() == 1,
		"guardar y cargar conserva el historial de auditoria",
	)


func _probar_reasignacion() -> void:
	var estado := Partida.nueva()
	estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([Auditorias.ACCION_SOBRANTE])
	Prometeo.reiniciar_vuelta(estado, Partida.VIDA_MAXIMA)
	var auditoria: Dictionary = estado[Auditorias.CLAVE_ESTADO]
	var estado_reasignado := Auditorias.estado(auditoria, Auditorias.ACCION_SOBRANTE)
	_comprobar(estado_reasignado == "inactiva", "una nueva vida laboral no hereda el reto anterior")
	_comprobar(auditoria["activas"].is_empty(), "la reasignación deja una selección vacía")
	_comprobar(Auditorias.seleccion_pendiente(estado), "la nueva vida queda esperando selección")
	var historial_antes := Auditorias.historial(estado)
	_comprobar(
		Auditorias.resolver_seleccion(estado, [Auditorias.ACCION_SOBRANTE]),
		"la nueva vida acepta una selección exactamente una vez",
	)
	_comprobar(not Auditorias.seleccion_pendiente(estado), "resolver la oferta la cierra")
	_comprobar(
		not Auditorias.resolver_seleccion(estado, []),
		"una selección ya resuelta no se puede sustituir a mitad de vida",
	)
	_comprobar(
		Auditorias.historial(estado) == historial_antes,
		"elegir de nuevo conserva exactamente el historial previo",
	)


func _probar_migracion_partida_antigua() -> void:
	var antigua := Partida.nueva()
	antigua.erase(Auditorias.CLAVE_ESTADO)
	_comprobar(_escribir_json(RUTA_ANTIGUA, antigua), "prepara un guardado anterior a #152")

	var migrada := Partida.new()
	var carga := migrada.cargar(RUTA_ANTIGUA)
	_comprobar(carga.get("resultado", "") == "cargada", "el guardado antiguo sigue cargando")
	_comprobar(
		migrada.estado.has(Auditorias.CLAVE_ESTADO),
		"la migración repone el bloque de auditorías",
	)
	var auditoria: Dictionary = migrada.estado[Auditorias.CLAVE_ESTADO]
	_comprobar(auditoria["activas"].is_empty(), "migrar no activa retos por sorpresa")


func _probar_validacion() -> void:
	var guardado_raiz := {"version": Partida.VERSION, Auditorias.CLAVE_ESTADO: []}
	var errores_raiz := Partida.validar(guardado_raiz)
	_comprobar(
		errores_raiz.has("auditorias no es un objeto"),
		"rechaza una raíz de auditorías con tipo incompatible",
	)

	var guardado_seleccion := {
		"version": Partida.VERSION,
		Auditorias.CLAVE_ESTADO: {"activas": ["inventada"], "fallidas": {}, "completadas": []},
	}
	var errores_seleccion := Partida.validar(guardado_seleccion)
	_comprobar(
		errores_seleccion.has("auditorias.seleccion invalida"),
		"rechaza ids de condición desconocidos",
	)

	var guardado_terminal := {
		"version": Partida.VERSION,
		Auditorias.CLAVE_ESTADO:
		{
			"activas": [Auditorias.ACCION_SOBRANTE],
			"fallidas": {Auditorias.ACCION_SOBRANTE: "motivo"},
			"completadas": [Auditorias.ACCION_SOBRANTE],
		},
	}
	var errores_terminal := Partida.validar(guardado_terminal)
	_comprobar(
		errores_terminal.has("auditorias.estado terminal duplicado: accion_sobrante"),
		"rechaza un reto simultáneamente fallido y completado",
	)


func _escribir_json(ruta: String, datos: Dictionary) -> bool:
	var fichero := FileAccess.open(ruta, FileAccess.WRITE)
	if fichero == null:
		return false
	fichero.store_string(JSON.stringify(datos, "\t"))
	fichero.close()
	return true


func _limpiar() -> void:
	for ruta in [
		RUTA,
		RUTA + ".nuevo",
		RUTA + ".roto",
		RUTA_ANTIGUA,
		RUTA_ANTIGUA + ".nuevo",
		RUTA_ANTIGUA + ".roto",
	]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Auditorias152: " + nombre)
