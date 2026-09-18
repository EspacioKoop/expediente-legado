## Trabajillos de casa (#94).
##
## No son otra profesión ni otra economía: un lote pequeño, una vez por noche,
## que compra algo de margen a cambio de descanso. La oferta rota de forma
## determinista entre tareas igual de mal pagadas y trabajar noches consecutivas
## degrada todavía más el sueño, sin tocar acciones del archivo ni pistas.
class_name Trabajillos
extends RefCounted

const PAGO_TRABAJILLO := 20
const ESCENAS_SUENO_PERDIDAS := 1
const ESCENAS_SUENO_PERDIDAS_RACHA := 2

const TIPOS := [
	{
		"id": "transcripcion",
		"rotulo": "TRABAJILLO_TRANSCRIPCION",
		"cobrado": "TRABAJILLO_COBRADO_TRANSCRIPCION",
	},
	{
		"id": "sobres",
		"rotulo": "TRABAJILLO_SOBRES",
		"cobrado": "TRABAJILLO_COBRADO_SOBRES",
	},
	{
		"id": "encuestas",
		"rotulo": "TRABAJILLO_ENCUESTAS",
		"cobrado": "TRABAJILLO_COBRADO_ENCUESTAS",
	},
]


static func _estado(jornada: Dictionary) -> Dictionary:
	if not jornada.has("trabajillos") or typeof(jornada["trabajillos"]) != TYPE_DICTIONARY:
		jornada["trabajillos"] = {
			"ultimo_dia": 0,
			"hechos": 0,
			"racha": 0,
			"racha_maxima": 0,
			"ultimo_tipo": "",
			"por_tipo": {},
		}
	var estado: Dictionary = jornada["trabajillos"]
	estado["ultimo_dia"] = int(estado.get("ultimo_dia", 0))
	estado["hechos"] = int(estado.get("hechos", 0))
	estado["racha"] = int(estado.get("racha", 0))
	estado["racha_maxima"] = int(estado.get("racha_maxima", estado["racha"]))
	estado["ultimo_tipo"] = String(estado.get("ultimo_tipo", ""))
	if not estado.has("por_tipo") or typeof(estado["por_tipo"]) != TYPE_DICTIONARY:
		estado["por_tipo"] = {}
	return estado


## La oferta cambia con día y vida laboral, pero nunca con azar global. Guardar,
## recargar o repetir la misma semilla conserva exactamente el mismo trabajillo.
static func oferta_del_dia(jornada: Dictionary) -> Dictionary:
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var vuelta := maxi(1, int(jornada.get("vuelta", 1)))
	var indice := (dia + vuelta - 2) % TIPOS.size()
	return TIPOS[indice].duplicate(true)


static func disponible(jornada: Dictionary) -> bool:
	if jornada.get("fase", "") != "casa":
		return false
	return int(_estado(jornada)["ultimo_dia"]) != int(jornada.get("dia", 1))


static func hacer(jornada: Dictionary) -> Dictionary:
	if not disponible(jornada):
		return {}
	var estado := _estado(jornada)
	var dia := int(jornada.get("dia", 1))
	var oferta := oferta_del_dia(jornada)
	var ultimo_dia := int(estado["ultimo_dia"])
	if ultimo_dia == dia - 1:
		estado["racha"] = int(estado["racha"]) + 1
	else:
		estado["racha"] = 1
	estado["racha_maxima"] = maxi(int(estado["racha_maxima"]), int(estado["racha"]))
	estado["ultimo_dia"] = dia
	estado["hechos"] += 1
	estado["ultimo_tipo"] = String(oferta["id"])

	var por_tipo: Dictionary = estado["por_tipo"]
	var tipo := String(oferta["id"])
	por_tipo[tipo] = int(por_tipo.get(tipo, 0)) + 1

	jornada["dinero"] = int(jornada.get("dinero", 0)) + PAGO_TRABAJILLO
	return {
		"dia": dia,
		"tipo": tipo,
		"rotulo": oferta["rotulo"],
		"cobrado": oferta["cobrado"],
		"importe": PAGO_TRABAJILLO,
		"dinero": jornada["dinero"],
		"hechos": estado["hechos"],
		"racha": estado["racha"],
		"racha_maxima": estado["racha_maxima"],
	}


static func hecho_hoy(jornada: Dictionary) -> bool:
	return int(_estado(jornada)["ultimo_dia"]) == int(jornada.get("dia", 1))


static func escenas_de_sueno(jornada: Dictionary, cantidad_normal: int) -> int:
	if not hecho_hoy(jornada):
		return cantidad_normal
	var perdidas := ESCENAS_SUENO_PERDIDAS
	if int(_estado(jornada)["racha"]) >= 2:
		perdidas = ESCENAS_SUENO_PERDIDAS_RACHA
	return maxi(1, cantidad_normal - perdidas)
