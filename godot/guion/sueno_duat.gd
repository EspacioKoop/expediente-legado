## Primer vertical standalone del Duat egipcio noventero (#441).
##
## Este módulo no decide qué noche aparece una familia ni modifica el generador
## común. Reutiliza el contrato de semillas de #442/#472 y una familia espacial
## ya caminable de #279 para preparar un pesaje burocrático reproducible.
##
## El contenido de vigilia es propio: un microdocumental ficticio de 1998. No
## copia personajes, diseños, logos ni escenas de franquicias contemporáneas.
class_name SuenoDuat
extends RefCounted

const ID := "duat"
const FUENTE_TV := "tv:microdocumental_excavaciones_98"
const MAX_OBJETOS := 5
const TOLERANCIA := 0.01


## Punto de integración previsto para la TV de casa. Ver el canal de fondo no
## basta: solo completar el fragmento registra la semilla cultural del día.
static func registrar_documental(jornada: Dictionary, fragmento_completado: bool) -> bool:
	if not fragmento_completado:
		return false
	return SemillasOniricas.activar_semilla_onirica(jornada, ID, FUENTE_TV, 1)


## La escena Duat solo puede vestirse cuando #442 confirma que la familia fue
## activada deliberadamente durante esta jornada.
static func habilitado(jornada: Dictionary) -> bool:
	return SemillasOniricas.familias_activas(jornada).has(ID)


## Construye un reto de balanza a partir de objetos realmente manipulados hoy.
##
## Cada objeto compatible declara:
## - `id`: identificador estable;
## - `peso`: propiedad física observable;
## - `manipulado_hoy`: evita introducir recuerdos que el jugador no tocó;
## - `peso_sellado` opcional: variante observable tras sellar/archivar.
##
## La selección se ordena antes de rotarse con `semilla`, de modo que la misma
## entrada produce siempre el mismo reto aunque el llamador entregue los objetos
## en otro orden. El peso objetivo se construye con una combinación que existe
## realmente entre los objetos seleccionados: nunca exige adivinar moralidad.
static func preparar_pesaje(objetos_conocidos: Array, semilla: int = 0) -> Dictionary:
	var validos := _objetos_validos(objetos_conocidos)
	if validos.size() < 2:
		return {}

	var limite := mini(MAX_OBJETOS, validos.size())
	var inicio := posmod(semilla, validos.size())
	var objetos: Array = []
	for desplazamiento in limite:
		objetos.append(validos[(inicio + desplazamiento) % validos.size()].duplicate(true))

	# Elegir posiciones pares o impares según la semilla garantiza una solución
	# real y evita convertir el puzzle en un inventario completo de objetos.
	var paridad := posmod(semilla, 2)
	var peso_objetivo := 0.0
	for indice in objetos.size():
		if indice % 2 == paridad:
			peso_objetivo += float(objetos[indice].get("peso", 0.0))

	return {
		"objetos": objetos,
		"peso_objetivo": peso_objetivo,
		"tolerancia": TOLERANCIA,
		"regla": "peso_observable",
	}


## Evalúa una colocación sin efectos laterales. `seleccion` usa `id -> bool`,
## donde el bool indica si ese objeto se pesa en su variante sellada. IDs que no
## pertenecen al reto se ignoran y un mismo objeto solo puede sumar una vez.
static func evaluar_pesaje(estado: Dictionary, seleccion: Dictionary) -> Dictionary:
	var objetivo := float(estado.get("peso_objetivo", 0.0))
	var tolerancia := float(estado.get("tolerancia", TOLERANCIA))
	var total := 0.0
	var usados: Array[String] = []

	for bruto in estado.get("objetos", []):
		if typeof(bruto) != TYPE_DICTIONARY:
			continue
		var objeto: Dictionary = bruto
		var id := String(objeto.get("id", ""))
		if id.is_empty() or not seleccion.has(id) or usados.has(id):
			continue
		usados.append(id)
		var sellado := bool(seleccion[id])
		var peso := float(objeto.get("peso", 0.0))
		if sellado:
			peso = float(objeto.get("peso_sellado", peso))
		total += peso

	var diferencia := total - objetivo
	return {
		"peso": total,
		"objetivo": objetivo,
		"diferencia": diferencia,
		"equilibrado": objetivo > 0.0 and absf(diferencia) <= tolerancia,
	}


## La accesibilidad altera solo cómo se presenta la transformación. No toca la
## semilla cultural, el conjunto de objetos, el objetivo ni la solución física.
static func presentacion(reduccion_movimiento: bool) -> Dictionary:
	if reduccion_movimiento:
		return {
			"movimiento_arquitectura": "corte_fundido",
			"parpadeo_crt": 0.0,
			"oscilacion_balanza": 0.15,
			"transicion_piramide": "estado_discreto",
		}
	return {
		"movimiento_arquitectura": "desplazamiento_continuo",
		"parpadeo_crt": 0.12,
		"oscilacion_balanza": 1.0,
		"transicion_piramide": "ascenso_descenso",
	}


## Viste un espacio ya construido sin duplicar geometría, progreso o selección
## nocturna. Hasta que se libere el wiring central de #279, esta función permite
## probar el contrato Duat de forma aislada y conectarlo después con una llamada.
static func adaptar_espacio(
	espacio_base: Dictionary,
	jornada: Dictionary,
	objetos_conocidos: Array,
	semilla: int = 0,
	reduccion_movimiento: bool = false
) -> Dictionary:
	if espacio_base.is_empty():
		return {}
	var resultado := espacio_base.duplicate(true)
	if not habilitado(jornada):
		return resultado

	var familia := SuenoFamilias.de(SuenoFamilias.CONVERGENTE)
	if familia.is_empty():
		return resultado

	resultado["identidad_onirica"] = ID
	resultado["contorno"] = familia.get("contorno", PackedVector2Array())
	resultado["altura_contorno"] = float(familia.get("altura", 3.2))
	resultado["entrada"] = familia.get("entrada", Vector3.ZERO)
	resultado["duat_pesaje"] = preparar_pesaje(objetos_conocidos, semilla)
	resultado["presentacion_duat"] = presentacion(reduccion_movimiento)
	resultado["anomalias_oniricas"] = {
		"peso_arquitectura": true,
		"piramide_invertida": true,
		"balanza_monumental": not resultado["duat_pesaje"].is_empty(),
	}
	return resultado


static func malla_base() -> ArrayMesh:
	return SuenoFamilias.malla(SuenoFamilias.CONVERGENTE)


static func valida() -> bool:
	return (
		SemillasOniricas.clave(ID) == "semilla_onirica_duat"
		and SuenoFamilias.valida(SuenoFamilias.CONVERGENTE)
		and FUENTE_TV.begins_with("tv:")
	)


static func _objetos_validos(objetos_conocidos: Array) -> Array:
	var por_id := {}
	for bruto in objetos_conocidos:
		if typeof(bruto) != TYPE_DICTIONARY:
			continue
		var objeto: Dictionary = bruto
		var id := String(objeto.get("id", "")).strip_edges()
		var peso := float(objeto.get("peso", 0.0))
		if id.is_empty() or peso <= 0.0 or not bool(objeto.get("manipulado_hoy", false)):
			continue

		var copia := objeto.duplicate(true)
		copia["id"] = id
		copia["peso"] = peso
		if copia.has("peso_sellado"):
			copia["peso_sellado"] = maxf(0.0, float(copia["peso_sellado"]))
		por_id[id] = copia

	var ids: Array = por_id.keys()
	ids.sort()
	var resultado: Array = []
	for id in ids:
		resultado.append(por_id[id])
	return resultado
