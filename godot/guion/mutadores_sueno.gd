## Mutadores secundarios del sueño derivados de hechos de la vigilia (#1770).
##
## Este módulo es deliberadamente puro: no guarda flags, no selecciona salas y
## no altera rutas ni objetivos. Recibe la Jornada ya existente, propone como
## máximo un mutador reproducible y añade únicamente metadata de presentación a
## un espacio que otro sistema ya construyó.
class_name MutadoresSueno
extends RefCounted

const HUMEDAD := "humedad"
const APAGONES := "apagones"
const REPETICION := "repeticion"
const DESFASE := "desfase"

const IDS: Array[String] = [HUMEDAD, APAGONES, REPETICION, DESFASE]
const UMBRAL_ESTRES_DESFASE := 35.0

const CATALOGO := {
	HUMEDAD:
	{
		"id": HUMEDAD,
		"origen": "clima",
		"lectura": "superficies_humedas",
	},
	APAGONES:
	{
		"id": APAGONES,
		"origen": "incidencia",
		"lectura": "fuentes_locales",
	},
	REPETICION:
	{
		"id": REPETICION,
		"origen": "objetos_examinados",
		"lectura": "identidad_repetida",
	},
	DESFASE:
	{
		"id": DESFASE,
		"origen": "estres",
		"lectura": "respuesta_tardia",
	},
}


static func catalogo() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for id in IDS:
		resultado.append(definicion(id))
	return resultado


static func definicion(id: String) -> Dictionary:
	var crudo: Variant = CATALOGO.get(id, {})
	if not crudo is Dictionary:
		return {}
	return (crudo as Dictionary).duplicate(true)


## Los candidatos se derivan exclusivamente de estado que ya existe durante el
## día. Leer esta función no modifica Jornada: incluso el estrés se consulta en
## crudo para no materializar su estado canónico si aún no existía.
static func candidatos(jornada: Dictionary) -> Array[String]:
	var resultado: Array[String] = []
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var clima := Clima.estado(dia)
	if Clima.precipitacion(clima):
		resultado.append(HUMEDAD)

	var eventos := _eventos_de(jornada)
	if (
		eventos.has("casa_luz_reducida")
		or eventos.has("apagon")
		or eventos.has("apagones")
		or eventos.has("corte_luz")
	):
		resultado.append(APAGONES)

	var examinados: Variant = jornada.get("leido_hoy", [])
	if examinados is Array and not (examinados as Array).is_empty():
		resultado.append(REPETICION)

	if _estres_crudo(jornada) >= UMBRAL_ESTRES_DESFASE:
		resultado.append(DESFASE)
	return resultado


## Devuelve cero o un mutador. La elección depende de la raíz de la partida,
## vuelta y día; nunca del orden de llamadas ni del reloj de la máquina.
static func seleccionar(jornada: Dictionary, raiz: int) -> Dictionary:
	var disponibles := candidatos(jornada)
	if disponibles.is_empty():
		return {}
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var vuelta := maxi(1, int(jornada.get("vuelta", 1)))
	var semilla := Azar.derivar(raiz, "sueno", [vuelta, dia, 1770])
	var indice := int(semilla % disponibles.size())
	return definicion(disponibles[indice])


## Añade la presentación del mutador sobre una copia profunda. Las claves del
## espacio original —bloques, entrada, salida, objetivos, figuras...— quedan
## intactas y el llamador puede ignorar por completo esta metadata.
static func aplicar(
	espacio: Dictionary, mutador: Dictionary, reduccion_movimiento: bool = false
) -> Dictionary:
	var resultado := espacio.duplicate(true)
	var id := String(mutador.get("id", ""))
	if not IDS.has(id):
		return resultado
	resultado["mutador_nocturno"] = _presentacion(id, reduccion_movimiento)
	return resultado


static func _presentacion(id: String, reduccion_movimiento: bool) -> Dictionary:
	var base := {
		"id": id,
		"afecta_navegacion": false,
		"afecta_objetivo": false,
		"animacion": not reduccion_movimiento,
		"particulas": not reduccion_movimiento,
	}
	match id:
		HUMEDAD:
			base["charcos"] = true
			base["cauces_secundarios"] = true
			base["superficie_resbaladiza_solo_visual"] = true
		APAGONES:
			base["ciclo_luces"] = not reduccion_movimiento
			base["fuentes_locales"] = true
			base["ruta_siempre_legible"] = true
		REPETICION:
			base["repetir_elemento_secundario"] = true
			base["misma_identidad"] = true
			base["copias_sin_progreso"] = true
		DESFASE:
			base["retardo_ambiental"] = 0.12 if reduccion_movimiento else 0.40
			base["retarda_solo_presentacion"] = true
	return base


static func _eventos_de(jornada: Dictionary) -> Array[String]:
	var resultado: Array[String] = []
	var directos: Variant = jornada.get("eventos", [])
	if directos is Array:
		for valor in directos as Array:
			var id := String(valor).strip_edges()
			if not id.is_empty() and not resultado.has(id):
				resultado.append(id)

	var imprevistos: Variant = jornada.get("imprevistos", {})
	if imprevistos is Dictionary:
		var consecuencias: Variant = (imprevistos as Dictionary).get("consecuencias", [])
		if consecuencias is Array:
			for valor in consecuencias as Array:
				var id := String(valor).strip_edges()
				if not id.is_empty() and not resultado.has(id):
					resultado.append(id)
	return resultado


static func _estres_crudo(jornada: Dictionary) -> float:
	var crudo: Variant = jornada.get(Estres.CAMPO_JORNADA, {})
	if not crudo is Dictionary:
		return 0.0
	var valor: Variant = (crudo as Dictionary).get("valor", 0.0)
	if typeof(valor) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(valor)):
		return 0.0
	return clampf(float(valor), 0.0, Estres.VALOR_MAXIMO)
