## Registro mínimo de incidentes de conducta (#209).
##
## Esta capa no anima, no mueve NPCs y no termina escenas. Solo decide qué
## significa una conducta en un lugar y conserva el mínimo historial necesario
## para reconocer reincidencia. La escena consume el resultado y decide cómo
## representarlo.
class_name IncidentesConducta
extends RefCounted

const CLAVE_HISTORIAL := "incidentes_conducta"
const GOLPE_PARED := "golpe_pared"
const OFICINA := "oficina"
const CASA := "casa"
const SUENO := "sueño"


## Registra una conducta y devuelve consecuencias declarativas.
##
## El mismo incidente repetido en el mismo día es idempotente: no añade otra
## entrada ni convierte un doble input en reincidencia. Solo un incidente de
## oficina en un día POSTERIOR dispara el despido.
static func registrar_incidente(
	estado: Dictionary, tipo: String, lugar: String, dia: int
) -> Dictionary:
	if tipo.is_empty() or lugar.is_empty() or dia < 1:
		return {}

	if lugar == SUENO:
		return _resultado(false, "onirica", false, false, false)
	if lugar == CASA:
		return _resultado(false, "marca_opcional", false, false, false)
	if lugar != OFICINA:
		return _resultado(false, "ninguna", false, false, false)

	var historial := _historial(estado)
	var reincidencia := false
	for incidente in historial:
		if typeof(incidente) != TYPE_DICTIONARY:
			continue
		if incidente.get("tipo", "") != tipo or incidente.get("lugar", "") != OFICINA:
			continue
		var dia_anterior := int(incidente.get("dia", 0))
		if dia_anterior == dia:
			return _resultado(false, "huir", true, false, true)
		if dia_anterior > 0 and dia_anterior < dia:
			reincidencia = true

	historial.append({"tipo": tipo, "lugar": OFICINA, "dia": dia})
	estado[CLAVE_HISTORIAL] = historial
	return _resultado(true, "huir", true, reincidencia, true)


## Devuelve una copia para que UI/pruebas puedan inspeccionar el historial sin
## modificar el estado persistente por accidente.
static func historial_de(estado: Dictionary) -> Array:
	return _historial(estado).duplicate(true)


static func _historial(estado: Dictionary) -> Array:
	var existente = estado.get(CLAVE_HISTORIAL, [])
	if typeof(existente) != TYPE_ARRAY:
		existente = []
	return existente


static func _resultado(
	nuevo: bool, reaccion: String, fin_jornada: bool, despido: bool, persistir: bool
) -> Dictionary:
	return {
		"nuevo": nuevo,
		"reaccion": reaccion,
		"fin_jornada": fin_jornada,
		"despido": despido,
		"persistir": persistir,
	}
