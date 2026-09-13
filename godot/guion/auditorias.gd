## Condiciones opcionales de una vida laboral (#152).
##
## Este módulo no decide CUÁNDO se incumple una condición. Solo mantiene un
## estado pequeño, determinista y guardable: qué se aceptó antes de empezar,
## qué sigue vivo y qué terminó fallando o completándose. Jornada, SIGA y el
## final pueden consumir el mismo contrato sin duplicar reglas de persistencia.
class_name Auditorias
extends RefCounted

const CATALOGO := {
	"sin_releer": {
		"rotulo": "AUDITORIA_SIN_RELEER",
		"descripcion": "AUDITORIA_SIN_RELEER_DESC",
		"incompatibles": [],
	},
	"accion_sobrante": {
		"rotulo": "AUDITORIA_ACCION_SOBRANTE",
		"descripcion": "AUDITORIA_ACCION_SOBRANTE_DESC",
		"incompatibles": [],
	},
	"gato_diario": {
		"rotulo": "AUDITORIA_GATO_DIARIO",
		"descripcion": "AUDITORIA_GATO_DIARIO_DESC",
		"incompatibles": [],
	},
	"sueno_completo": {
		"rotulo": "AUDITORIA_SUENO_COMPLETO",
		"descripcion": "AUDITORIA_SUENO_COMPLETO_DESC",
		"incompatibles": [],
	},
}


static func ids() -> Array:
	var resultado := CATALOGO.keys()
	resultado.sort()
	return resultado


## Crea el estado al COMENZAR la vida. No hay API para añadir condiciones
## después: quien quiera cambiarlas tiene que iniciar otra vida laboral.
static func nueva(seleccion: Array = []) -> Dictionary:
	if not compatibles(seleccion):
		return {}
	var activas := seleccion.duplicate()
	activas.sort()
	return {
		"activas": activas,
		"fallidas": {},
		"completadas": [],
	}


static func compatibles(seleccion: Array) -> bool:
	var vistas := {}
	for valor in seleccion:
		var id := String(valor)
		if not CATALOGO.has(id) or vistas.has(id):
			return false
		vistas[id] = true
		for otro in CATALOGO[id].get("incompatibles", []):
			if seleccion.has(otro):
				return false
	return true


static func estado(auditoria: Dictionary, id: String) -> String:
	if auditoria.get("fallidas", {}).has(id):
		return "fallida"
	if auditoria.get("completadas", []).has(id):
		return "completada"
	if auditoria.get("activas", []).has(id):
		return "activa"
	return "inactiva"


## Fallar es irreversible durante la vida. El motivo es una clave técnica para
## que UI/pruebas puedan explicar qué ocurrió sin convertirlo en puntuación.
static func fallar(auditoria: Dictionary, id: String, motivo: String = "") -> bool:
	if estado(auditoria, id) != "activa":
		return false
	auditoria["fallidas"][id] = motivo
	return true


## Completar solo es válido si la condición sobrevivió toda la vida.
static func completar(auditoria: Dictionary, id: String) -> bool:
	if estado(auditoria, id) != "activa":
		return false
	auditoria["completadas"].append(id)
	auditoria["completadas"].sort()
	return true


static func pendientes(auditoria: Dictionary) -> Array:
	var resultado := []
	for id in auditoria.get("activas", []):
		if estado(auditoria, id) == "activa":
			resultado.append(id)
	return resultado
