## Capa de #239 sobre el visor con sello/careo/despido.
##
## Hoy `Acusacion` todavía no produce cintas, así que esta capa no altera el
## flujo actual. Cuando un resultado traiga `cinta_onirica.estado`, la firma se
## guarda primero, se proyecta ese estado ya decidido y después continúa el
## mismo sello/careo de siempre.
extends "res://guion/visor_sello_app.gd"

const ESCENA_PROYECCION := preload("res://escenas/cinematica.tscn")


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
	_reproducir_sello(resultado)
