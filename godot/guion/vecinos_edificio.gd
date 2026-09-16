## Rutinas declarativas del portal y vecinos (#673).
##
## Este primer corte no monta geometría ni UI: describe presencias reproducibles
## a partir del día y la fase de Jornada. La capa 3D puede consumir este contrato
## sin inventar otra economía, afinidad o sistema de progreso.
class_name VecinosEdificio
extends RefCounted

const CLAVE_RESUELTOS := "vecinos_edificio_resueltos"
const ID_PAQUETE_EQUIVOCADO := "paquete_equivocado_4a"

const PRESENCIAS := [
	{
		"id": "manuela_3b",
		"nombre": "Manuela, 3º B",
		"tipo": "vecino",
		"ubicacion": "portal",
		"modo": "visible",
		"inicio": 1,
		"periodo": 2,
		"estados": ["sacude_felpudo", "riega_maceta"],
		"movimientos": ["sacudir", "regar"],
	},
	{
		"id": "televisor_2a",
		"nombre": "Piso 2º A",
		"tipo": "presencia",
		"ubicacion": "rellano_2",
		"modo": "sonoro",
		"inicio": 2,
		"periodo": 2,
		"estados": ["tertulia_baja", "partido_lejano"],
		"sonidos": ["televisor_murmullos", "televisor_partido"],
	},
	{
		"id": "pasos_4a",
		"nombre": "Piso 4º A",
		"tipo": "presencia",
		"ubicacion": "escalera",
		"modo": "sonoro",
		"inicio": 3,
		"periodo": 3,
		"estados": ["sube_dos_pisos", "baja_con_prisa"],
		"sonidos": ["pasos_escalera_lentos", "pasos_escalera_rapidos"],
	},
	{
		"id": "repartidor_confundido",
		"nombre": "Repartidor",
		"tipo": "vecino",
		"ubicacion": "buzones",
		"modo": "visible",
		"inicio": 4,
		"periodo": 4,
		"estados": ["consulta_porteros", "deja_paquete_4a"],
		"movimientos": ["mirar_porteros", "dejar_paquete"],
		"correo_postal": "buzon_portal",
	},
]

const FELPUDOS := ["centrado", "torcido", "humedo"]
const NOTAS_TABLON := ["ascensor_revision", "reunion_comunidad", "agua_corte_breve"]


static func presencias(
	jornada: Dictionary, reduccion_movimiento: bool = false
) -> Array[Dictionary]:
	if String(jornada.get("fase", "")) != "trayecto":
		return []
	var dia := _dia(jornada)
	var salida: Array[Dictionary] = []
	for base in PRESENCIAS:
		if not _aparece(base, dia):
			continue
		salida.append(_materializar(base, dia, reduccion_movimiento))
	return salida


## Estado ambiental pequeño que una futura capa 3D puede aplicar al portal sin
## depender de NPC visibles. Los sonidos salen de las mismas presencias del día.
static func estado_portal(jornada: Dictionary, reduccion_movimiento: bool = false) -> Dictionary:
	var dia := _dia(jornada)
	var sonidos: Array[String] = []
	var ids_presentes: Array[String] = []
	for presencia in presencias(jornada, reduccion_movimiento):
		ids_presentes.append(String(presencia.get("id", "")))
		var sonido_id := String(presencia.get("sonido_id", ""))
		if not sonido_id.is_empty():
			sonidos.append(sonido_id)
	return {
		"dia": dia,
		"felpudo": FELPUDOS[(dia - 1) % FELPUDOS.size()],
		"tablon_id": NOTAS_TABLON[(dia - 1) % NOTAS_TABLON.size()],
		"luz_portal": "parpadeo" if dia % 5 == 0 else "estable",
		"puerta_2a": "entornada" if ids_presentes.has("televisor_2a") else "cerrada",
		"sonidos": sonidos,
		"reduccion_movimiento": reduccion_movimiento,
	}


