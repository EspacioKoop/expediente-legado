## Presentación diegética de la memoria nocturna (#162).
##
## Recibe un espacio ya construido y el análisis puro de MemoriaNocturna.
## Solo modifica luz y ambiente: no cambia planta, colisión, salidas, contenido
## documental ni progreso.
class_name MemoriaNocturnaPresentacion
extends RefCounted

const COLOR_MEMORIA := Color(0.42, 0.50, 0.72)
const COLOR_RELACION := Color(0.62, 0.46, 0.76)
const ENERGIA_BASE := 0.42
const ENERGIA_REPETIDA_DELTA := 0.28
const ALCANCE_BASE := 2.4
const ALCANCE_REPETIDO_DELTA := 0.55
const AMBIENTE_RELACION_DELTA := 0.05
const DESPLAZAMIENTOS := [
	Vector3(-0.9, 1.6, 0.7),
	Vector3(0.0, 1.8, 1.0),
	Vector3(0.9, 1.6, 0.7),
]


static func aplicar(espacio: Dictionary, seleccion: Array, analisis: Dictionary) -> Dictionary:
	var resultado := espacio.duplicate(true)
	var folios := _folios_validos(seleccion)
	if folios.is_empty():
		return resultado

	var luces: Array = resultado.get("luces", []).duplicate(true)
	var entrada: Vector3 = resultado.get("entrada", Vector3.ZERO)
	var repeticiones := _repeticiones_por_folio(analisis)
	var relacionados := _folios_relacionados(analisis)
	for i in folios.size():
		var folio := String(folios[i])
		var veces := maxi(1, int(repeticiones.get(folio, 1)))
		var relacionado := relacionados.has(folio)
		luces.append(
			{
				"pos": entrada + DESPLAZAMIENTOS[i],
				"color": COLOR_RELACION if relacionado else COLOR_MEMORIA,
				"energia": ENERGIA_BASE + float(veces - 1) * ENERGIA_REPETIDA_DELTA,
				"alcance": ALCANCE_BASE + float(veces - 1) * ALCANCE_REPETIDO_DELTA,
				"carcasa": false,
			}
		)
	resultado["luces"] = luces

	var relaciones: Array = analisis.get("relaciones", [])
	if not relaciones.is_empty():
		resultado["ambiente_energia"] = clampf(
			(
				float(resultado.get("ambiente_energia", 0.32))
				+ AMBIENTE_RELACION_DELTA * mini(relaciones.size(), 2)
			),
			0.05,
			1.5,
		)

	resultado["memoria_nocturna_visual"] = {
		"huecos": folios.size(),
		"intensidad_maxima": int(analisis.get("intensidad_maxima", 1)),
		"relaciones": relaciones.size(),
	}
	return resultado


static func _folios_validos(seleccion: Array) -> Array:
	var resultado := []
	for valor in seleccion:
		if typeof(valor) != TYPE_STRING:
			continue
		var folio := String(valor)
		if folio.is_empty():
			continue
		resultado.append(folio)
		if resultado.size() == SeleccionNocturna.MAX_DOCUMENTOS:
			break
	return resultado


static func _repeticiones_por_folio(analisis: Dictionary) -> Dictionary:
	var resultado := {}
	for valor in analisis.get("repeticiones", []):
		if not valor is Dictionary:
			continue
		var repeticion := valor as Dictionary
		var folio := String(repeticion.get("folio", ""))
		if not folio.is_empty():
			resultado[folio] = maxi(1, int(repeticion.get("veces", 1)))
	return resultado


static func _folios_relacionados(analisis: Dictionary) -> Dictionary:
	var resultado := {}
	for valor in analisis.get("relaciones", []):
		if not valor is Dictionary:
			continue
		for folio_valor in (valor as Dictionary).get("folios", []):
			var folio := String(folio_valor)
			if not folio.is_empty():
				resultado[folio] = true
	return resultado
