## Integración real del diálogo diegético en el recorrido (#276).
##
## Esta capa se inserta debajo de clima para mantener estable la raíz de
## `dia.tscn`: calle -> diálogo -> clima -> escena.
extends "res://guion/dia_calle_app.gd"


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	# Un guardado pendiente tiene prioridad absoluta: la capa base sabe cómo
	# reintentarlo sin duplicar efectos de jornada.
	if partida.guardado_pendiente:
		super._al_pisar_salida(cuerpo, salida)
		return
	if cuerpo != _caminante or _pantalla != null:
		super._al_pisar_salida(cuerpo, salida)
		return

	var frase: String = salida.get_meta("frase", "")
	if frase.is_empty():
		super._al_pisar_salida(cuerpo, salida)
		return

	DialogoDiegetico.mostrar(_hud, _mundo, _caminante, salida, tr(frase))
