## Dónde están las frases marcadas dentro del texto de un documento.
##
## Reemplaza a tres servicios del backend Java que hacían lo mismo por
## separado y encadenados: [code]HotspotService[/code] (la frase gatillo de una
## pista), [code]CartaOcultaService[/code] (la frase que esconde una carta de
## tarot) y [code]WikiLinkService[/code] (las referencias [[Concepto]] del
## corcho). Los tres buscaban una frase y la envolvían en HTML, cada uno sobre
## la salida del anterior — así que una frase que cayera dentro del marcado ya
## generado por otro lo partía por la mitad.
##
## Aquí no se genera marcado: se devuelven SEGMENTOS. Quién los pinta (BBCode
## para un RichTextLabel) es otro módulo, y así el solapamiento se decide una
## sola vez, explícitamente, en vez de depender del orden de las pasadas.
class_name Marcas
extends RefCounted

## Referencia a un concepto del corcho: [[Nombre]].
const REFERENCIA := "\\[\\[([^\\[\\]]+)\\]\\]"


## Localiza la PRIMERA aparición de una frase, como hacía el indexOf de Java.
## Devuelve un hallazgo, o un diccionario vacío si la frase no está.
static func frase(texto: String, buscada: String, tipo: String, meta: Dictionary) -> Dictionary:
	if buscada.strip_edges().is_empty():
		return {}
	var inicio := texto.find(buscada)
	if inicio < 0:
		return {}
	return {
		"inicio": inicio,
		"fin": inicio + buscada.length(),
		"texto": buscada,
		"tipo": tipo,
		"meta": meta,
	}


## Todas las referencias [[Concepto]] del texto, en orden de aparición.
## [param desbloqueados] son los nombres que el jugador ya ha descubierto: una
## referencia a un concepto que aún no tiene se marca igual, pero como
## pendiente — el nombre se lee, y no lleva a ninguna parte.
static func referencias(texto: String, desbloqueados: Array) -> Array:
	var expresion := RegEx.new()
	expresion.compile(REFERENCIA)
	var hallazgos := []
	for coincidencia in expresion.search_all(texto):
		var nombre: String = coincidencia.get_string(1)
		(
			hallazgos
			. append(
				{
					"inicio": coincidencia.get_start(),
					"fin": coincidencia.get_end(),
					# Los corchetes desaparecen: lo que se lee es el nombre.
					"texto": nombre,
					"tipo": "concepto" if desbloqueados.has(nombre) else "concepto_pendiente",
					"meta": {"nombre": nombre},
				}
			)
		)
	return hallazgos


## Parte el texto en segmentos alternos de texto plano y texto marcado.
##
## Un hallazgo que se solape con otro ya colocado se DESCARTA, y el que gana es
## el que empieza antes (a igual inicio, el que se declaró primero). Es la
## decisión que el encadenado de Java tomaba sin saberlo, según qué servicio
## corriera antes.
static func segmentar(texto: String, hallazgos: Array) -> Array:
	var ordenados := hallazgos.filter(func(h): return not h.is_empty())
	ordenados.sort_custom(func(a, b): return a["inicio"] < b["inicio"])

	var segmentos := []
	var cursor := 0
	for hallazgo in ordenados:
		if hallazgo["inicio"] < cursor:
			continue  # solapa con uno ya colocado
		if hallazgo["inicio"] > cursor:
			(
				segmentos
				. append(
					{
						"texto": texto.substr(cursor, hallazgo["inicio"] - cursor),
						"tipo": "",
						"meta": {},
					}
				)
			)
		(
			segmentos
			. append(
				{
					"texto": hallazgo["texto"],
					"tipo": hallazgo["tipo"],
					"meta": hallazgo["meta"],
				}
			)
		)
		cursor = hallazgo["fin"]

	if cursor < texto.length():
		segmentos.append({"texto": texto.substr(cursor), "tipo": "", "meta": {}})
	return segmentos


## Los segmentos de un registro del expediente: su frase gatillo (si la pista
## no está descubierta todavía, es pulsable; si lo está, queda como leída) y la
## carta de tarot escondida en él, si la hay.
static func de_registro(registro: Dictionary, pistas: Array, descubiertas: Array) -> Array:
	var contenido: String = (
		registro.get("contenido", "") if registro.get("contenido") != null else ""
	)
	var hallazgos := []

	for pista in pistas:
		var gatillo = pista.get("fraseGatillo")
		if gatillo == null:
			continue
		var descubierta: bool = descubiertas.has(pista.get("id"))
		hallazgos.append(
			frase(
				contenido,
				gatillo,
				"pista_vista" if descubierta else "pista",
				{"pista": pista.get("id")}
			)
		)

	var carta := CartasOcultas.en_folio(registro.get("folio", ""))
	if not carta.is_empty():
		hallazgos.append(frase(contenido, carta["frase"], "carta", {"carta": carta["carta"]}))

	return segmentar(contenido, hallazgos)
