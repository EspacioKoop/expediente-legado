## Cuánta ayuda presta el gato fuera de casa (#92).
##
## No guarda afecto ni inventa otro contador: las tres superficies leen el mismo
## estado persistente que ya usa la casa. La conducta doméstica sigue siendo la
## señal principal; SIGA y el sueño solo traducen esa señal a presencia/ausencia.
class_name GatoAyuda
extends RefCounted

const COMPLETA := "completa"
const ESCASA := "escasa"
const AUSENTE := "ausente"

## Primer corte del catálogo contextual histórico (#455). Son IDs semánticos,
## no texto visible: la capa de presentación podrá traducirlos después sin
## convertir esta política en una segunda fuente de estado o de contenido.
const CONTEXTO_EXPLORAR := "explorar_expediente"
const CONTEXTO_LISTO := "listo_para_imputar"
const CONTEXTO_CERRADO := "expediente_cerrado"
const CONTEXTO_DESCUBRIMIENTO := "descubrimiento"
const CONTEXTO_COMBINACION_FALLIDA := "combinacion_fallida"
const CONTEXTO_COMBINACION_REPETIDA := "combinacion_repetida"

const EVENTO_A_CONTEXTO := {
	"descubrimiento": CONTEXTO_DESCUBRIMIENTO,
	"combinacion_fallida": CONTEXTO_COMBINACION_FALLIDA,
	"combinacion_repetida": CONTEXTO_COMBINACION_REPETIDA,
}


static func nivel(gato: Dictionary) -> String:
	if not bool(gato.get("presente", false)):
		return AUSENTE
	if int(gato.get("dias_sin_comer", 0)) > GatoConducta.DIAS_PARA_DESCONFIAR:
		return ESCASA
	return COMPLETA


## Selecciona un contexto SIGA a partir de datos ya resueltos por la pantalla.
##
## Un evento real y reciente tiene prioridad porque explica qué acaba de pasar.
## Si no hay evento, el estado del expediente decide entre cerrado/listo/explorar.
## No guarda nada: el siguiente evento o refresco vuelve a derivar el contexto.
static func contexto_siga(estado: Dictionary = {}, evento: String = "") -> String:
	if EVENTO_A_CONTEXTO.has(evento):
		return String(EVENTO_A_CONTEXTO[evento])
	if bool(estado.get("cerrado", false)):
		return CONTEXTO_CERRADO
	if bool(estado.get("listo_para_imputar", false)):
		return CONTEXTO_LISTO
	return CONTEXTO_EXPLORAR


## Claves reservadas para el comentario accesorio del gato. Todavía no se
## renderizan en #455: el primer corte fija el contrato y el wiring posterior
## añadirá traducciones + señal explícita desde el visor.
static func comentario_contextual(contexto: String) -> String:
	match contexto:
		CONTEXTO_EXPLORAR:
			return "GATO_SIGA_EXPLORAR"
		CONTEXTO_LISTO:
			return "GATO_SIGA_LISTO"
		CONTEXTO_CERRADO:
			return "GATO_SIGA_CERRADO"
		CONTEXTO_DESCUBRIMIENTO:
			return "GATO_SIGA_DESCUBRIMIENTO"
		CONTEXTO_COMBINACION_FALLIDA:
			return "GATO_SIGA_COMBINACION_FALLIDA"
		CONTEXTO_COMBINACION_REPETIDA:
			return "GATO_SIGA_COMBINACION_REPETIDA"
		_:
			return ""


## El asistente nunca miente sobre una regla necesaria para jugar. Con el gato
## bien cuidado añade una observación institucional dudosa; con hambre se limita
## a la instrucción que ya existe en el visor. Sin gato no aparece asistente.
##
## Sin contexto conserva exactamente el contrato ya integrado por #266. Cuando
## el visor empiece a pasar uno, solo COMPLETA añade el comentario accesorio:
## ESCASA conserva la instrucción cierta y AUSENTE sigue en silencio.
static func lineas_asistente(gato: Dictionary, contexto: String = "") -> Array:
	if contexto.is_empty():
		match nivel(gato):
			COMPLETA:
				return ["VISOR_ELIJA", "ENTRADA_VOZ_SOLO"]
			ESCASA:
				return ["VISOR_ELIJA"]
			_:
				return []

	match nivel(gato):
		COMPLETA:
			var lineas := ["VISOR_ELIJA"]
			var comentario := comentario_contextual(contexto)
			if not comentario.is_empty():
				lineas.append(comentario)
			return lineas
		ESCASA:
			return ["VISOR_ELIJA"]
		_:
			return []


static func guia_visible(gato: Dictionary) -> bool:
	return nivel(gato) != AUSENTE


## Alimentado orienta. Hambriento todavía aparece —es el mismo gato—, pero deja
## de hacer de brújula. La pérdida de ayuda se ve sin barra ni aviso de sistema.
static func guia_orienta(gato: Dictionary) -> bool:
	return nivel(gato) == COMPLETA
