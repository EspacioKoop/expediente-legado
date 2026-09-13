## Capa de presentación del contexto de investigación en el careo (#366).
##
## Reutiliza el folio y el estado que el careo ya recibe. La conclusión se
## muestra como recordatorio documental sin alterar ninguna regla del duelo.
extends "res://guion/careo_app.gd"

var _contexto_investigacion: Dictionary = {}


func _ready() -> void:
	var contenido_contexto := Contenido.new()
	if contenido_contexto.cargar():
		_contexto_investigacion = ContextoCareo.de_folio(
			contenido_contexto.casos,
			folio,
			estado.get("pistas_descubiertas", []),
		)
	super._ready()


func _empezar_duelo() -> void:
	super._empezar_duelo()
	if _contexto_investigacion.is_empty():
		return
	var descripcion := String(_contexto_investigacion.get("descripcion", ""))
	if descripcion.is_empty():
		return
	_cronica.text = descripcion + "\n" + _cronica.text
