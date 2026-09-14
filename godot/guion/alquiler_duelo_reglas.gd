## Regla del duelo ocasional al pagar el alquiler (#85).
##
## No cobra ni pinta nada: decide si este vencimiento trae objeción y resuelve
## el trámite después del Combate. La misma jornada y semilla producen siempre
## la misma respuesta, de modo que cerrar/reabrir la pantalla no vuelve a tirar.
class_name AlquilerDueloReglas
extends RefCounted

const UNO_DE_CADA := 5
const PRIMER_VENCIMIENTO_CON_DUELO := 2
## Separa esta derivación de las rondas normales del combate sin abrir otro
## dominio de azar: sigue siendo una decisión del dominio `combate`.
const INDICE_EVENTO := 85


## Aproximadamente 20% de los vencimientos, nunca el primero.
##
## Solo devuelve true cuando HOY se puede resolver realmente el alquiler. Así
## no aparece un combate en un día cualquiera ni cuando ya se pagó/reintentó el
## mismo vencimiento.
static func ocurre(jornada: Dictionary) -> bool:
	if jornada.get("fase", "") != "trayecto" or not Jornada.alquiler_pendiente(jornada):
		return false
	var dia := int(jornada.get("dia", 1))
	var vencimiento := Jornada.alquiler_vencimiento(dia)
	if dia != vencimiento or int(jornada.get("acciones", 0)) <= 0:
		return false
	var numero := int(vencimiento / Jornada.DIAS_POR_MES)
	if numero < PRIMER_VENCIMIENTO_CON_DUELO:
		return false
	var tirada := Azar.derivar(
		int(jornada.get("raiz", 0)),
		"combate",
		[int(jornada.get("vuelta", 1)), numero, INDICE_EVENTO]
	)
	return tirada % UNO_DE_CADA == 0


## Resuelve el alquiler DESPUÉS del combate sin pasar por `pagar_alquiler`.
## Ganar concede el vencimiento (importe 0); perder registra la misma pérdida
## de vivienda que #84. En ambos casos la visita consume una acción y queda
## resuelta de forma idempotente.
static func resolver(jornada: Dictionary, gano: bool) -> Dictionary:
	if jornada.get("fase", "") != "trayecto" or not Jornada.alquiler_pendiente(jornada):
		return {}
	var dia := int(jornada.get("dia", 1))
	var vencimiento := Jornada.alquiler_vencimiento(dia)
	if dia != vencimiento or int(jornada.get("acciones", 0)) <= 0:
		return {}

	jornada["acciones"] -= 1
	jornada["alquiler"]["ultimo_resuelto"] = vencimiento
	if gano:
		jornada["alquiler"]["bonificados"] = int(jornada["alquiler"].get("bonificados", 0)) + 1
	else:
		# #84 ya deriva la vivienda de `impagos`; usar el mismo contrato evita
		# crear una segunda bandera de desahucio que pueda contradecirlo.
		jornada["alquiler"]["impagos"] = int(jornada["alquiler"].get("impagos", 0)) + 1

	return {
		"vencimiento": vencimiento,
		"importe": 0 if gano else Jornada.PRECIO_ALQUILER,
		"gano": gano,
		"perdio_vivienda": not gano,
		"dinero": int(jornada.get("dinero", 0)),
		"acciones": int(jornada.get("acciones", 0)),
	}
