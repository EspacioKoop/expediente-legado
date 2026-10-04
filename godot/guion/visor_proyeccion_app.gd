## Capa de #239 sobre el visor con sello/careo/despido.
##
## Hoy `Acusacion` todavía no produce cintas, así que esta capa no altera el
## flujo actual. Cuando un resultado traiga `cinta_onirica.estado`, la firma se
## guarda primero, se proyecta ese estado ya decidido y después continúa el
## mismo sello/careo de siempre.
extends "res://guion/visor_sello_app.gd"

const ESCENA_PROYECCION := preload("res://escenas/cinematica.tscn")
const COMBATE_CAOS = preload("res://guion/proyeccion_caos_combate_app.gd")

var _combate_caos: JuicioCombate3D


func _al_firmar(resultado: Dictionary, formulario: Control) -> void:
	var cinta: Dictionary = resultado.get("cinta_onirica", {})
	var estado := String(cinta.get("estado", ""))
	if cinta.is_empty() or not ProyeccionOniricaCinematica.es_estado(estado):
		super._al_firmar(resultado, formulario)
		return

	formulario.queue_free()
	# Igual que el sello: la acusación ya ocurrió y se escribe antes de poner
	# imágenes encima. La proyección no puede ser la autoridad del veredicto.
	if not _guardar_o_avisar():
		return
	_imputar.disabled = true
	_reproducir_proyeccion(resultado, estado)


func _reproducir_proyeccion(resultado: Dictionary, estado: String) -> void:
	var id := ProyeccionOniricaCinematica.id_de(estado)
	var reproductor: Node = ESCENA_PROYECCION.instantiate()
	add_child(reproductor)
	reproductor.terminada.connect(_al_terminar_proyeccion.bind(reproductor, resultado))
	reproductor.reproducir(
		ProyeccionOniricaCinematica.planos_de(estado, Cinematica.vistas_de(partida.estado, id)),
		id,
		partida.estado
	)


## Skip y final normal convergen aquí. Solo se intenta conservar la cuenta de
## vistas; aunque ese guardado falle, la firma ya estaba persistida antes de la
## proyección y el flujo debe continuar hasta el sello.
func _al_terminar_proyeccion(reproductor: Node, resultado: Dictionary) -> void:
	reproductor.queue_free()
	_guardar_o_avisar()
	var cinta: Dictionary = resultado.get("cinta_onirica", {})
	if (
		String(cinta.get("estado", "")) == ProyeccionOniricaCinematica.ESTADO_CAOS
		and _abrir_combate_caos(resultado)
	):
		return
	_reproducir_sello(resultado)


func _abrir_combate_caos(resultado: Dictionary) -> bool:
	if is_instance_valid(_combate_caos):
		return true
	var anfitrion := get_parent()
	if anfitrion == null:
		return false
	_combate_caos = COMBATE_CAOS.abrir(
		anfitrion,
		partida.estado,
		Callable(self, "_al_terminar_combate_caos").bind(resultado),
	)
	if not is_instance_valid(_combate_caos):
		return false
	visible = false
	return true


func _al_terminar_combate_caos(_gano: bool, resultado: Dictionary) -> void:
	var combate_actual := _combate_caos
	_combate_caos = null
	if is_instance_valid(combate_actual):
		combate_actual.queue_free()
	visible = true
	_reproducir_sello(resultado)


func _unhandled_input(evento: InputEvent) -> void:
	if not is_instance_valid(_combate_caos):
		return
	if (
		evento.is_action_pressed("cancelar")
		or evento.is_action_pressed("ui_cancel")
	):
		get_viewport().set_input_as_handled()
		_combate_caos.abandonar()
