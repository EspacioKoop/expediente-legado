## Controller hijo para el corte onírico de #400.
##
## Observa el mundo ya construido por Dia y añade dressing solo cuando la fase
## activa es sueño. No cambia la cadena de herencia, no decide objetivos y no
## toca el diccionario espacial que usa #281.
extends Node

var _mundo_vestido_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_vestido_id:
		return

	_mundo_vestido_id = mundo_id
	if String(dia.jornada.get("fase", "")) != "sueño":
		return
	var escenas: Array = dia.jornada.get("sueno_escenas", [])
	if escenas.is_empty():
		return
	(
		SuenoUtileria
		. montar(
			mundo,
			String(escenas[0]),
			int(dia.jornada.get("dia", 1)),
			dia._raiz(),
		)
	)
