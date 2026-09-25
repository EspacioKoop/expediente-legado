## Dressing reactivo para las salas compuestas del sueño (#400 / #149 / #87).
##
## No modifica Sueno/SuenoFormas: lee la forma que ya se eligió y coloca solo
## objetos familiares cuyo original se examinó deliberadamente durante este día.
## Una carta de tarot cuenta únicamente si su folio se leyó hoy y ya fue recogida;
## si no hay originales compatibles, la sala no inventa utilería.
## Cada prescripción enlaza además con un ID estable de CatalogoAnomalias.
##
## #888 añade una segunda lectura puramente visual: cada original puede proyectar
## un eco geométrico estático ligado a una familia de la gramática simbólica y,
## después, una rima espacial no colisionable que extiende ese mismo motivo al
## entorno cercano. Ninguna de las dos capas altera objetivos #281, navegación,
## progreso ni persistencia.
class_name SuenoUtileria
extends RefCounted

const PRESCRIPCIONES := [
	{
		"objeto_id": "silla",
		"anomalia_id": "silla-demasiado-alta",
		"modelo": "chairDesk",
		"tam": Vector3(0.62, 0.95, 0.62),
		"color": Color(0.30, 0.31, 0.38),
		"nombre": "silla demasiado alta",
		"escala": Vector3(1.15, 2.35, 0.72),
		"reaccion": Vector3(0.72, 1.35, 1.85),
		"giro": Vector3(0.0, 18.0, -7.0),
		"giro_reaccion": Vector3(0.0, 112.0, 8.0),
		"motivo_simbolico": "umbral",
	},
	{
		"objeto_id": "monitor",
		"anomalia_id": "monitor-estirado",
		"modelo": "computerScreen",
		"tam": Vector3(0.50, 0.45, 0.40),
		"color": Color(0.48, 0.55, 0.52),
		"nombre": "monitor estirado",
		"escala": Vector3(2.30, 0.72, 1.08),
		"reaccion": Vector3(0.88, 1.95, 1.30),
		"giro": Vector3(-6.0, -24.0, -10.0),
		"giro_reaccion": Vector3(9.0, 42.0, 13.0),
		"motivo_simbolico": "doble",
	},
	{
		"objeto_id": "archivador",
		"anomalia_id": "archivador-torcido",
		"modelo": "bookcaseClosed",
		"tam": Vector3(1.0, 1.8, 0.6),
		"color": Color(0.34, 0.31, 0.38),
		"nombre": "archivador torcido",
		"escala": Vector3(0.58, 1.55, 1.42),
		"reaccion": Vector3(1.42, 0.72, 0.74),
		"giro": Vector3(0.0, 14.0, 6.0),
		"giro_reaccion": Vector3(0.0, -76.0, -9.0),
		"motivo_simbolico": "laberinto",
	},
	{
		"objeto_id": "televisor_casa",
		"anomalia_id": "televisor-domestico-desfasado",
		"modelo": "televisionVintage",
		"tam": Vector3(0.85, 0.75, 0.60),
		"color": Color(0.38, 0.34, 0.30),
		"nombre": "televisor doméstico desfasado",
		"escala": Vector3(1.35, 0.82, 1.85),
		"reaccion": Vector3(0.76, 1.48, 0.92),
		"giro": Vector3(-4.0, 26.0, 9.0),
		"giro_reaccion": Vector3(12.0, 118.0, -8.0),
		"motivo_simbolico": "doble",
	},
	{
		"objeto_id": "armario_hogar",
		"anomalia_id": "armario-domestico-desencajado",
		"modelo": "household_goods/wardrobe_01",
		"tam": Vector3(0.99, 1.93, 0.63),
		"color": Color(0.34, 0.28, 0.23),
		"nombre": "armario doméstico desencajado",
		"escala": Vector3(0.62, 1.80, 1.45),
		"reaccion": Vector3(1.42, 0.78, 0.68),
		"giro": Vector3(0.0, 28.0, 8.0),
		"giro_reaccion": Vector3(0.0, -62.0, -11.0),
		"motivo_simbolico": "laberinto",
		"asset_cc0": true,
	},
]

