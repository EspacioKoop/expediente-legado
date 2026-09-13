## Decide si un espacio debe cerrarse por arriba.
##
## El contrato es deliberadamente mínimo: los interiores conservan techo por
## defecto y un exterior debe declararlo explícitamente con `techo = false`.
## La decisión vive en datos para que `Espacio3D` no tenga que conocer nombres
## de fases ni casos especiales como CALLE.
class_name PoliticaTecho
extends RefCounted


static func debe_tener(espacio: Dictionary) -> bool:
	return bool(espacio.get("techo", true))


static func marcar_exterior(espacio: Dictionary) -> Dictionary:
	var resultado := espacio.duplicate(true)
	resultado["techo"] = false
	return resultado
