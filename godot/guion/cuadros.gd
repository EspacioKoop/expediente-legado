## Contrato declarativo para láminas murales (#195).
##
## Esta capa no conoce salas concretas ni carga assets. Solo normaliza la
## declaración de un cuadro y decide si puede usar una textura o debe conservar
## un relleno neutro. La integración 3D puede consumir este resultado sin
## acoplarse a nombres de fichero ni romper la escena cuando falte un recurso.
class_name Cuadros
extends RefCounted

const COLOR_FALLBACK := Color(0.34, 0.30, 0.25)
const TAM_MINIMO := Vector2(0.2, 0.2)


static func normalizar(declaracion: Dictionary) -> Dictionary:
	var tam := declaracion.get("tam", Vector2(1.0, 0.7)) as Vector2
	tam.x = maxf(tam.x, TAM_MINIMO.x)
	tam.y = maxf(tam.y, TAM_MINIMO.y)

	return {
		"pos": declaracion.get("pos", Vector3.ZERO),
		"tam": tam,
		"giro": float(declaracion.get("giro", 0.0)),
		"textura": String(declaracion.get("textura", "")).strip_edges(),
		"color_fallback": declaracion.get("color_fallback", COLOR_FALLBACK),
	}


static func ruta_textura(declaracion: Dictionary) -> String:
	var nombre := String(normalizar(declaracion)["textura"])
	if nombre.is_empty():
		return ""
	return "res://assets/texturas/%s" % nombre


static func tiene_textura(declaracion: Dictionary) -> bool:
	var ruta := ruta_textura(declaracion)
	return not ruta.is_empty() and ResourceLoader.exists(ruta)


static func materializar(declaracion: Dictionary) -> Dictionary:
	var cuadro := normalizar(declaracion)
	cuadro["ruta_textura"] = ruta_textura(cuadro)
	cuadro["usar_textura"] = tiene_textura(cuadro)
	return cuadro
