## Regresión del wiring en el recorrido nocturno, no solo del PackedScene.
## El doble de Dia ofrece únicamente el contrato que usa el controlador.
extends SceneTree

const CONTROLADOR = preload("res://guion/dia_museo_2430_app.gd")


class DiaDoble:
	extends Node3D

	var _mundo: Node3D
	var _espacio_actual := {"entrada": Vector3(3.0, 0.0, 8.0)}
	var jornada := {
		"fase": "sueño",
		"dia": 3,
		"vuelta": 2,
		"raiz": 2430,
		"plantilla": 170,
		"leido_hoy": ["EXP-1998-01"],
		"sueno_escenas": ["patio"],
	}


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var dia := DiaDoble.new()
	dia.name = "Dia"
	var mundo := Node3D.new()
	mundo.name = "Mundo"
	dia._mundo = mundo
	dia.add_child(mundo)
	var controlador := CONTROLADOR.new()
	controlador.name = "MuseoVidasNoOcurridasController"
	dia.add_child(controlador)
	var jornada_antes := dia.jornada.duplicate(true)
	root.add_child(dia)
	await process_frame

	var galeria := mundo.get_node_or_null("GaleriaVidasNoOcurridas")
	_comprobar(galeria is SuenoMuseoEscena2430, "se monta galería en una noche con lectura")
	if galeria == null:
		_terminar()
		return

	var acceso := mundo.get_node_or_null("UmbralMuseo") as Interactuable3D
	var salida := galeria.get_node_or_null("SalidaMuseo") as Interactuable3D
	_comprobar(acceso != null, "el mundo normal ofrece el acceso físico")
	_comprobar(salida != null, "el museo ofrece regreso al mundo normal")
	_comprobar(not salida.habilitado, "la salida comienza inactiva")

	var jugador := CharacterBody3D.new()
	jugador.name = "Jugador"
	mundo.add_child(jugador)
	jugador.global_position = Vector3(3.0, 0.25, 4.0)
	var transform_antes := jugador.global_transform

	_comprobar(acceso.interactuar(jugador), "el jugador entra desde la sala nocturna")
	_comprobar(not acceso.habilitado, "el acceso se bloquea hasta regresar")
	_comprobar(salida.habilitado, "se habilita el regreso")
	_comprobar(
		not jugador.global_transform.is_equal_approx(transform_antes),
		"el jugador visita otra posición física en el museo",
	)
	_comprobar(
		galeria.opciones().size() == 3,
		"las tres posibilidades usan el estado existente de Jornada",
	)
	_comprobar(salida.interactuar(jugador), "el jugador vuelve a su sueño")
	_comprobar(
		jugador.global_transform.is_equal_approx(transform_antes),
		"el portal restituye la posición y la orientación anteriores",
	)
	_comprobar(acceso.habilitado and not salida.habilitado, "el portal es reversible")
	_comprobar(dia.jornada == jornada_antes, "ningún portal modifica Jornada")

	controlador._process(0.0)
	var numero_galerias := 0
	for nodo in mundo.get_children():
		if nodo.name == "GaleriaVidasNoOcurridas":
			numero_galerias += 1
	_comprobar(numero_galerias == 1, "procesar de nuevo no duplica el museo")
	dia.queue_free()
	await process_frame

	# Una noche sin lecturas nunca añade contenido gratuito al sueño.
	var vacio := DiaDoble.new()
	vacio.jornada["leido_hoy"] = []
	var mundo_vacio := Node3D.new()
	vacio._mundo = mundo_vacio
	vacio.add_child(mundo_vacio)
	vacio.add_child(CONTROLADOR.new())
	root.add_child(vacio)
	await process_frame
	_comprobar(
		mundo_vacio.get_node_or_null("GaleriaVidasNoOcurridas") == null,
		"sin documentos leídos no se monta el museo",
	)
	vacio.queue_free()
	await process_frame
	_terminar()


func _terminar() -> void:
	print("dia_museo_2430: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(descripcion)
