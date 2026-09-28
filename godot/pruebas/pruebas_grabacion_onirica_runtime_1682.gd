## Regresión runtime de la primera costura jugable de cámara onírica (#1682).
extends SceneTree

const CONTROLADOR = preload("res://guion/dia_sueno_reactivo_app.gd")

var _pasadas := 0
var _fallos := 0
var _ruta := "user://prueba_grabacion_onirica_runtime_1682.json"


class DiaFalso:
	extends Node3D

	var jornada := {
		"fase": "sueño",
		"leido_hoy": ["doc-conocido"],
	}
	var partida := Partida.new()
	var guardados := 0
	var _mundo: Node3D
	var _caminante: Node3D

	func _guardar_o_avisar(_mensaje: String) -> bool:
		guardados += 1
		return true


func _init() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_limpiar()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.world_3d = World3D.new()
	root.add_child(viewport)

	var dia := DiaFalso.new()
	viewport.add_child(dia)
	dia._caminante = Node3D.new()
	dia._caminante.name = "Caminante"
	dia.add_child(dia._caminante)
	var camara := Camera3D.new()
	camara.name = "Camara"
	camara.current = true
	dia._caminante.add_child(camara)

	var controlador := CONTROLADOR.new()
	controlador.set_process(false)
	dia.add_child(controlador)

	var conocida := _anomalia("Conocida", "doc-conocido", Vector3(0.0, 0.0, -5.0))
	dia.add_child(conocida)
	var desconocida := _anomalia("Desconocida", "doc-ajeno", Vector3(0.0, 0.0, -5.0))
	dia.add_child(desconocida)
	await process_frame

	GrabacionOniricaEstado.iniciar_cinta(dia.partida.estado, 10.0)
	_probar_valida(controlador, dia, conocida)
	_probar_desconocida(controlador, dia, desconocida)
	_probar_contaminada(controlador, dia, conocida)
	_probar_salida_sueno(controlador, dia, conocida)
	_probar_roundtrip(dia.partida)

	viewport.queue_free()
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _anomalia(nombre: String, documento: String, posicion: Vector3) -> AnomaliaSueno3D:
	var anomalia := AnomaliaSueno3D.new()
	anomalia.name = nombre
	anomalia.position = posicion
	anomalia.set_meta("documento_origen", documento)
	return anomalia


func _probar_valida(controlador: Node, dia: DiaFalso, anomalia: AnomaliaSueno3D) -> void:
	var inicio: Dictionary = controlador.iniciar_grabacion_anomalia(anomalia)
	_comprobar("un original conocido inicia toma", inicio.get("ok"), true)
	controlador._process(0.7)
	anomalia.position = Vector3(0.0, 0.0, 5.0)
	controlador._process(0.3)
	var resultado: Dictionary = controlador.finalizar_grabacion(true, false)
	_comprobar("la toma runtime entra en la cinta", resultado.get("ok"), true)
	_comprobar(
		"más de la mitad en cuadro produce válida",
		resultado.get("evaluacion", {}).get("estado"),
		GrabacionOniricaContrato.ESTADO_VALIDA,
	)
	_comprobar(
		"runtime conserva el original real",
		resultado.get("toma", {}).get("original_id"),
		"doc-conocido",
	)
	_comprobar(
		"registrar no selecciona a escondidas",
		GrabacionOniricaEstado.seleccion_actual(dia.partida.estado),
		{},
	)
	var antes := dia.partida.estado[GrabacionOniricaEstado.CLAVE_ESTADO]["cinta"]["tomas"].size()
	var repetida: Dictionary = controlador.finalizar_grabacion(true, false)
	_comprobar("finalizar dos veces se rechaza", repetida.get("ok"), false)
	_comprobar(
		"finalizar dos veces no duplica",
		dia.partida.estado[GrabacionOniricaEstado.CLAVE_ESTADO]["cinta"]["tomas"].size(),
		antes,
	)
	anomalia.position = Vector3(0.0, 0.0, -5.0)


