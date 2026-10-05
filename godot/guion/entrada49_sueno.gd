## Eco onírico de La Entrada 49 (#2477).
##
## Deforma solamente la presentación de la primera sala de una noche a partir
## de una decisión ya persistida. No cambia selección, salidas, duración ni
## añade hechos nuevos.
class_name Entrada49Sueno
extends RefCounted

const CLAVE_ESTADO := "entrada49"


static func aplicar(espacio: Dictionary, estado: Dictionary, indice_sala: int) -> Dictionary:
	var salida := espacio.duplicate(true)
	if indice_sala != 0:
		return salida
	var resolucion_bruta: Variant = estado.get(CLAVE_ESTADO, {})
	if not resolucion_bruta is Dictionary:
		return salida
	var resolucion := resolucion_bruta as Dictionary
	var eco_bruto: Variant = resolucion.get("eco_onirico", {})
	if not eco_bruto is Dictionary:
		return salida
	var eco := eco_bruto as Dictionary
	var motivo := String(eco.get("motivo", ""))
	if motivo.is_empty():
		return salida

	salida["entrada49_eco"] = {
		"motivo": motivo,
		"decision": String(resolucion.get("decision", "")),
		"afirmacion_metafisica": false,
	}
	var entrada: Vector3 = salida.get("entrada", Vector3.ZERO)
	var carteles: Array = salida.get("carteles", []).duplicate(true)
	var luces: Array = salida.get("luces", []).duplicate(true)

	match motivo:
		"archivo_sellado":
			carteles.append(_cartel("EXPEDIENTE AISLADO · 49", entrada + Vector3(2.2, 1.5, -1.8)))
		"puesto_vacio_ocupado":
			var figuras: Array = salida.get("figuras", []).duplicate(true)
			figuras.append(
				{
					"pos": entrada + Vector3(2.4, 0.0, 2.2),
					"color": Color(0.08, 0.08, 0.09, 0.82),
					"rotulo": "",
					"color_rotulo": Color(0.55, 0.55, 0.57),
					"duelo": "",
					"ataques": [],
					"movimiento_idle": false,
					"fase_idle": 0.0,
					"mirar_jugador": true,
				}
			)
			salida["figuras"] = figuras
		"tablilla_reescrita":
			carteles.append(
				_cartel("48 nombres. 49 líneas. 48 nombres.", entrada + Vector3(-2.0, 1.4, 1.7))
			)
		"sala_de_tablillas":
			for i in range(4):
				carteles.append(
					_cartel(
						"RACIÓN %02d / 49" % [46 + i],
						entrada + Vector3(-2.4 + float(i) * 1.5, 1.35, 2.0),
					)
				)
			luces.append(
				{
					"pos": entrada + Vector3(0.0, 1.8, 2.4),
					"color": Color(0.78, 0.58, 0.30),
					"energia": 0.75,
					"alcance": 4.0,
					"carcasa": false,
				}
			)
		_:
			return salida

	salida["carteles"] = carteles
	salida["luces"] = luces
	return salida


static func _cartel(texto: String, pos: Vector3) -> Dictionary:
	return {
		"texto": texto,
		"pos": pos,
		"giro": 0.0,
		"color": Color(0.82, 0.76, 0.62),
	}