const PRESCRIPCION_TAROT := {
	"anomalia_id": "tarot-geometria-viva",
	"modelo": "tarotCard",
	"tam": Vector3(0.42, 0.70, 0.035),
	"color": Color(0.52, 0.44, 0.67),
	"nombre": "carta de tarot deformada",
	"escala": Vector3(1.25, 1.85, 0.55),
	"reaccion": Vector3(0.72, 0.88, 4.80),
	"giro": Vector3(-5.0, 23.0, 7.0),
	"giro_reaccion": Vector3(18.0, 117.0, -13.0),
	"motivo_simbolico": "ciclo-centro",
}


static func montar(
	mundo: Node3D,
	id: String,
	dia: int,
	raiz_azar: int,
	documentos_origen: Array = [],
	objetos_tocados: Array = [],
	cartas_recogidas: Array = [],
) -> Array:
	var folios := _folios_validos(documentos_origen)
	var prescripciones := prescripciones_para(objetos_tocados)
	var tarot := _tarot_del_dia(folios, cartas_recogidas)
	if prescripciones.is_empty() and tarot.is_empty():
		return []

	var forma := SuenoFormas.de(id)
	var bloques: Array = forma["bloques"]
	var entrada: Vector2i = forma["entrada"]
	var salida := Planta.mas_lejana(bloques, entrada)

	var semilla := Azar.derivar_texto(raiz_azar, "sueno", "utileria:%s" % id, [dia])
	var desplazamiento := 0
	if not prescripciones.is_empty():
		desplazamiento = posmod(semilla, prescripciones.size())
	var plan := _plan_deformaciones(prescripciones, folios, tarot, desplazamiento, semilla)
	var cantidad := mini(plan.size(), 3)

	var primera := Planta.a_la_vista(bloques, entrada, 3)
	var celdas := [primera]
	if cantidad > 1:
		celdas.append_array(Planta.repartidas(bloques, cantidad - 1, [entrada, primera, salida]))

	var creadas := []
	for i in cantidad:
		var paso: Dictionary = plan[i]
		var datos: Dictionary = paso["datos"]
		var anomalia := AnomaliaSueno3D.new()
		anomalia.name = "AnomaliaSueno%d" % (i + 1)
		var tam: Vector3 = datos["tam"]
		var escala: Vector3 = datos["escala"]
		anomalia.position = (
			Planta.centro_en_metros(bloques, celdas[i])
			+ Vector3(0.0, tam.y * absf(escala.y) * 0.5, 0.0)
		)

		var objeto := String(paso.get("objeto", ""))
		if not objeto.is_empty():
			anomalia.set_meta("objeto_origen", objeto)
		var folio := String(paso.get("folio", ""))
		if not folio.is_empty():
			anomalia.set_meta("documento_origen", folio)
		var carta := String(paso.get("carta", ""))
		if not carta.is_empty():
			anomalia.set_meta("carta_origen", carta)
		var motivo := String(datos.get("motivo_simbolico", ""))
		if not motivo.is_empty():
			anomalia.set_meta("motivo_simbolico", motivo)

		mundo.add_child(anomalia)
		(
			anomalia
			. configurar(
				datos["anomalia_id"],
				datos["modelo"],
				tam,
				datos["color"],
				datos["nombre"],
				escala,
				datos["reaccion"],
				datos["giro"],
				datos["giro_reaccion"],
				datos.get("asset_cc0", false) == true,
			)
		)
		_montar_eco_simbolico(anomalia, motivo)
		creadas.append(anomalia)
	SuenoEspacioSimbolico.montar(mundo, creadas)
	return creadas