func _probar_desconocida(
	controlador: Node, dia: DiaFalso, anomalia: AnomaliaSueno3D
) -> void:
	var antes := dia.partida.estado[GrabacionOniricaEstado.CLAVE_ESTADO]["cinta"]["tomas"].size()
	var inicio: Dictionary = controlador.iniciar_grabacion_anomalia(anomalia)
	_comprobar("un original no leído no inicia toma", inicio.get("ok"), false)
	_comprobar(
		"original desconocido no registra nada",
		dia.partida.estado[GrabacionOniricaEstado.CLAVE_ESTADO]["cinta"]["tomas"].size(),
		antes,
	)


func _probar_contaminada(
	controlador: Node, dia: DiaFalso, anomalia: AnomaliaSueno3D
) -> void:
	anomalia.position = Vector3(0.0, 0.0, -5.0)
	_comprobar(
		"segunda toma conocida puede empezar",
		controlador.iniciar_grabacion_anomalia(anomalia).get("ok"),
		true,
	)
	controlador._process(0.5)
	anomalia.position = Vector3(0.0, 0.0, 5.0)
	controlador._process(0.5)
	var resultado: Dictionary = controlador.finalizar_grabacion(true, false)
	_comprobar(
		"cincuenta por ciento conserva contaminada",
		resultado.get("evaluacion", {}).get("estado"),
		GrabacionOniricaContrato.ESTADO_CONTAMINADA,
	)
	anomalia.position = Vector3(0.0, 0.0, -5.0)


func _probar_salida_sueno(
	controlador: Node, dia: DiaFalso, anomalia: AnomaliaSueno3D
) -> void:
	var antes := dia.partida.estado[GrabacionOniricaEstado.CLAVE_ESTADO]["cinta"]["tomas"].size()
	_comprobar(
		"toma previa a despertar empieza",
		controlador.iniciar_grabacion_anomalia(anomalia).get("ok"),
		true,
	)
	controlador._process(0.6)
	dia.jornada["fase"] = "casa"
	controlador._process(0.1)
	var tomas: Array = dia.partida.estado[GrabacionOniricaEstado.CLAVE_ESTADO]["cinta"]["tomas"]
	_comprobar("salir del sueño persiste la toma interrumpida", tomas.size(), antes + 1)
	_comprobar(
		"salir del sueño marca contaminación",
		tomas[-1].get("estado"),
		GrabacionOniricaContrato.ESTADO_CONTAMINADA,
	)
	_comprobar("salir del sueño cierra la medición", controlador.grabacion_activa(), false)
	_comprobar("cada registro pide guardado", dia.guardados >= 3, true)
	dia.jornada["fase"] = "sueño"


func _probar_roundtrip(partida: Partida) -> void:
	_comprobar("guardado runtime con cinta", partida.guardar(_ruta), true)
	var releida := Partida.new()
	var carga := releida.cargar(_ruta)
	_comprobar("recarga conserva cinta runtime", carga.get("resultado"), "cargada")
	var original: Dictionary = partida.estado[GrabacionOniricaEstado.CLAVE_ESTADO]["cinta"]
	var copia: Dictionary = releida.estado[GrabacionOniricaEstado.CLAVE_ESTADO]["cinta"]
	_comprobar("recarga conserva tomas y metraje", copia, original)
	_comprobar(
		"recarga sigue sin selección implícita",
		releida.estado[GrabacionOniricaEstado.CLAVE_ESTADO]["toma_seleccionada"],
		GrabacionOniricaEstado.SIN_TOMA,
	)


func _limpiar() -> void:
	for sufijo in ["", ".nuevo", ".roto"]:
		var ruta := _ruta + sufijo
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		_pasadas += 1
		return
	_fallos += 1
	printerr("FALLO %s: esperado=%s obtenido=%s" % [nombre, esperado, obtenido])
