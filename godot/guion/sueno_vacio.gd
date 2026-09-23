## Identidad de la noche sin lecturas (#786).
##
## No añade recuerdos: conserva la geometría/salidas seleccionadas por Sueno y
## vacía explícitamente cualquier contenido narrativo. La presentación 3D puede
## así convertir la ausencia en un lenguaje propio sin violar la regla de #87.
class_name SuenoVacio
extends RefCounted

const ID := "vacio"


static func adaptar_espacio(espacio: Dictionary) -> Dictionary:
	var resultado := espacio.duplicate(true)
	resultado["identidad_onirica"] = ID
	resultado["sueno_sin_lecturas"] = true
	resultado["figuras"] = []
	resultado["carteles"] = []
	resultado["decals"] = []
	resultado["ambiente"] = Color(0.075, 0.085, 0.09)
	resultado["ambiente_energia"] = 0.16
	resultado["sol"] = 0.0
	return resultado
