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
const RUTA_RESTRINGIDA := "equipo/red/acreditaciones"
const CONOCIMIENTO_INCOHERENCIA := "os98_incoherencia"


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
	var credenciales: Array[String] = []
	var conocimiento: Array[String] = []
	if bool(estado.get("credencial_descubierta", false)):
		credenciales.append(CREDENCIAL)
		conocimiento.append(CREDENCIAL)
	if int(estado.get("fase", FASE_NORMALIDAD)) >= FASE_INCOHERENCIAS:
		conocimiento.append(CONOCIMIENTO_INCOHERENCIA)
	return {
		"jornada": maxi(1, dia),
		"dia": maxi(1, dia),
		"memorandum_disponible": memorandum,
		# La superficie restringida se ve cuando existe el memorándum, pero sigue
		# bloqueada hasta que el jugador lo abre y conoce la credencial.
		"habilitar_enlace13": memorandum,
		"credenciales": credenciales,
		"conocimiento": conocimiento,
		"urls_caidas": [],
		"fase_contaminacion": int(estado.get("fase", FASE_NORMALIDAD)),
	}


## Leer el memorándum concede conocimiento; abrir después el diagnóstico
## restringido activa la primera incoherencia verificable. Repetir cualquiera de
## los dos hitos es idempotente.
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
		_avanzar(estado, FASE_INCOHERENCIAS, "diagnostico_restringido_leido")
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
