## Verificación de procedencia real de Crónicas (#2589).
extends SceneTree

var _pasadas := 0
var _fallos := 0
const RUTA_TMP := "user://cronicas-exposicion-test-2589.json"


func _initialize() -> void:
	call_deferred("_probar")


func _app() -> EscritorioSigaApp:
	var app := EscritorioSigaApp.new(
		"cronicas-pc-98", "Cronicas", func() -> Control: return Control.new()
	)
	app.persistir_estado = true
	return app


func _probar() -> void:
	var app := _app()
	var jornada := {"raiz": 2589, "vuelta": 1, "dia": 4}
	_comprobar(not CronicasExposicion2589.prologo_verificado(app, jornada), "abrir no equivale a jugar")
	_comprobar(app.exportar_estado().is_empty(), "sin marcadores inventados en el alta")

	var invalida := {"raiz": 0, "vuelta": 1, "dia": 4}
	_comprobar(not CronicasExposicion2589.registrar_prologo(app, invalida), "raiz nula no acredita")
	_comprobar(not CronicasExposicion2589.registrar_prologo(app, {"raiz": 2589, "vuelta": 0, "dia": 4}), "vuelta invalida")
	_comprobar(not CronicasExposicion2589.registrar_prologo(app, {"raiz": 2589, "vuelta": 1, "dia": 0}), "dia invalido")
	_comprobar(app.exportar_estado().is_empty(), "interaccion incompleta no marca")

	_comprobar(CronicasExposicion2589.registrar_prologo(app, jornada), "completar registra evidencia")
	_comprobar(CronicasExposicion2589.prologo_verificado(app, jornada), "puede verificar esta vuelta")
	_comprobar(not CronicasExposicion2589.registrar_prologo(app, jornada), "doble finalizacion es idempotente")
	var registro: Dictionary = app.obtener_estado_local(CronicasExposicion2589.CAMPO_REGISTRO)
	_comprobar(registro.size() == 1, "una sola entrada por vuelta")
	_comprobar(
		registro["2589:1"]["fuente"] == CronicasExposicion2589.FUENTE_VERIFICADA,
		"proveniencia y capitulo estables",
	)
	jornada["dia"] = 9
	_comprobar(not CronicasExposicion2589.registrar_prologo(app, jornada), "no altera primera fecha")
	_comprobar(registro["2589:1"]["dia"] == 4, "fecha no reescrita")

	var otra_vuelta := {"raiz": 2589, "vuelta": 2, "dia": 9}
	_comprobar(not CronicasExposicion2589.prologo_verificado(app, otra_vuelta), "otra vuelta aun no jugo")
	_comprobar(CronicasExposicion2589.registrar_prologo(app, otra_vuelta), "la nueva vuelta puede jugar")
	_comprobar(registro.size() == 1, "la copia anterior no muta por referencia")

	var partida_distinta := {"raiz": 2590, "vuelta": 1, "dia": 9}
	_comprobar(not CronicasExposicion2589.prologo_verificado(app, partida_distinta), "otras partidas no heredan visita")

	# Guardado de apps, no de campaña: ruta de prueba explicitamente aislada.
	_comprobar(EstadoAplicacionesSiga.guardar([app], RUTA_TMP), "metadata OS98 se guarda")
	var recargado := _app()
	EstadoAplicacionesSiga.cargar([recargado], RUTA_TMP)
	_comprobar(CronicasExposicion2589.prologo_verificado(recargado, jornada), "recarga restaura primera vuelta")
	_comprobar(CronicasExposicion2589.prologo_verificado(recargado, otra_vuelta), "recarga restaura segunda vuelta")
	_comprobar(not CronicasExposicion2589.prologo_verificado(recargado, partida_distinta), "recarga no contamina otras partidas")

	var falso := _app()
	falso.establecer_estado_local(CronicasExposicion2589.CAMPO_REGISTRO,
		{"2589:1": {"fuente": "icono_solo", "raiz": 2589, "vuelta": 1, "dia": 4}})
	_comprobar(not CronicasExposicion2589.prologo_verificado(falso, jornada), "icono o dato incorrecto no acredita")

	var no_persistente := _app()
	no_persistente.persistir_estado = false
	_comprobar(not CronicasExposicion2589.registrar_prologo(no_persistente, jornada), "no registra fuera del contrato OS98")
	var mal_id := _app()
	mal_id.id = "otra-app"
	_comprobar(not CronicasExposicion2589.registrar_prologo(mal_id, jornada), "otra app no puede registrar Crónicas")

	_comprobar(SemillasOniricas.familias_activas(jornada).is_empty(), "visitar no activa semillas de sueño")
	_comprobar(not jornada.has("partida"), "no introduce guardado nuevo en Jornada")
	if FileAccess.file_exists(RUTA_TMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_TMP))
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("Exposicion Crónicas: " + nombre)
