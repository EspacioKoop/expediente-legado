## Contrato de procedencia del prólogo jugado de Crónicas (#2589).
##
## Se llama EXCLUSIVAMENTE desde la señal prologo_completado de CronicasPc98.
## La visita permanece en EstadoAplicacionesSiga (metadatos OS98), nunca en
## Partida ni en SemillasOniricas. Una futura experiencia EN CASA decidirá
## si este recuerdo puede activar una semilla, sin anticipar hechos SIGA.
class_name CronicasExposicion2589
extends RefCounted

const ID_APP := "cronicas-pc-98"
const CAMPO_REGISTRO := "prologos_por_vuelta"
const FUENTE_VERIFICADA := "pc98:cronicas:prologo_bastion"


static func clave_vuelta(jornada: Dictionary) -> String:
	var raiz := int(jornada.get("raiz", 0))
	var vuelta := int(jornada.get("vuelta", 0))
	if raiz <= 0 or vuelta <= 0:
		return ""
	return "%d:%d" % [raiz, vuelta]


## El guardado de la partida se mantiene en Dia. No se llama desde _ready
## ni desde el menú "Jugar", solo tras superar el custodio y cruzar el umbral.
static func registrar_prologo(app: EscritorioSigaApp, jornada: Dictionary) -> bool:
	if not _app_valida(app):
		return false
	var clave := clave_vuelta(jornada)
	var dia := int(jornada.get("dia", 0))
	if clave.is_empty() or dia <= 0:
		return false

	var historico := _historico(app)
	if historico.has(clave):
		# No permitir una segunda recompensa ni sobreescribir la primera fecha.
		return false
	historico[clave] = {
		"fuente": FUENTE_VERIFICADA,
		"raiz": int(jornada.get("raiz", 0)),
		"vuelta": int(jornada.get("vuelta", 0)),
		"dia": dia,
	}
	app.establecer_estado_local(CAMPO_REGISTRO, historico)
	return true


## Consulta de procedencia únicamente: una visita NO es una semilla.
static func prologo_verificado(app: EscritorioSigaApp, jornada: Dictionary) -> bool:
	if not _app_valida(app):
		return false
	var clave := clave_vuelta(jornada)
	if clave.is_empty():
		return false
	var entrada: Variant = _historico(app).get(clave, {})
	if not entrada is Dictionary:
		return false
	return (
		String(entrada.get("fuente", "")) == FUENTE_VERIFICADA
		and int(entrada.get("raiz", 0)) == int(jornada.get("raiz", -1))
		and int(entrada.get("vuelta", 0)) == int(jornada.get("vuelta", -1))
		and int(entrada.get("dia", 0)) > 0
	)


static func _app_valida(app: EscritorioSigaApp) -> bool:
	return app != null and app.id == ID_APP and app.persistir_estado


static func _historico(app: EscritorioSigaApp) -> Dictionary:
	var guardado: Variant = app.obtener_estado_local(CAMPO_REGISTRO, {})
	if guardado is Dictionary:
		return (guardado as Dictionary).duplicate(true)
	return {}
