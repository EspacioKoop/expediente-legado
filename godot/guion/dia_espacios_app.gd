## DiaEspaciosApp: helper para resolver y construir el espacio base.
##
## Extrae la lógica común de resolución y construcción de espacios de DiaApp,
## sin conocer overrides de calle/sueño/clima/gato.
extends RefCounted


###
# Resolución del espacio base a partir de fase y jornada.
##
# [param fase] fase actual (archivo, trayecto, casa, sueño)
# [param jornada] estado de la jornada (Dictionary)
##
# [return] diccionario del espacio base (sin overrides)
static func resolver_espacio_base(fase: String, jornada: Dictionary) -> Dictionary:
	if fase != "sueño":
		var sitio := EspaciosCatalogo.de_fase(fase).duplicate(true)
		sitio["figuras"] = _plantilla_en(sitio, jornada)
		return sitio
	# Para sueño, devolvemos vacío: el overriden se maneja fuera.
	return {}


###
# Construcción del espacio en el mundo 3D.
##
# [param mundo] nodo Node3D donde construir el espacio
# [param espacio] diccionario del espacio (resultado de resolver_espacio_base)
##
# [return] Array de Area3D (salidas) resultantes de Espacio3D.construir
static func construir_espacio(mundo: Node3D, espacio: Dictionary) -> Array:
	return Espacio3D.construir(mundo, espacio)


###
# Plantilla de compañeros para el espacio base.
##
# [param sitio] diccionario del sitio (de EspaciosCatalogo)
# [param jornada] estado de la jornada (Dictionary)
##
# [return] Array de figuras para colocar en el sitio
static func _plantilla_en(sitio: Dictionary, jornada: Dictionary) -> Array:
	var sitios: Array = sitio.get("sitios_companeros", [])
	if sitios.is_empty():
		return []
	var figuras := []
	var quienes := Companeros.plantilla(jornada["plantilla"])
	for i in mini(quienes.size(), sitios.size()):
		var quien: Dictionary = quienes[i]
		(
			figuras
			. append(
				{
					"pos": sitios[i],
					"id_companero": String(quien.get("id", "")),
					"color": quien["color"],
					"rotulo":
					String(TranslationServer.translate(StringName(String(quien["nombre"])))),
					"frase": Companeros.frase_de(quien, jornada["dia"]),
					"modelo": Companeros.cuerpo_de(quien),
					"retrato": quien.get("retrato", ""),
				}
			)
		)
	return figuras
