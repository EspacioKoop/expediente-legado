## Microincidente físico de impresora compartida (#1768).
##
## El modelo no monta nodos ni consume tiempo de Jornada. Separa dos cosas:
## - una programación reproducible por raíz/vuelta/día;
## - la secuencia local inspeccionar -> abrir -> retirar -> cerrar.
##
## La integración de mundo podrá publicar EVENTO cuando materialice el atasco y
## persistir el diccionario devuelto. Ignorar la impresora equivale simplemente
## a no llamar a transicionar: el resto del día no queda bloqueado.
class_name IncidenteImpresoraOficina
extends RefCounted

const EVENTO := "impresora_atascada"

const ATASCADA := "atascada"
const BANDEJA_ABIERTA := "bandeja_abierta"
const PAPEL_RETIRADO := "papel_retirado"
const RESUELTA := "resuelta"

const INSPECCIONAR := "inspeccionar"
const ABRIR_BANDEJA := "abrir_bandeja"
const RETIRAR_PAPEL := "retirar_papel"
const CERRAR_BANDEJA := "cerrar_bandeja"

const FRECUENCIA := 3


## Como máximo describe una incidencia para el día. El llamador decide si la
## materializa cuando se alcanza `tras_accion`; consultar no modifica Jornada.
static func programacion(jornada: Dictionary, raiz: int) -> Dictionary:
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var vuelta := maxi(1, int(jornada.get("vuelta", 1)))
	var semilla := Azar.derivar(raiz, "dia", [vuelta, dia, 1768])
	var activa := int(semilla % FRECUENCIA) != 0
	var acciones := maxi(1, Jornada.ACCIONES_POR_DIA)
	var tras_accion := 1 + int((semilla / FRECUENCIA) as int) % acciones
	return {
		"activa": activa,
		"dia": dia,
		"vuelta": vuelta,
		"tras_accion": tras_accion,
		"evento": EVENTO,
	}


static func nuevo(dia: int, vuelta: int = 1) -> Dictionary:
	return {
		"dia": maxi(1, dia),
		"vuelta": maxi(1, vuelta),
		"estado": ATASCADA,
		"inspeccionada": false,
		"resuelta": false,
		"evento": EVENTO,
	}


## Devuelve resultado + copia del incidente. Una acción fuera de orden falla
## cerrada y conserva exactamente el estado recibido.
static func transicionar(incidente: Dictionary, accion: String) -> Dictionary:
	var estado := incidente.duplicate(true)
	if estado.is_empty():
		return _resultado(false, estado, "sin_incidente")
	if bool(estado.get("resuelta", false)) or String(estado.get("estado", "")) == RESUELTA:
		return _resultado(false, estado, "ya_resuelta")

	var actual := String(estado.get("estado", ""))
	match accion:
		INSPECCIONAR:
			if actual != ATASCADA or bool(estado.get("inspeccionada", false)):
				return _resultado(false, estado, "orden_invalido")
			estado["inspeccionada"] = true
		ABRIR_BANDEJA:
			if actual != ATASCADA or not bool(estado.get("inspeccionada", false)):
				return _resultado(false, estado, "orden_invalido")
			estado["estado"] = BANDEJA_ABIERTA
		RETIRAR_PAPEL:
			if actual != BANDEJA_ABIERTA:
				return _resultado(false, estado, "orden_invalido")
			estado["estado"] = PAPEL_RETIRADO
		CERRAR_BANDEJA:
			if actual != PAPEL_RETIRADO:
				return _resultado(false, estado, "orden_invalido")
			estado["estado"] = RESUELTA
			estado["resuelta"] = true
		_:
			return _resultado(false, estado, "accion_desconocida")

	return _resultado(true, estado, "")


static func secuencia_completa() -> Array[String]:
	return [INSPECCIONAR, ABRIR_BANDEJA, RETIRAR_PAPEL, CERRAR_BANDEJA]


static func _resultado(ok: bool, estado: Dictionary, motivo: String) -> Dictionary:
	return {
		"ok": ok,
		"estado": estado,
		"resuelta": bool(estado.get("resuelta", false)),
		"motivo": motivo,
	}
