extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var catalogo := CatalogoAnomalias.catalogo()
	_comprobar(catalogo.size() >= 3, "hay un catálogo mínimo utilizable")
	_comprobar(_catalogo_es_opaco(catalogo), "el catálogo no filtra ubicación ni solución")
	_comprobar(_hay_anomalia_de_exploracion(catalogo), "hay una anomalía sin requisito de combate")

	var estado := {}
	var primera := CatalogoAnomalias.registrar(estado, "silla-demasiado-alta")
	_comprobar(primera.get("resultado", "") == "registrada", "el primer vistazo registra")
	_comprobar(CatalogoAnomalias.conocida(estado, "silla-demasiado-alta"), "queda en memoria total")
	_comprobar(
		CatalogoAnomalias.conocida_en_vuelta(estado, "silla-demasiado-alta"),
		"queda en memoria de la vuelta"
	)

	var variante := CatalogoAnomalias.registrar_variante(
		estado, "silla-demasiado-alta", "FOLIO-PRUEBA-A"
	)
	_comprobar(
		variante.get("resultado", "") == "variante-registrada",
		"un folio leído añade una variante documental"
	)
	var repetida_variante := CatalogoAnomalias.registrar_variante(
		estado, "silla-demasiado-alta", "FOLIO-PRUEBA-A"
	)
	_comprobar(
		repetida_variante.get("resultado", "") == "variante-conocida",
		"el mismo folio no duplica la variante"
	)
	CatalogoAnomalias.registrar_variante(estado, "silla-demasiado-alta", "FOLIO-PRUEBA-B")
	_comprobar(
		(
			CatalogoAnomalias.variantes(estado, "silla-demasiado-alta")
			== ["FOLIO-PRUEBA-A", "FOLIO-PRUEBA-B"]
		),
		"una misma anomalía conserva variantes de folios distintos"
	)
	_comprobar(
		CatalogoAnomalias.progreso(estado).get("descubiertas_total", 0) == 1,
		"las variantes no cuentan como anomalías adicionales"
	)

	var repetida := CatalogoAnomalias.registrar(estado, "silla-demasiado-alta")
	_comprobar(repetida.get("resultado", "") == "ya-reconocida", "volver a observar no duplica")
	_comprobar(
		estado[CatalogoAnomalias.CLAVE_TOTAL].count("silla-demasiado-alta") == 1,
		"el total mantiene una sola copia"
	)

	CatalogoAnomalias.reiniciar_vuelta(estado)
	_comprobar(
		CatalogoAnomalias.conocida(estado, "silla-demasiado-alta"), "la memoria total sobrevive"
	)
	_comprobar(
		not CatalogoAnomalias.conocida_en_vuelta(estado, "silla-demasiado-alta"),
		"la nueva vida laboral empieza sin hallazgos de vuelta"
	)
	_comprobar(
		CatalogoAnomalias.variantes(estado, "silla-demasiado-alta").size() == 2,
		"reasignar no borra las variantes documentales"
	)
	var reencontrada := CatalogoAnomalias.registrar(estado, "silla-demasiado-alta")
	_comprobar(
		reencontrada.get("resultado", "") == "reencontrada",
		"reconocerla en otra vuelta no la concede de nuevo"
	)

	var estado_sin_base := {}
	var huerfana := CatalogoAnomalias.registrar_variante(
		estado_sin_base, "monitor-estirado", "FOLIO-HUERFANO"
	)
	_comprobar(
		huerfana.get("resultado", "") == "anomalia-no-registrada",
		"una variante no descubre la anomalía base"
	)
	_comprobar(estado_sin_base.is_empty(), "una variante huérfana no modifica memoria")

	var antes_invalida := estado.duplicate(true)
	var invalida := CatalogoAnomalias.registrar(estado, "anomalia-que-no-existe")
	_comprobar(invalida.get("resultado", "") == "desconocida", "una clave inválida se rechaza")
	_comprobar(estado == antes_invalida, "una clave inválida no modifica memoria")

	CatalogoAnomalias.reiniciar_vuelta(estado)
	for entrada in catalogo:
		CatalogoAnomalias.registrar(estado, String(entrada["id"]))
	var progreso := CatalogoAnomalias.progreso(estado)
	_comprobar(
		progreso.get("descubiertas_vuelta", 0) == catalogo.size(),
		"el progreso de vuelta se deriva del catálogo"
	)
	_comprobar(bool(progreso.get("vuelta_completa", false)), "se detecta una vuelta completa")

	_probar_persistencia_y_reasignacion()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_persistencia_y_reasignacion() -> void:
	var ruta := "user://prueba-catalogo-anomalias-%d.json" % Time.get_ticks_usec()
	_limpiar(ruta)

	var partida := Partida.new()
	partida.estado = Partida.nueva()
	_comprobar(
		partida.estado.has(CatalogoAnomalias.CLAVE_TOTAL),
		"Partida declara la memoria total del catálogo"
	)
	_comprobar(
		partida.estado.has(CatalogoAnomalias.CLAVE_VUELTA),
		"Partida declara la memoria de la vuelta"
	)
	CatalogoAnomalias.registrar(partida.estado, "monitor-estirado")
	CatalogoAnomalias.registrar_variante(partida.estado, "monitor-estirado", "FOLIO-PERSISTENTE")
	_comprobar(partida.guardar(ruta), "el reconocimiento se puede guardar")

	var recargada := Partida.new()
	var carga := recargada.cargar(ruta)
	_comprobar(carga.get("resultado", "") == "cargada", "la partida con catálogo recarga")
	_comprobar(
		CatalogoAnomalias.conocida(recargada.estado, "monitor-estirado"),
		"la memoria total sobrevive a guardar y recargar"
	)
	_comprobar(
		CatalogoAnomalias.conocida_en_vuelta(recargada.estado, "monitor-estirado"),
		"la memoria de vuelta también sobrevive a recargar"
	)
	_comprobar(
		CatalogoAnomalias.variantes(recargada.estado, "monitor-estirado") == ["FOLIO-PERSISTENTE"],
		"la variante documental sobrevive a guardar y recargar"
	)

	Prometeo.reiniciar_vuelta(recargada.estado, Partida.VIDA_MAXIMA)
	_comprobar(
		CatalogoAnomalias.conocida(recargada.estado, "monitor-estirado"),
		"reasignar conserva la memoria total"
	)
	_comprobar(
		not CatalogoAnomalias.conocida_en_vuelta(recargada.estado, "monitor-estirado"),
		"reasignar limpia solo la memoria de vuelta"
	)
	_comprobar(
		CatalogoAnomalias.variantes(recargada.estado, "monitor-estirado") == ["FOLIO-PERSISTENTE"],
		"reasignar conserva las variantes documentales"
	)
	_limpiar(ruta)


func _limpiar(ruta: String) -> void:
	for candidata in [ruta, ruta + ".nuevo", ruta + ".roto"]:
		if FileAccess.file_exists(candidata):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidata))


func _catalogo_es_opaco(catalogo: Array) -> bool:
	var permitidas := [
		"id",
		"titulo",
		"descripcion",
		"nota_visual",
		"origen_tipo",
		"origen_id",
		"representacion",
		"modo_observacion",
	]
	for entrada in catalogo:
		for clave in entrada.keys():
			if not permitidas.has(clave):
				return false
	return true


func _hay_anomalia_de_exploracion(catalogo: Array) -> bool:
	for entrada in catalogo:
		if String(entrada.get("modo_observacion", "")) == "exploracion":
			return true
	return false


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO CatalogoAnomalias: " + nombre)
