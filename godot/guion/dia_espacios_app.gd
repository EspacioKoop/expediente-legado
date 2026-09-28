## Constructor de espacios base del día (#1761).
##
## DiaApp conserva el hook _espacio_de para toda la cadena de herencia, pero el
## montaje de catálogo y el reparto onírico viven aquí. No decide transiciones:
## recibe Jornada/Partida ya vigentes y devuelve el espacio junto a los rivales
## que la escena onírica hace combatibles.
class_name DiaEspaciosApp
extends RefCounted


static func construir(
	fase: String,
	jornada: Dictionary,
	estado: Dictionary,
	casos: Array,
	raiz: int,
	opciones_sueno: Callable,
	registro_literario: Callable,
) -> Dictionary:
	if fase != "sueño":
		var sitio := EspaciosCatalogo.de_fase(fase).duplicate(true)
		sitio["figuras"] = plantilla_en(sitio, jornada)
		return {"espacio": sitio}

	var opciones := SeleccionNocturna.opciones_sueno(jornada, opciones_sueno.call())
	var cantidad := clampi(
		int(opciones.get("cantidad", Sueno.ESCENAS_POR_NOCHE)), 1, SuenoFormas.ids().size()
	)
	if jornada["sueno_escenas"].is_empty():
		jornada["sueno_escenas"] = Sueno.noche(
			jornada["dia"],
			jornada["leido_hoy"],
			jornada["mapa"],
			raiz,
			opciones,
		)

	var id: String = jornada["sueno_escenas"][0]
	if bool(opciones.get("recordar_mapa", true)):
		Sueno.recordar(jornada["mapa"], id)

	var fuentes := (
		SuenoContenido
		. fuentes(
			jornada["leido_hoy"],
			casos,
			estado["pistas_descubiertas"],
			estado.get("veredictos", {}),
			SuenoCombate.vencidos(estado),
		)
	)
	var semilla_noche := Sueno.semilla(
		jornada["dia"],
		jornada["leido_hoy"],
		raiz,
		opciones.get("seleccion_nocturna", []),
	)
	var reparto := SuenoContenido.repartir(fuentes, cantidad, semilla_noche)
	var cual: int = cantidad - jornada["sueno_escenas"].size()
	var trozo: Dictionary = reparto[clampi(cual, 0, reparto.size() - 1)]

	var forma_actual := SuenoFormas.de(id)
	if String(forma_actual.get("identidad_onirica", "")) == SuenoCastillo.ID:
		var estado_castillo: Dictionary = trozo.get("estado_presentacion", {}).duplicate(true)
		estado_castillo["vuelta_castillo"] = cual + 1
		estado_castillo["semilla_castillo"] = semilla_noche
		trozo["estado_presentacion"] = estado_castillo

	var rivales: Dictionary = {}
	for quien in trozo["figuras"]:
		if SuenoCombate.se_pelea(quien, estado):
			rivales[quien["id"]] = quien

	var espacio_sueno := Sueno.espacio(id, jornada["sueno_escenas"].size() - 1, trozo)
	var espacio := SuenoLiteratura.aplicar(espacio_sueno, registro_literario.call(), cual)
	return {"espacio": espacio, "rivales": rivales}


static func plantilla_en(sitio: Dictionary, jornada: Dictionary) -> Array:
	var sitios: Array = sitio.get("sitios_companeros", [])
	if sitios.is_empty():
		return []
	var figuras := []
	var quienes := Companeros.plantilla(jornada["plantilla"])
	for i in mini(quienes.size(), sitios.size()):
		var quien: Dictionary = quienes[i]
		figuras.append(
			{
				"pos": sitios[i],
				"id_companero": String(quien.get("id", "")),
				"color": quien["color"],
				"rotulo": tr(quien["nombre"]),
				"frase": Companeros.frase_de(quien, jornada["dia"]),
				"modelo": Companeros.cuerpo_de(quien),
				"retrato": quien.get("retrato", ""),
			}
		)
	return figuras
