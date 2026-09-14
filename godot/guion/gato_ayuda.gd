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


static func nivel(gato: Dictionary) -> String:
	if not bool(gato.get("presente", false)):
		return AUSENTE
	if int(gato.get("dias_sin_comer", 0)) > GatoConducta.DIAS_PARA_DESCONFIAR:
		return ESCASA
	return COMPLETA


## El asistente nunca miente sobre una regla necesaria para jugar. Con el gato
## bien cuidado añade una observación institucional dudosa; con hambre se limita
## a la instrucción que ya existe en el visor. Sin gato no aparece asistente.
static func lineas_asistente(gato: Dictionary) -> Array:
	match nivel(gato):
		COMPLETA:
			return ["VISOR_ELIJA", "ENTRADA_VOZ_SOLO"]
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
