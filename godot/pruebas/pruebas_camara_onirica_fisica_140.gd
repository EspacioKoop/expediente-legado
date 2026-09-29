## Regresión jugable de adquisición física de cámara onírica (#140).
extends SceneTree

const CONTROLADOR = preload("res://guion/dia_sueno_reactivo_app.gd")

var _pasadas := 0
var _fallos := 0


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
	var _espacio_actual := {"entrada": Vector3.ZERO}

	func _guardar_o_avisar(_mensaje: String) -> bool:
		guardados += 1
		return true


func _init() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.world_3d = World3D.new()
	root.add_child(viewport)

	var dia := DiaFalso.new()
	viewport.add_child(dia)

	dia._mundo = Node3D.new()
	dia._mundo.name = "Mundo"
	dia.add_child(dia._mundo)

	dia._caminante = Node3D.new()
	dia._caminante.name = "Caminante"
	dia.add_child(dia._caminante)
	var camara_jugador := Camera3D.new()
	camara_jugador.name = "Camara"
	camara_jugador.current = true
	dia._caminante.add_child(camara_jugador)

	var controlador := CONTROLADOR.new()
	controlador.set_process(false)
	dia.add_child(controlador)

	var anomalia := AnomaliaSueno3D.new()
	anomalia.name = "AnomaliaGrabable"
	anomalia.position = Vector3(0.0, 0.0, -5.0)
	anomalia.set_meta("documento_origen", "doc-conocido")
	dia._mundo.add_child(anomalia)
	await process_frame

	controlador._montar_camara_si_corresponde(dia, dia._mundo, [anomalia])
	await process_frame
	var camara_objeto := dia._mundo.get_node_or_null("CamaraOniricaAdquirible") as CamaraOnirica3D
	_comprobar("la cámara física aparece", camara_objeto != null, true)
	if camara_objeto != null:
		_comprobar(
			"se recoge con verbo semántico", camara_objeto.verbo, Interactuable3D.Verbo.COGER
		)
		_comprobar("tiene cuerpo visible", camara_objeto.get_node_or_null("Cuerpo") != null, true)
		_comprobar("tiene colisión real", camara_objeto.get_node_or_null("Colision") != null, true)

	var sin_camara := controlador.iniciar_grabacion_anomalia(anomalia)
	_comprobar(
		"sin recoger cámara no puede grabar",
		sin_camara.get("error"),
		controlador.ERROR_CAMARA_NO_ADQUIRIDA,
	)

	if camara_objeto != null:
		camara_objeto.interactuar(dia._caminante)
	await process_frame

	var contenedor := GrabacionOniricaEstado.asegurar_en_estado(dia.partida.estado)
	var cinta: Dictionary = contenedor.get("cinta", {})
	_comprobar("recoger inicializa cinta canónica", cinta.is_empty(), false)
	_comprobar("la cinta tiene diez segundos", cinta.get("capacidad_segundos"), 10.0)
	_comprobar("adquisición guarda una vez", dia.guardados, 1)
	_comprobar(
		"el objeto desaparece tras recoger",
		dia._mundo.get_node_or_null("CamaraOniricaAdquirible"),
		null
	)
	_comprobar("HUD aparece tras adquirir", controlador._hud_camara != null, true)
	_comprobar("HUD muestra metraje", "10.0" in controlador._hud_metraje.text, true)

	var inicio := controlador.iniciar_grabacion_anomalia(anomalia)
	_comprobar("con cámara adquirida puede iniciar toma", inicio.get("ok"), true)
	controlador._process(0.4)
	controlador.interrumpir_grabacion()
	var cierre := controlador.finalizar_grabacion(false, false)
	_comprobar("una toma interrumpida entra en la cinta", cierre.get("ok"), true)

	var segundo_mundo := Node3D.new()
	dia.add_child(segundo_mundo)
	controlador._montar_camara_si_corresponde(dia, segundo_mundo, [anomalia])
	await process_frame
	_comprobar(
		"la cinta existente evita duplicar la cámara física",
		segundo_mundo.get_node_or_null("CamaraOniricaAdquirible"),
		null,
	)

	viewport.queue_free()
	await process_frame
	print("Cámara onírica física 140: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO cámara #140: %s (obtenido=%s esperado=%s)" % [nombre, obtenido, esperado])
