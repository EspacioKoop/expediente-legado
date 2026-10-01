## Eco efímero del sueño al despertar (#1775).
##
## Esta capa no escribe estado global ni monta escenas. Recibe material que el
## dueño de la noche ya confirmó como vivido, selecciona como máximo un eco y
## devuelve un pendiente pequeño que el consumidor puede aceptar una sola vez.
class_name EcosDespertar
extends RefCounted

const HUMEDAD := "humedad"
const CRT := "crt"
const OBJETO_DESPLAZADO := "objeto_desplazado"
const SONIDO_RESIDUAL := "sonido_residual"
const TIPOS := [HUMEDAD, CRT, OBJETO_DESPLAZADO, SONIDO_RESIDUAL]

## Solo material que puede haber aparecido realmente en SuenoUtileria. Esta
## tabla no mira objetos tocados: el caller pasa exclusivamente ids extraidos
## de anomalias que ya fueron montadas en la sala.
const ORIGENES_CRT := ["monitor", "televisor_casa"]
const ORIGENES_OBJETO_DESPLAZADO := ["silla", "archivador", "armario_hogar"]


## Traduce presentacion nocturna ya materializada al contrato minimo de ecos.
## mutador_nocturno es la metadata aplicada al espacio por MutadoresSueno;
## objetos_montados son los objeto_origen de las anomalias creadas por
## SuenoUtileria. Desconocidos y material no montado no generan nada.
static func material_desde_noche(
	mutador_nocturno: Dictionary, objetos_montados: Array
) -> Array[Dictionary]:
	var material: Array[Dictionary] = []
	var mutador_id := String(mutador_nocturno.get("id", "")).strip_edges()
	if mutador_id == MutadoresSueno.HUMEDAD:
		material.append({"tipo": HUMEDAD, "origen_id": "mutador:humedad"})
	elif mutador_id == MutadoresSueno.DESFASE:
		# DESFASE es el unico mutador actual que monta audio audible en la sala.
		material.append({"tipo": SONIDO_RESIDUAL, "origen_id": "mutador:desfase"})

	var vistos := {}
	for valor in objetos_montados:
		var objeto_id := String(valor).strip_edges()
		if objeto_id.is_empty() or vistos.has(objeto_id):
			continue
		vistos[objeto_id] = true
		if ORIGENES_CRT.has(objeto_id):
			material.append({"tipo": CRT, "origen_id": "utileria:%s" % objeto_id})
		elif ORIGENES_OBJETO_DESPLAZADO.has(objeto_id):
			material.append(
				{"tipo": OBJETO_DESPLAZADO, "origen_id": "utileria:%s" % objeto_id}
			)

	return candidatos(material)


static func candidatos(material_vivido: Array) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var vistos := {}
	for valor in material_vivido:
		if not valor is Dictionary:
			continue
		var entrada: Dictionary = valor
		var tipo := String(entrada.get("tipo", ""))
		var origen_id := String(entrada.get("origen_id", "")).strip_edges()
		if not TIPOS.has(tipo) or origen_id.is_empty():
			continue
		var firma := "%s:%s" % [tipo, origen_id]
		if vistos.has(firma):
			continue
		vistos[firma] = true
		salida.append({"tipo": tipo, "origen_id": origen_id})
	return salida


static func preparar(material_vivido: Array, raiz: int, dia_noche: int) -> Dictionary:
	var disponibles := candidatos(material_vivido)
	if disponibles.is_empty():
		return {}
	var noche := maxi(1, dia_noche)
	var tirada := Azar.derivar(raiz, "sueno", [noche, 1775])
	var elegido: Dictionary = disponibles[int(tirada % disponibles.size())]
	var tipo := String(elegido["tipo"])
	var origen_id := String(elegido["origen_id"])
	return {
		"id": "eco:%d:%s:%s" % [noche + 1, tipo, origen_id],
		"tipo": tipo,
		"origen_id": origen_id,
		"dia_vigilia": noche + 1,
		"consumido": false,
	}


static func vigente(pendiente: Dictionary, dia_vigilia: int) -> bool:
	if pendiente.is_empty() or bool(pendiente.get("consumido", false)):
		return false
	if int(pendiente.get("dia_vigilia", -1)) != dia_vigilia:
		return false
	if not TIPOS.has(String(pendiente.get("tipo", ""))):
		return false
	return not String(pendiente.get("origen_id", "")).strip_edges().is_empty()


## Consultar la oferta no muta nada. Así guardar/cargar antes de que una escena
## la acepte conserva exactamente el mismo pendiente.
static func oferta(pendiente: Dictionary, dia_vigilia: int) -> Dictionary:
	if not vigente(pendiente, dia_vigilia):
		return {}
	return pendiente.duplicate(true)


## El consumidor confirma que realmente montó el efecto pasando el mismo id.
## Una aceptación repetida falla cerrada y conserva el estado ya consumido.
static func aceptar(pendiente: Dictionary, eco_id: String, dia_vigilia: int) -> Dictionary:
	var estado := pendiente.duplicate(true)
	if not vigente(estado, dia_vigilia):
		return {"ok": false, "estado": estado}
	if eco_id != String(estado.get("id", "")):
		return {"ok": false, "estado": estado}
	estado["consumido"] = true
	return {"ok": true, "estado": estado}


## Al pasar a otro día el residuo se descarta incluso si nadie lo llegó a ver.
static func descartar_al_avanzar(pendiente: Dictionary, dia_vigilia: int) -> Dictionary:
	if pendiente.is_empty():
		return {}
	if dia_vigilia > int(pendiente.get("dia_vigilia", -1)):
		return {}
	return pendiente.duplicate(true)


## La accesibilidad solo cambia la forma de presentar el mismo eco.
static func presentacion(pendiente: Dictionary, reduccion_movimiento: bool) -> Dictionary:
	if pendiente.is_empty():
		return {}
	return {
		"id": String(pendiente.get("id", "")),
		"tipo": String(pendiente.get("tipo", "")),
		"origen_id": String(pendiente.get("origen_id", "")),
		"estilo": "corte" if reduccion_movimiento else "transicion",
	}
