## Progresión diegética del escritorio OS98 (#539).
##
## Este módulo no toca el host ni decide presentación. Recibe estado local del
## escritorio y estado de campaña, y devuelve un contexto declarativo compartido
## por Explorador y Web98. La progresión es por hitos explícitos: nunca usa RNG.
class_name ContaminacionOs98
extends RefCounted

const FASE_NORMALIDAD := 0
const FASE_ACCESO_PRIVILEGIADO := 1
const FASE_INCOHERENCIAS := 2
const FASE_CONTAMINACION_CRUZADA := 3
const FASE_CLIMAX := 4

const EXPEDIENTES_PRINCIPALES := 5
const CREDENCIAL := "enlace13"
const MEMORANDUM_ID := "memorandum_enlace13"
const DIAGNOSTICO_ID := "diagnostico_enlace13"
const REGISTRO_IMPOSIBLE_ID := "registro_imposible_13"
const RUTA_RESTRINGIDA := "equipo/red/acreditaciones"
const CONOCIMIENTO_INCOHERENCIA := "os98_incoherencia"
const CONOCIMIENTO_CLIMAX := "os98_climax_pendiente"
const URL_DIAGNOSTICO := "http://intranet.dgai/diag/enlace13/"


static func nuevo() -> Dictionary:
	return {
		"fase": FASE_NORMALIDAD,
		"credencial_descubierta": false,
		"acceso_restringido_usado": false,
		"hitos": [],
	}


static func completar(estado: Dictionary) -> Dictionary:
	var molde := nuevo()
	for clave in molde:
		if not estado.has(clave):
			estado[clave] = molde[clave]
	estado["fase"] = clampi(int(estado.get("fase", FASE_NORMALIDAD)), FASE_NORMALIDAD, FASE_CLIMAX)
	if not estado.get("hitos", []) is Array:
		estado["hitos"] = []
	return estado


## #28: la acreditación solo entra en juego después de cinco cierres reales.
## Los veredictos son el registro persistente de expedientes cerrados; no se
## infieren días, clicks ni orden de lectura.
static func memorandum_disponible(partida: Dictionary) -> bool:
	var veredictos: Variant = partida.get("veredictos", {})
	return veredictos is Dictionary and (veredictos as Dictionary).size() >= EXPEDIENTES_PRINCIPALES


## Contexto único para todas las apps del OS. Así una anomalía no necesita
## reimplementar la misma condición en Explorador, Web98 o futuras superficies.
static func contexto(partida: Dictionary, estado: Dictionary, dia: int) -> Dictionary:
	completar(estado)
	var memorandum := memorandum_disponible(partida)
	var fase := int(estado.get("fase", FASE_NORMALIDAD))
	var credenciales: Array[String] = []
	var conocimiento: Array[String] = []
	var urls_caidas: Array[String] = []
	if bool(estado.get("credencial_descubierta", false)):
		credenciales.append(CREDENCIAL)
		conocimiento.append(CREDENCIAL)
	if fase >= FASE_INCOHERENCIAS:
		conocimiento.append(CONOCIMIENTO_INCOHERENCIA)
	# Fase 3: una acción en Explorador altera de forma verificable una superficie
	# distinta. El diagnóstico que funcionaba en fase 1/2 deja de responder en
	# Web98, mientras su volcado imposible sigue disponible como rastro. No hay
	# azar ni red real: `Web98Indice` interpreta esta URL como caída simulada.
	if fase >= FASE_CONTAMINACION_CRUZADA:
		urls_caidas.append(URL_DIAGNOSTICO)
	# Fase 4 no arranca aquí el combate ni el final de #9. Solo publica un handoff
	# estable y persistente por vuelta para que la capa dueña del clímax pueda
	# consumirlo sin volver a interpretar documentos, historial o credenciales.
	if fase >= FASE_CLIMAX:
		conocimiento.append(CONOCIMIENTO_CLIMAX)
	return {
		"jornada": maxi(1, dia),
		"dia": maxi(1, dia),
		"memorandum_disponible": memorandum,
		# La superficie restringida se ve cuando existe el memorándum, pero sigue
		# bloqueada hasta que el jugador lo abre y conoce la credencial.
		"habilitar_enlace13": memorandum,
		"credenciales": credenciales,
		"conocimiento": conocimiento,
		"urls_caidas": urls_caidas,
		"fase_contaminacion": fase,
		"efecto_texto": configuracion_texto_corrupto(fase),
		"climax_hastur_pendiente": fase >= FASE_CLIMAX,
	}


