## Dressing reactivo para las salas compuestas del sueño (#400 / #149 / #87).
##
## No modifica Sueno/SuenoFormas: lee la forma que ya se eligió y coloca tres
## objetos familiares únicamente sobre celdas transitables. Uno queda delante de
## la entrada y los otros se reparten lejos entre sí, evitando también la salida.
## Cada prescripción enlaza además con un ID estable de CatalogoAnomalias.
##
## Las cartas de tarot son una excepción importante: solo pueden entrar en el
## sueño cuando su folio fue leído HOY y la carta ya fue recogida. Leer el folio
## sin haber pulsado la frase oculta no autoriza al sueño a revelar la carta.
class_name SuenoUtileria
extends RefCounted

const PRESCRIPCIONES := [
	{
		"anomalia_id": "silla-demasiado-alta",
		"modelo": "chairDesk",
		"tam": Vector3(0.62, 0.95, 0.62),
		"color": Color(0.30, 0.31, 0.38),
		"nombre": "silla demasiado alta",
		"escala": Vector3(1.15, 2.35, 0.72),
		"reaccion": Vector3(0.72, 1.35, 1.85),
		"giro": Vector3(0.0, 18.0, -7.0),
		"giro_reaccion": Vector3(0.0, 112.0, 8.0),
	},
	{
		"anomalia_id": "monitor-estirado",
		"modelo": "computerScreen",
		"tam": Vector3(0.50, 0.45, 0.40),
		"color": Color(0.48, 0.55, 0.52),
		"nombre": "monitor estirado",
		"escala": Vector3(2.30, 0.72, 1.08),
		"reaccion": Vector3(0.88, 1.95, 1.30),
		"giro": Vector3(-6.0, -24.0, -10.0),
		"giro_reaccion": Vector3(9.0, 42.0, 13.0),
	},
	{
		"anomalia_id": "archivador-torcido",
		"modelo": "bookcaseClosed",
		"tam": Vector3(1.0, 1.8, 0.6),
		"color": Color(0.34, 0.31, 0.38),
		"nombre": "archivador torcido",
		"escala": Vector3(0.58, 1.55, 1.42),
		"reaccion": Vector3(1.42, 0.72, 0.74),
		"giro": Vector3(0.0, 14.0, 6.0),
		"giro_reaccion": Vector3(0.0, -76.0, -9.0),
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
}


static func montar(
	mundo: Node3D,
	id: String,
	dia: int,
	raiz_azar: int,
	documentos_origen: Array = [],
	cartas_recogidas: Array = [],
) -> Array:
	var forma := SuenoFormas.de(id)
	var bloques: Array = forma["bloques"]
	var entrada: Vector2i = forma["entrada"]
	var salida := Planta.mas_lejana(bloques, entrada)
	var primera := Planta.a_la_vista(bloques, entrada, 3)
	var celdas := [primera]
	celdas.append_array(Planta.repartidas(bloques, 2, [entrada, primera, salida]))

	# Mismo día + misma semilla = misma distribución. Cambiar de noche rota qué
	# objeto se encuentra primero sin introducir un sorteo imposible de reproducir.
	var semilla := Azar.derivar_texto(raiz_azar, "sueno", "utileria:%s" % id, [dia])
	var desplazamiento := posmod(semilla, PRESCRIPCIONES.size())
	var folios := _folios_validos(documentos_origen)
	var plan := _plan_deformaciones(folios, cartas_recogidas, desplazamiento)
	var creadas := []
	for i in range(plan.size()):
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
		# Una variante solo puede proceder de un folio que ya estaba en
		# `leido_hoy`. Con la misma entrada la asociación es reproducible.
		var folio := String(paso.get("folio", ""))
		if not folio.is_empty():
			anomalia.set_meta("documento_origen", folio)
		var carta := String(paso.get("carta", ""))
		if not carta.is_empty():
			anomalia.set_meta("carta_origen", carta)
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
			)
		)
		creadas.append(anomalia)
	return creadas


static func _plan_deformaciones(
	folios: Array, cartas_recogidas: Array, desplazamiento: int
) -> Array:
	var plan := []
	var tarot := _tarot_del_dia(folios, cartas_recogidas)
	if not tarot.is_empty():
		var elegida: Dictionary = tarot[posmod(desplazamiento, tarot.size())]
		plan.append(
			{
				"datos": PRESCRIPCION_TAROT,
				"folio": elegida["folio"],
				"carta": elegida["carta"],
			}
		)

	var faltan := 3 - plan.size()
	for i in range(faltan):
		var paso := {"datos": PRESCRIPCIONES[(i + desplazamiento) % PRESCRIPCIONES.size()]}
		if not folios.is_empty():
			paso["folio"] = folios[(i + desplazamiento) % folios.size()]
		plan.append(paso)
	return plan


## Devuelve únicamente cartas que el jugador puede reconocer legítimamente esta
## noche: su documento fue leído hoy y el estado persistente confirma que la
## carta ya fue recogida. Así el sueño recuerda; nunca adelanta una pista.
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


static func _folios_validos(documentos_origen: Array) -> Array:
	var folios := []
	for valor in documentos_origen:
		var folio := String(valor).strip_edges()
		if not folio.is_empty() and not folios.has(folio):
			folios.append(folio)
	return folios