static func _montar_eco_simbolico(anomalia: AnomaliaSueno3D, motivo: String) -> void:
	if motivo.is_empty():
		return
	var original := anomalia.find_child("FormaDeformada", false, false) as Node3D
	if original == null:
		return
	var eco := original.duplicate() as Node3D
	if eco == null:
		return

	eco.name = "EcoSimbolico"
	eco.set_meta("motivo_simbolico", motivo)
	match motivo:
		"doble":
			eco.position = Vector3(0.32, 0.05, -0.22)
			eco.scale = original.scale * Vector3(0.82, 0.82, 0.82)
			eco.rotation_degrees = original.rotation_degrees + Vector3(0.0, -18.0, 0.0)
		"laberinto":
			eco.position = Vector3(0.38, 0.0, -0.30)
			eco.scale = original.scale * Vector3(0.72, 0.88, 0.72)
			eco.rotation_degrees = original.rotation_degrees + Vector3(0.0, 90.0, 0.0)
		"umbral":
			eco.position = Vector3(0.0, 0.0, -0.42)
			eco.scale = original.scale * Vector3(0.84, 0.84, 0.84)
			eco.rotation_degrees = original.rotation_degrees + Vector3(0.0, 8.0, 0.0)
		"ciclo-centro":
			eco.position = Vector3(0.0, 0.08, -0.12)
			eco.scale = original.scale * Vector3(0.62, 0.62, 0.62)
			eco.rotation_degrees = original.rotation_degrees + Vector3(0.0, 180.0, 0.0)
		_:
			return
	anomalia.add_child(eco)


static func _plan_deformaciones(
	prescripciones: Array,
	folios: Array,
	tarot: Array,
	desplazamiento: int,
	semilla: int,
) -> Array:
	var plan := []
	if not tarot.is_empty():
		var elegida: Dictionary = tarot[posmod(semilla, tarot.size())]
		var paso_tarot := {
			"datos": PRESCRIPCION_TAROT,
			"folio": elegida["folio"],
			"carta": elegida["carta"],
		}
		plan.append(paso_tarot)

	var huecos := 3 - plan.size()
	var cantidad_objetos := mini(prescripciones.size(), huecos)
	for i in cantidad_objetos:
		var indice := (i + desplazamiento) % prescripciones.size()
		var datos: Dictionary = prescripciones[indice]
		var paso := {"datos": datos, "objeto": datos["objeto_id"]}
		if not folios.is_empty():
			paso["folio"] = folios[indice % folios.size()]
		plan.append(paso)
	return plan


## Devuelve solo cartas que el jugador puede reconocer legítimamente esta noche:
## el folio fue leído hoy y el estado persistente confirma que ya se recogió.
static func _tarot_del_dia(folios: Array, cartas_recogidas: Array) -> Array:
	var resultado := []
	for folio in folios:
		var oculta := CartasOcultas.en_folio(folio)
		if oculta.is_empty():
			continue
		var carta := String(oculta.get("carta", "")).strip_edges()
		if carta.is_empty() or not cartas_recogidas.has(carta):
			continue
		resultado.append({"folio": folio, "carta": carta})
	return resultado


## Contrato puro usado también por la regresión: desconocidos, vacíos y
## duplicados no fabrican contenido; el catálogo decide la representación.
static func prescripciones_para(objetos_tocados: Array) -> Array:
	var ids := []
	for valor in objetos_tocados:
		var objeto_id := String(valor).strip_edges()
		if not objeto_id.is_empty() and not ids.has(objeto_id):
			ids.append(objeto_id)
	var elegidas := []
	for datos in PRESCRIPCIONES:
		if ids.has(datos["objeto_id"]):
			elegidas.append(datos)
	return elegidas


static func _folios_validos(documentos_origen: Array) -> Array:
	var folios := []
	for valor in documentos_origen:
		var folio := String(valor).strip_edges()
		if not folio.is_empty() and not folios.has(folio):
			folios.append(folio)
	return folios