## Contrato visual declarativo para #806. La presentación decide qué nodos
## concretos reciben el efecto; aquí solo se publica intensidad, ritmo y semilla
## estable por fase narrativa.
static func configuracion_texto_corrupto(fase: int) -> Dictionary:
	var fase_segura := clampi(fase, FASE_NORMALIDAD, FASE_CLIMAX)
	var intensidad := 0.0
	match fase_segura:
		FASE_INCOHERENCIAS:
			intensidad = 0.30
		FASE_CONTAMINACION_CRUZADA:
			intensidad = 0.62
		FASE_CLIMAX:
			intensidad = 0.88
	return {
		"activo": intensidad > 0.0,
		"intensidad": intensidad,
		"duracion": 1.35,
		"reversible": true,
		"semilla": "contaminacion-os98-fase-%d" % fase_segura,
	}


## Leer el memorándum concede conocimiento; abrir después el diagnóstico
## restringido activa la primera incoherencia verificable. Leer esa evidencia
## imposible hace avanzar a contaminación cruzada. Cuando el jugador vuelve al
## diagnóstico después de comprobar que Web98 ya no puede resolverlo, se alcanza
## fase 4 y queda publicado el handoff de clímax. Repetir hitos es idempotente.
static func registrar_documento(
	partida: Dictionary, estado: Dictionary, documento_id: String
) -> bool:
	completar(estado)
	if documento_id == MEMORANDUM_ID:
		if not memorandum_disponible(partida):
			return false
		var cambio := not bool(estado.get("credencial_descubierta", false))
		estado["credencial_descubierta"] = true
		_avanzar(estado, FASE_ACCESO_PRIVILEGIADO, "memorandum_leido")
		return cambio
	if documento_id == DIAGNOSTICO_ID and bool(estado.get("credencial_descubierta", false)):
		var fase_antes := int(estado.get("fase", FASE_NORMALIDAD))
		if fase_antes >= FASE_CONTAMINACION_CRUZADA:
			_avanzar(estado, FASE_CLIMAX, "diagnostico_reabierto_climax")
		else:
			_avanzar(estado, FASE_INCOHERENCIAS, "diagnostico_restringido_leido")
		return int(estado.get("fase", FASE_NORMALIDAD)) != fase_antes
	if (
		documento_id == REGISTRO_IMPOSIBLE_ID
		and int(estado.get("fase", FASE_NORMALIDAD)) >= FASE_INCOHERENCIAS
	):
		var fase_antes := int(estado.get("fase", FASE_NORMALIDAD))
		_avanzar(estado, FASE_CONTAMINACION_CRUZADA, "registro_imposible_leido")
		return int(estado.get("fase", FASE_NORMALIDAD)) != fase_antes
	return false


static func registrar_ruta(estado: Dictionary, ruta: String) -> bool:
	completar(estado)
	if ruta != RUTA_RESTRINGIDA or not bool(estado.get("credencial_descubierta", false)):
		return false
	if bool(estado.get("acceso_restringido_usado", false)):
		return false
	estado["acceso_restringido_usado"] = true
	_anotar_hito(estado, "acceso_restringido_usado")
	return true


static func _avanzar(estado: Dictionary, fase: int, hito: String) -> void:
	estado["fase"] = maxi(int(estado.get("fase", FASE_NORMALIDAD)), fase)
	_anotar_hito(estado, hito)


static func _anotar_hito(estado: Dictionary, hito: String) -> void:
	if hito.is_empty():
		return
	var hitos: Array = estado.get("hitos", [])
	if not hitos.has(hito):
		hitos.append(hito)
	estado["hitos"] = hitos
