## Capa de #239 sobre el visor con sello/careo/despido.
##
## Hoy `Acusacion` todavía no produce cintas, así que esta capa no altera el
## flujo actual. Cuando un resultado traiga `cinta_onirica.estado`, la firma se
## guarda primero, se proyecta ese estado ya decidido y después continúa el
## mismo sello/careo de siempre.
extends "res://guion/visor_sello_app.gd"

const ESCENA_PROYECCION := preload("res://escenas/cinematica.tscn")

var _combate_publico_caos: JuicioCombate3D


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
	if ProyeccionCaosCombate140.debe_abrir(resultado):
		_abrir_combate_publico_caos(resultado)
		return
	_reproducir_sello(resultado)


func _abrir_combate_publico_caos(resultado: Dictionary) -> void:
	if is_instance_valid(_combate_publico_caos):
		return
	visible = false
	var combate := JuicioCombate3D.new()
	combate.name = "CombatePublicoCaos"
	(
		combate
		. configurar(
			ProyeccionCaosCombate140.objetivo_publico(),
			ProyeccionCaosCombate140.BONO_COMBATE_BREVE,
			bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false)),
			_raiz(),
		)
	)
	combate.terminado.connect(_al_terminar_combate_publico_caos.bind(combate, resultado))
	_combate_publico_caos = combate
	add_child(combate)
	for hijo in combate.get_children():
		if hijo is Camera3D:
			hijo.current = true
			break


func _al_terminar_combate_publico_caos(
	_gano: bool, combate: JuicioCombate3D, resultado: Dictionary
) -> void:
	if is_instance_valid(combate):
		combate.queue_free()
	_combate_publico_caos = null
	visible = true
	_reproducir_sello(resultado)


func _unhandled_input(evento: InputEvent) -> void:
	if not is_instance_valid(_combate_publico_caos):
		return
	if not evento.is_action_pressed("cancelar") and not evento.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	_combate_publico_caos.abandonar()
