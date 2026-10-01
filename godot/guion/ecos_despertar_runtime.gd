## Captura runtime del material vivido para los ecos de despertar (#1775).
##
## Acumula candidatos provenientes de nodos realmente montados, prepara un
## único pendiente antes de despertar y lo presenta una sola vez al entrar en
## la primera vigilia. Ninguna de esas capas crea hechos o progreso.
class_name EcosDespertarRuntime
extends RefCounted

const CLAVE_MATERIAL := "eco_despertar_material_vivido"
const CLAVE_PENDIENTE := "eco_despertar_pendiente"


static func registrar_sala(
	jornada: Dictionary, mundo: Node3D, anomalias: Array
) -> Array[Dictionary]:
	if String(jornada.get("fase", "")) != "sueño" or mundo == null:
		return []

	var objetos_montados := []
	for candidato in anomalias:
		if not candidato is Node:
			continue
		var objeto_id := String((candidato as Node).get_meta("objeto_origen", "")).strip_edges()
		if not objeto_id.is_empty() and not objetos_montados.has(objeto_id):
			objetos_montados.append(objeto_id)

	var mutador_presentado := {}
	var presentador := mundo.get_node_or_null(SuenoMutadorPresentacion3D.NOMBRE)
	if presentador != null and is_instance_valid(presentador):
		var meta: Variant = presentador.get_meta("presentacion", {})
		if meta is Dictionary:
			mutador_presentado = (meta as Dictionary).duplicate(true)

	var nuevos := EcosDespertar.material_desde_noche(mutador_presentado, objetos_montados)
	var previos: Variant = jornada.get(CLAVE_MATERIAL, [])
	var acumulado := []
	if previos is Array:
		acumulado.append_array((previos as Array).duplicate(true))
	acumulado.append_array(nuevos)
	var canonicos := EcosDespertar.candidatos(acumulado)
	if canonicos.is_empty():
		return []
	jornada[CLAVE_MATERIAL] = canonicos.duplicate(true)
	return canonicos


## Convierte el material de la noche que termina en un único pendiente para la
## mañana siguiente. Debe llamarse antes de Jornada.despertar*: después se
## pierde la fase nocturna y el día ya ha avanzado.
##
## Es idempotente dentro de la misma noche. Si una ruta intenta preparar dos
## veces (por reintento/callback duplicado), conserva el pendiente ya elegido y
## consume igualmente el acumulador para que no contamine noches posteriores.
static func preparar_despertar(jornada: Dictionary) -> Dictionary:
	if String(jornada.get("fase", "")) != "sueño":
		return {}

	var noche := int(jornada.get("dia", 0))
	var previo_bruto: Variant = jornada.get(CLAVE_PENDIENTE, {})
	if previo_bruto is Dictionary:
		var previo := previo_bruto as Dictionary
		if EcosDespertar.vigente(previo, noche + 1):
			jornada.erase(CLAVE_MATERIAL)
			return previo.duplicate(true)

	var material_bruto: Variant = jornada.get(CLAVE_MATERIAL, [])
	var material: Array = []
	if material_bruto is Array:
		material = (material_bruto as Array).duplicate(true)
	var pendiente := (
		EcosDespertar
		. preparar(
			material,
			int(jornada.get("raiz", 0)),
			noche,
		)
	)
	jornada.erase(CLAVE_MATERIAL)
	if pendiente.is_empty():
		jornada.erase(CLAVE_PENDIENTE)
		return {}

	jornada[CLAVE_PENDIENTE] = pendiente.duplicate(true)
	return pendiente.duplicate(true)


## Monta el pendiente únicamente en la primera fase de vigilia. Consultar no
## consume: la aceptación se escribe en Jornada solo si el presentador llegó a
## crear una capa sensorial válida.
static func presentar_vigilia(
	jornada: Dictionary,
	mundo: Node3D,
	espacio: Dictionary,
	reduccion_movimiento: bool,
) -> bool:
	if String(jornada.get("fase", "")) != "archivo" or mundo == null:
		return false
	var dia := int(jornada.get("dia", 0))
	var bruto: Variant = jornada.get(CLAVE_PENDIENTE, {})
	if not bruto is Dictionary:
		return false
	var oferta := EcosDespertar.oferta(bruto as Dictionary, dia)
	if oferta.is_empty():
		return false
	var presentacion := EcosDespertar.presentacion(oferta, reduccion_movimiento)
	var capa := EcoDespertarPresentacion3D.montar(mundo, presentacion, espacio)
	if capa == null:
		return false
	var aceptado := EcosDespertar.aceptar(oferta, String(presentacion.get("id", "")), dia)
	if not bool(aceptado.get("ok", false)):
		capa.queue_free()
		return false
	jornada[CLAVE_PENDIENTE] = (aceptado["estado"] as Dictionary).duplicate(true)
	return true
