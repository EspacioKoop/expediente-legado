extends SceneTree

const RUTA := "user://prueba_auditorias_152.json"
const RUTA_ANTIGUA := "user://prueba_auditorias_152_antigua.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar()
	_probar_guardado_y_recarga()
	_probar_predicado_accion_sobrante()
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
	_comprobar(
		Auditorias.estado(
			partida.estado[Auditorias.CLAVE_ESTADO], Auditorias.ACCION_SOBRANTE
		)
		== "activa",
		"la condición se activa antes de empezar la vida",
	)
	_comprobar(partida.guardar(RUTA), "guarda una partida con auditoría activa")

	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA)
	_comprobar(carga.get("resultado", "") == "cargada", "recarga la partida con auditoría")
	_comprobar(
		Auditorias.estado(
			recargada.estado[Auditorias.CLAVE_ESTADO], Auditorias.ACCION_SOBRANTE
		)
		== "activa",
		"la recarga conserva la condición activa",
	)


func _probar_predicado_accion_sobrante() -> void:
	var estado := Partida.nueva()
	estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([Auditorias.ACCION_SOBRANTE])
	var jornada: Dictionary = estado["jornada"]

	jornada["acciones"] = 1
	var cumple := Auditorias.resolver_fin_archivo(estado)
	_comprobar(cumple.get("resultado", "") == "activa", "una acción sobrante mantiene el reto")
	_comprobar(
		Auditorias.estado(estado[Auditorias.CLAVE_ESTADO], Auditorias.ACCION_SOBRANTE)
		== "activa",
		"cumplir un día no completa prematuramente la vida",
	)

	jornada["acciones"] = 0
	var falla := Auditorias.resolver_fin_archivo(estado)
	_comprobar(falla.get("resultado", "") == "fallida", "cero acciones falla la condición")
	_comprobar(
		estado[Auditorias.CLAVE_ESTADO]["fallidas"].get(Auditorias.ACCION_SOBRANTE, "")
		== "sin_accion_al_fichar",
		"el fallo conserva un motivo técnico estable",
	)

	jornada["acciones"] = 2
	var terminal := Auditorias.resolver_fin_archivo(estado)
	_comprobar(
		terminal.get("resultado", "") == "fallida",
		"un día posterior no revive una condición ya fallida",
	)


func _probar_reasignacion() -> void:
	var estado := Partida.nueva()
	estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([Auditorias.ACCION_SOBRANTE])
	Prometeo.reiniciar_vuelta(estado, Partida.VIDA_MAXIMA)
	_comprobar(
		Auditorias.estado(estado[Auditorias.CLAVE_ESTADO], Auditorias.ACCION_SOBRANTE)
		== "inactiva",
		"una nueva vida laboral no hereda el reto anterior",
	)
	_comprobar(
		estado[Auditorias.CLAVE_ESTADO]["activas"].is_empty(),
		"la reasignación deja una selección vacía",
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
	_comprobar(
		migrada.estado[Auditorias.CLAVE_ESTADO]["activas"].is_empty(),
		"migrar no activa retos por sorpresa",
	)


func _probar_validacion() -> void:
	var errores_raiz := Partida.validar(
		{"version": Partida.VERSION, Auditorias.CLAVE_ESTADO: []}
	)
	_comprobar(
		errores_raiz.has("auditorias no es un objeto"),
		"rechaza una raíz de auditorías con tipo incompatible",
	)

	var errores_seleccion := Partida.validar(
		{
			"version": Partida.VERSION,
			Auditorias.CLAVE_ESTADO:
			{"activas": ["inventada"], "fallidas": {}, "completadas": []},
		}
	)
	_comprobar(
		errores_seleccion.has("auditorias.seleccion invalida"),
		"rechaza ids de condición desconocidos",
	)

	var errores_terminal := Partida.validar(
		{
			"version": Partida.VERSION,
			Auditorias.CLAVE_ESTADO:
			{
				"activas": [Auditorias.ACCION_SOBRANTE],
				"fallidas": {Auditorias.ACCION_SOBRANTE: "motivo"},
				"completadas": [Auditorias.ACCION_SOBRANTE],
			},
		}
	)
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
