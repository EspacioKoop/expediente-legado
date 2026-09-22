extends SceneTree

const RUTA_PRUEBA := "user://prueba_pasaporte_inspeccion_154.json"

var _pasadas := 0
var _fallos := 0
var _estado_interaccion: Dictionary = {}


func _initialize() -> void:
	_limpiar_temporales()
	_probar_catalogo()
	_probar_registro_idempotente()
	_probar_interaccion_real()
	_probar_persistencia()
	_limpiar_temporales()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_catalogo() -> void:
	var catalogo := PasaporteInspeccion.catalogo()
	_comprobar(catalogo.size() == 4, "el primer corte declara cuatro puntos")

	var ids := {}
	var zonas := {}
	var modos_validos := true
	for entrada in catalogo:
		ids[String(entrada.get("id", ""))] = true
		zonas[String(entrada.get("zona", ""))] = true
		modos_validos = modos_validos and String(entrada.get("modo_observacion", "")) == "examinar"

	_comprobar(ids.size() == catalogo.size(), "los ids de inspección son únicos")
	var zonas_validas := zonas.size() == PasaporteInspeccion.ZONAS.size()
	for zona in zonas:
		zonas_validas = zonas_validas and PasaporteInspeccion.ZONAS.has(zona)
	_comprobar(
		zonas_validas,
		"hay exactamente un corte para archivo, trayecto, casa y sueño"
	)
	_comprobar(modos_validos, "todos los puntos exigen observación EXAMINAR")
	_comprobar(SuenoFormas.ids().has("peine"), "el punto onírico referencia una sala existente")


func _probar_registro_idempotente() -> void:
	var estado := {Sellos.CLAVE_ESTADO: []}
	var primera := PasaporteInspeccion.registrar_observacion(estado, "archivo:mesa-clasificacion")
	_comprobar(primera.get("resultado", "") == "registrado", "la primera observación registra")

	var repetida := PasaporteInspeccion.registrar_observacion(estado, "archivo:mesa-clasificacion")
	_comprobar(repetida.get("resultado", "") == "ya-observado", "repetir no concede dos veces")

	var id_sello := PasaporteInspeccion.sello_id("archivo:mesa-clasificacion")
	_comprobar(
		estado.get(Sellos.CLAVE_ESTADO, []).count(id_sello) == 1,
		"el almacén persistente conserva una sola copia"
	)

	var antes := estado.duplicate(true)
	var desconocido := PasaporteInspeccion.registrar_observacion(estado, "archivo:no-existe")
	_comprobar(desconocido.get("resultado", "") == "desconocido", "un punto desconocido se rechaza")
	_comprobar(estado == antes, "un punto desconocido no modifica el estado")


func _probar_interaccion_real() -> void:
	_estado_interaccion = {Sellos.CLAVE_ESTADO: []}
	var punto := PuntoInspeccion3D.new()
	punto.configurar("casa:ventana")
	punto.observado.connect(_al_observar)

	_comprobar(
		punto.verbo == Interactuable3D.Verbo.EXAMINAR,
		"el punto usa la acción semántica EXAMINAR"
	)
	_comprobar(punto.interactuar(null), "la interacción habilitada se ejecuta")
	_comprobar(
		PasaporteInspeccion.observado(_estado_interaccion, "casa:ventana"),
		"solo tras interactuar llega la observación al registro"
	)
	punto.free()


func _probar_persistencia() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	_comprobar(
		partida.estado.has(Sellos.CLAVE_ESTADO),
		"Partida ya declara el almacén persistente reutilizado"
	)

	var jornada: Dictionary = partida.estado.get("jornada", {})
	var dinero_antes := int(jornada.get("dinero", 0))
	var acciones_antes := int(jornada.get("acciones", 0))
	var pistas_antes: Array = partida.estado.get("pistas_descubiertas", []).duplicate()

	var registro := PasaporteInspeccion.registrar_observacion(partida.estado, "trayecto:farola-sodio")
	_comprobar(registro.get("resultado", "") == "registrado", "el punto de trayecto se registra")
	_comprobar(int(jornada.get("dinero", 0)) == dinero_antes, "inspeccionar no concede dinero")
	_comprobar(int(jornada.get("acciones", 0)) == acciones_antes, "inspeccionar no concede acciones")
	_comprobar(
		partida.estado.get("pistas_descubiertas", []) == pistas_antes,
		"inspeccionar no concede pistas"
	)

	_comprobar(partida.guardar(RUTA_PRUEBA), "la partida con inspección se guarda")

	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA_PRUEBA)
	_comprobar(carga.get("resultado", "") == "cargada", "la partida vuelve a cargar")
	_comprobar(
		PasaporteInspeccion.observado(recargada.estado, "trayecto:farola-sodio"),
		"la observación sobrevive a guardar y recargar"
	)

	var id_sello := PasaporteInspeccion.sello_id("trayecto:farola-sodio")
	_comprobar(
		recargada.estado.get(Sellos.CLAVE_ESTADO, []).count(id_sello) == 1,
		"la recarga conserva exactamente una copia"
	)
	var repetida := PasaporteInspeccion.registrar_observacion(
		recargada.estado, "trayecto:farola-sodio"
	)
	_comprobar(
		repetida.get("resultado", "") == "ya-observado",
		"repetir después de recargar sigue siendo idempotente"
	)
	_comprobar(
		recargada.estado.get(Sellos.CLAVE_ESTADO, []).count(id_sello) == 1,
		"la repetición tras recarga no duplica"
	)


func _al_observar(punto_id: String, _actor: Node) -> void:
	PasaporteInspeccion.registrar_observacion(_estado_interaccion, punto_id)


func _limpiar_temporales() -> void:
	for ruta in [RUTA_PRUEBA, RUTA_PRUEBA + ".nuevo", RUTA_PRUEBA + ".roto"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PasaporteInspeccion154: " + nombre)
