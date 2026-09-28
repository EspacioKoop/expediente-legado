## Política pura de variedad para objetivos oníricos (#299).
##
## Decide qué condiciones físicas ofrece una noche y normaliza sus descriptores.
## No crea nodos ni concede progreso: SuenoObjetivos sigue siendo la autoridad
## que cuenta, falla y resuelve objetivos.
class_name SuenoObjetivosVariedad
extends RefCounted

const TIPO_RECORRIDO := "recorrido"
const TIPO_SECUENCIA := "secuencia"
const TIPO_PERMANENCIA := "permanencia"
const TIPO_RETORNO := "retorno"

const CANTIDAD_POR_NOCHE := SuenoObjetivos.POSIBLES_PRIMER_CORTE
const TIPOS := [TIPO_RECORRIDO, TIPO_SECUENCIA, TIPO_PERMANENCIA, TIPO_RETORNO]


static func tipos_para(dia: int, escena_id: String) -> Array:
	var semilla := dia * 17
	for byte in escena_id.to_utf8_buffer():
		semilla += int(byte)
	var rotacion := posmod(semilla, TIPOS.size())
	var salida: Array = []
	for indice in CANTIDAD_POR_NOCHE:
		salida.append(TIPOS[posmod(indice + rotacion, TIPOS.size())])
	return salida


static func condicion(tipo: String) -> String:
	match tipo:
		TIPO_SECUENCIA:
			return "seguir_secuencia"
		TIPO_PERMANENCIA:
			return "permanecer"
		TIPO_RETORNO:
			return "ida_y_vuelta"
		_:
			return "alcanzar"


static func punto_inicial_secuencia(origen: Vector3, destino: Vector3) -> Vector3:
	var punto := origen.lerp(destino, 0.45)
	punto.y = destino.y
	return punto


static func descriptor(objetivo: Dictionary) -> Dictionary:
	return {
		"id": String(objetivo.get("id", "")),
		"tipo": String(objetivo.get("tipo", "interaccion")),
		"condicion": String(objetivo.get("condicion", "evento_determinista")),
		"feedback": "ambiente",
		"cuenta": true,
	}


static func sincronizar_descriptores(estado: Dictionary, objetivos_espacio: Array) -> void:
	var descriptores: Array = estado.get("objetivos", [])
	for indice in descriptores.size():
		var descriptor_actual: Dictionary = descriptores[indice]
		var objetivo_id := String(descriptor_actual.get("id", ""))
		for objetivo in objetivos_espacio:
			if String(objetivo.get("id", "")) != objetivo_id:
				continue
			descriptor_actual["tipo"] = String(
				objetivo.get("tipo", descriptor_actual.get("tipo", "interaccion"))
			)
			descriptor_actual["condicion"] = String(
				objetivo.get(
					"condicion", descriptor_actual.get("condicion", "evento_determinista")
				)
			)
			descriptores[indice] = descriptor_actual
			break
	estado["objetivos"] = descriptores
