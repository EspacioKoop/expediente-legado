## Adaptador mecánico de Vicios personificados (#2257 / #2088).
##
## Mantiene tres cuerpos alegóricos y delega íntegramente la política temporal
## al ENJAMBRE canónico. No aplica daño ni decide representación cultural.
class_name JuicioCombateViciosRuntime2088
extends RefCounted

const ENJAMBRE = preload("res://guion/juicio_combate_enjambre_runtime.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")

const CANTIDAD := 3


static func nuevo(raiz: int) -> Dictionary:
	return {
		"unidades": HOST.nuevo_enjambre(raiz, CANTIDAD),
	}


static func avanzar(estado: Dictionary, delta: float) -> Dictionary:
	var copia := estado.duplicate(true)
	var unidades: Array = copia.get("unidades", [])
	if unidades.is_empty():
		unidades = HOST.nuevo_enjambre(0, CANTIDAD)

	var paso := (
		ENJAMBRE
		. tick(
			unidades,
			delta,
			HOST.presupuesto_enjambre(),
		)
	)
	var nuevas: Array = paso.get("unidades", unidades)
	copia["unidades"] = nuevas

	var vivos := 0
	for unidad in nuevas:
		if unidad is Dictionary and int(unidad.get("determinacion", 0)) > 0:
			vivos += 1

	return {
		"estado": copia,
		"resultados": paso.get("resultados", []),
		"inicio_ataque": paso.get("inicio_ataque", []),
		"abrir_ventana": paso.get("abrir_ventana", []),
		"atacantes_activos": int(paso.get("atacantes_activos", 0)),
		"vivos": vivos,
	}
