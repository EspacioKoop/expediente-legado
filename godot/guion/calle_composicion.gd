## Recomposición visual del trayecto para #277.
##
## No cambia reglas de fase ni contenido de las pantallas. Toma la calle ya
## declarada y concentra sus seis aparatos en un único escaparate reconocible.
class_name CalleComposicion
extends RefCounted

const COLOR_MARCO := Color(0.18, 0.17, 0.16)
const COLOR_FONDO := Color(0.24, 0.22, 0.20)


static func aplicar(calle: Dictionary) -> Dictionary:
	var resultado := calle.duplicate(true)
	var pantallas: Array = resultado.get("pantallas", [])
	if pantallas.size() != 6:
		return resultado

	var z_columnas := [-7.2, -5.8, -4.4]
	for i in pantallas.size():
		var fila := i / 3
		var columna := i % 3
		pantallas[i]["pos"] = Vector3(-2.56, 1.25 + fila * 0.92, z_columnas[columna])
		pantallas[i]["giro"] = 90.0
	resultado["pantallas"] = pantallas

	var bultos: Array = resultado.get("bultos", []).duplicate(true)
	bultos.append_array(_marco_escaparate())
	resultado["bultos"] = bultos
	return resultado


static func _marco_escaparate() -> Array:
	return [
		{
			"pos": Vector3(-2.72, 1.70, -5.80),
			"tam": Vector3(0.28, 2.45, 4.55),
			"color": COLOR_FONDO,
		},
		{
			"pos": Vector3(-2.48, 0.47, -5.80),
			"tam": Vector3(0.48, 0.18, 4.75),
			"color": COLOR_MARCO,
		},
		{
			"pos": Vector3(-2.48, 2.93, -5.80),
			"tam": Vector3(0.48, 0.18, 4.75),
			"color": COLOR_MARCO,
		},
		{
			"pos": Vector3(-2.48, 1.70, -8.18),
			"tam": Vector3(0.48, 2.62, 0.16),
			"color": COLOR_MARCO,
		},
		{
			"pos": Vector3(-2.48, 1.70, -3.42),
			"tam": Vector3(0.48, 2.62, 0.16),
			"color": COLOR_MARCO,
		},
	]
