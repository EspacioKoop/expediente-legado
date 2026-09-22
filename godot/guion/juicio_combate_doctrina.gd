## Estado y transiciones de doctrinas del Juicio por Combate.
##
## Mantiene decisiones de activación fuera del Node3D. El orquestador conserva
## audio, nodos, HUD y aplicación física de los efectos.
class_name JuicioCombateDoctrina
extends RefCounted

const REGLAS = preload("res://guion/juicio_combate_reglas.gd")

const ACCION_NINGUNA := ""
const ACCION_TEMPORIZADA := "temporizada"
const ACCION_MESA := "mesa"
const ACCION_COMISION := "comision"


static func bloqueada(doctrina_activa: String, comision_pendiente: bool) -> bool:
	return not doctrina_activa.is_empty() or comision_pendiente


static func intentar_activar(
	eje: String,
	cargas: Dictionary,
	ritual: Dictionary,
	acabado: bool,
	habilidad_disponible: bool,
	doctrina_activa: String,
	comision_pendiente: bool,
) -> Dictionary:
	if acabado or not habilidad_disponible:
		return {"aceptada": false}
	if int(cargas.get(eje, 0)) <= 0:
		return {"aceptada": false}
	if bloqueada(doctrina_activa, comision_pendiente):
		return {"aceptada": false}

	var nuevas_cargas := cargas.duplicate(true)
	nuevas_cargas[eje] = int(nuevas_cargas[eje]) - 1
	var plan := {
		"aceptada": true,
		"cargas": nuevas_cargas,
		"accion": ACCION_NINGUNA,
		"doctrina_activa": doctrina_activa,
		"doctrina_tiempo": 0.0,
	}
	match eje:
		"comunismo", "neoliberal":
			plan["accion"] = ACCION_TEMPORIZADA
			plan["doctrina_activa"] = eje
			plan["doctrina_tiempo"] = REGLAS.duracion_doctrina(eje, ritual)
		"centrista":
			plan["accion"] = ACCION_MESA
		"socialdemocrata":
			plan["accion"] = ACCION_COMISION
	return plan


static func plan_comision(
	ataque_pendiente: bool,
	telegrafo_restante: float,
	telegrafo_total: float,
	ritual: Dictionary,
) -> Dictionary:
	if not ataque_pendiente:
		return {
			"comision_pendiente": true,
			"doctrina_activa": "",
			"doctrina_tiempo": 0.0,
			"telegrafo_restante": telegrafo_restante,
			"telegrafo_total": telegrafo_total,
		}

	var total_nuevo := REGLAS.duracion_telegrafo(true, ritual)
	var extra := maxf(0.0, total_nuevo - REGLAS.TELEGRAFO_RIVAL)
	var restante_nuevo := telegrafo_restante + extra
	return {
		"comision_pendiente": false,
		"doctrina_activa": "socialdemocrata",
		"doctrina_tiempo": restante_nuevo,
		"telegrafo_restante": restante_nuevo,
		"telegrafo_total": telegrafo_total + extra,
	}


static func eje_estado(doctrina_activa: String, comision_pendiente: bool) -> String:
	if doctrina_activa.is_empty() and comision_pendiente:
		return "socialdemocrata"
	return doctrina_activa