## Interacción deliberadamente no dialogada. Solo aparece cuando la segunda
## visita del repartidor deja un paquete junto a los buzones. Resolverla no da
## premios ni bloquea la campaña; únicamente deja el portal coherente ese día.
static func interacciones(jornada: Dictionary) -> Array[Dictionary]:
	if String(jornada.get("fase", "")) != "trayecto":
		return []
	var dia := _dia(jornada)
	var clave := _clave_resolucion(dia, ID_PAQUETE_EQUIVOCADO)
	if _resueltos(jornada).has(clave):
		return []
	for presencia in presencias(jornada):
		if (
			String(presencia.get("id", "")) == "repartidor_confundido"
			and String(presencia.get("estado", "")) == "deja_paquete_4a"
		):
			return [
				{
					"id": ID_PAQUETE_EQUIVOCADO,
					"ubicacion": "buzones",
					"verbo": "coger",
					"dialogo": false,
					"destino": "buzon_4a",
					"correo_postal": "buzon_portal",
				}
			]
	return []


static func resolver_interaccion(jornada: Dictionary, interaccion_id: String) -> Dictionary:
	if String(jornada.get("fase", "")) != "trayecto":
		return _fallo(interaccion_id, "fuera_del_trayecto")
	if interaccion_id != ID_PAQUETE_EQUIVOCADO:
		return _fallo(interaccion_id, "interaccion_desconocida")

	var dia := _dia(jornada)
	var clave := _clave_resolucion(dia, interaccion_id)
	var resueltos := _resueltos(jornada)
	if resueltos.has(clave):
		return {
			"ok": true,
			"id": interaccion_id,
			"ya_resuelta": true,
			"efecto": "paquete_en_buzon_4a",
			"bloquea_campana": false,
		}
	if interacciones(jornada).is_empty():
		return _fallo(interaccion_id, "no_disponible")

	resueltos.append(clave)
	jornada[CLAVE_RESUELTOS] = resueltos
	return {
		"ok": true,
		"id": interaccion_id,
		"ya_resuelta": false,
		"efecto": "paquete_en_buzon_4a",
		"bloquea_campana": false,
	}


static func _materializar(base: Dictionary, dia: int, reduccion_movimiento: bool) -> Dictionary:
	var salida: Dictionary = base.duplicate(true)
	var indice := _indice_ocurrencia(base, dia)
	var estados: Array = base.get("estados", [])
	if not estados.is_empty():
		salida["estado"] = String(estados[indice % estados.size()])
	var movimientos: Array = base.get("movimientos", [])
	if not movimientos.is_empty():
		var movimiento := String(movimientos[indice % movimientos.size()])
		salida["movimiento"] = "estatico" if reduccion_movimiento else movimiento
	var sonidos: Array = base.get("sonidos", [])
	if not sonidos.is_empty():
		salida["sonido_id"] = String(sonidos[indice % sonidos.size()])
	salida["dia"] = dia
	salida.erase("estados")
	salida.erase("movimientos")
	salida.erase("sonidos")
	return salida


static func _aparece(base: Dictionary, dia: int) -> bool:
	var inicio := maxi(1, int(base.get("inicio", 1)))
	var periodo := maxi(1, int(base.get("periodo", 1)))
	return dia >= inicio and (dia - inicio) % periodo == 0


static func _indice_ocurrencia(base: Dictionary, dia: int) -> int:
	var inicio := maxi(1, int(base.get("inicio", 1)))
	var periodo := maxi(1, int(base.get("periodo", 1)))
	return maxi(0, int((dia - inicio) / periodo))


static func _dia(jornada: Dictionary) -> int:
	return maxi(1, int(jornada.get("dia", 1)))


static func _resueltos(jornada: Dictionary) -> Array[String]:
	var bruto = jornada.get(CLAVE_RESUELTOS, [])
	var salida: Array[String] = []
	if typeof(bruto) != TYPE_ARRAY:
		return salida
	for valor in bruto:
		var clave := String(valor)
		if not clave.is_empty() and not salida.has(clave):
			salida.append(clave)
	return salida


static func _clave_resolucion(dia: int, interaccion_id: String) -> String:
	return "%d:%s" % [dia, interaccion_id]


static func _fallo(interaccion_id: String, motivo: String) -> Dictionary:
	return {
		"ok": false,
		"id": interaccion_id,
		"motivo": motivo,
		"bloquea_campana": false,
	}
