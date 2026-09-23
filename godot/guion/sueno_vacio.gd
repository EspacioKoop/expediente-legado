## Identidad de la noche sin lecturas (#786).
##
## No añade recuerdos: conserva el destino/timing de la escena seleccionada,
## vacía explícitamente cualquier contenido narrativo y sustituye la planta
## ortogonal por una familia fragmentada ya validada por #279.
class_name SuenoVacio
extends RefCounted

const ID := "vacio"
const FAMILIA := SuenoFamilias.FRAGMENTADA


static func adaptar_espacio(espacio: Dictionary) -> Dictionary:
	if espacio.is_empty():
		return {}

	var resultado := espacio.duplicate(true)
	var familia := SuenoFamilias.de(FAMILIA)
	resultado["identidad_onirica"] = ID
	resultado["sueno_sin_lecturas"] = true
	resultado["figuras"] = []
	resultado["carteles"] = []
	resultado["decals"] = []
	resultado["ambiente"] = Color(0.075, 0.085, 0.09)
	resultado["ambiente_energia"] = 0.24
	resultado["sol"] = 0.0

	if familia.is_empty():
		return resultado

	resultado["contorno"] = familia["contorno"]
	resultado["altura_contorno"] = float(familia.get("altura", 3.0))
	resultado["tabiques_poligonales"] = familia.get("tabiques", []).duplicate(true)
	resultado["entrada"] = Vector3(familia.get("entrada", Vector3(-10, 0, -10)))

	var anclas: Array = familia.get("anclas", []).duplicate(true)
	var salida_pos := Vector3(8.0, 0.0, 8.0)
	if not anclas.is_empty():
		salida_pos = Vector3(anclas[anclas.size() - 1])
	var salidas: Array = resultado.get("salidas", []).duplicate(true)
	if not salidas.is_empty():
		var salida: Dictionary = salidas[0].duplicate(true)
		salida["pos"] = salida_pos + Vector3(0, 1.1, 0)
		salidas[0] = salida
	resultado["salidas"] = salidas
	return resultado
