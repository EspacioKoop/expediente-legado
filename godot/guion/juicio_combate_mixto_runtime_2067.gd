## Composición pura de arena mixta ENJAMBRE + rival singular (#2268 / #2067).
##
## No aplica daño: el host informa qué índices han sido derrotados. Este módulo
## conserva índices, avanza las políticas existentes y declara terminación solo
## cuando no queda ningún rival vivo.
class_name JuicioCombateMixtoRuntime2067
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const ENJAMBRE = preload("res://guion/juicio_combate_enjambre_runtime.gd")

const CANTIDAD_ENJAMBRE := 2
const INDICE_SINGULAR := 41


static func nuevo(raiz: int, tipo_singular: String = ARQUETIPOS.BLOQUEADOR) -> Dictionary:
	var tipo := tipo_singular
	if tipo not in [ARQUETIPOS.BLOQUEADOR, ARQUETIPOS.HOSTIGADOR]:
		tipo = ARQUETIPOS.BLOQUEADOR
	return {
		"_raiz": raiz,
		"enjambre": HOST.nuevo_enjambre(raiz, CANTIDAD_ENJAMBRE),
		"singular": ARQUETIPOS.nuevo(tipo, raiz, INDICE_SINGULAR),
		"singular_vivo": true,
	}


static func avanzar(
	estado: Dictionary,
	delta: float,
	contexto_singular: Dictionary = {},
	derrotados_enjambre: Array = [],
	singular_derrotado: bool = false,
) -> Dictionary:
	var copia := estado.duplicate(true)
	if copia.is_empty():
		copia = nuevo(0)

	var unidades: Array = copia.get("enjambre", [])
	for indice_variant in derrotados_enjambre:
		var indice := int(indice_variant)
		if indice < 0 or indice >= unidades.size():
			continue
		var unidad = unidades[indice]
		if unidad is Dictionary:
			unidad["determinacion"] = 0
			unidades[indice] = unidad
	copia["enjambre"] = unidades

	if singular_derrotado:
		copia["singular_vivo"] = false

	var paso_enjambre := ENJAMBRE.tick(
		unidades,
		delta,
		HOST.presupuesto_enjambre(),
	)
	copia["enjambre"] = paso_enjambre.get("unidades", unidades)

	var paso_singular := {}
	if bool(copia.get("singular_vivo", false)):
		var singular: Dictionary = copia.get("singular", {})
		paso_singular = ARQUETIPOS.avanzar(singular, delta, contexto_singular)
		copia["singular"] = paso_singular.get("unidad", singular)

	var vivos_enjambre := _vivos(copia.get("enjambre", []))
	var singular_vivo := bool(copia.get("singular_vivo", false))
	var unidades_ventana: Array = copia.get("enjambre", []).duplicate(true)
	if singular_vivo:
		unidades_ventana.append(copia.get("singular", {}))

	return {
		"estado": copia,
		"enjambre": paso_enjambre,
		"singular": paso_singular,
		"vivos_enjambre": vivos_enjambre,
		"singular_vivo": singular_vivo,
		"ventana_respuesta": ARQUETIPOS.arena_tiene_ventana(unidades_ventana),
		"terminado": vivos_enjambre == 0 and not singular_vivo,
	}


static func _vivos(unidades: Array) -> int:
	var vivos := 0
	for unidad in unidades:
		if unidad is Dictionary and int(unidad.get("determinacion", 0)) > 0:
			vivos += 1
	return vivos
