## Capa de #224 sobre el día: activa el cielo CC0 adaptado de Godot Skies.
##
## El ciclo, el sueño y la geometría siguen en las capas anteriores. Aquí solo
## cambia la fuente del fondo del Environment para que exteriores y huecos al
## cielo puedan compartir un recurso visual único y barato.
extends "res://guion/dia_sueno_app.gd"

const CIELO_SIGA := preload("res://arte/cielo_siga.tres")


func _montar_entorno() -> void:
	super._montar_entorno()

	var cielo := Sky.new()
	cielo.process_mode = Sky.PROCESS_MODE_QUALITY
	cielo.radiance_size = Sky.RADIANCE_SIZE_64
	cielo.sky_material = CIELO_SIGA.duplicate()

	_ambiente.background_mode = Environment.BG_SKY
	_ambiente.sky = cielo
