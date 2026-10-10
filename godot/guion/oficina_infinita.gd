## Escenario de oficina infinita de 1998.
##
## Módulo aislado que propone un mutador nocturno reproducible para la fase
## de oficina, reutilizando MutadoresSueno cuando sea posible. No toca Partida
## ni SuenoFormas: su única responsabilidad es la presentación onírica sobre el
## espacio de oficina ya construido por el día.
##
## Flujo: el día construye el espacio de oficina. Cuando el jugador duerme,
## este módulo añade presentación onírica mediante un mutador seleccionado de
## MutadoresSueno.catalogo(), sin modificar la geometría ni el progreso.

class_name OficinaInfinita
extends RefCounted

## Mutadores nocturnos reutilizados de MutadoresSueno.
## No se duplican definiciones: se accede al catálogo existente.
const HUMEDAD := MutadoresSueno.HUMEDAD
const APAGONES := MutadoresSueno.APAGONES
const REPETICION := MutadoresSueno.REPETICION
const DESFASE := MutadoresSueno.DESFASE


## Candidatos disponibles para la fase oficina, derivados del estado del día.
## Sólo consulta hechos ya existentes; no materializa estado canónico.
static func candidatos(jornada: Dictionary) -> Array[String]:
	var resultado: Array[String] = []
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var clima := Clima.estado(dia)
	if Clima.precipitacion(clima):
		resultado.append(HUMEDAD)

	var eventos := MutadoresSueno._eventos_de(jornada)
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

	return resultado


## Seleccionar un mutador reproducible para la oficina infinita.
## La elección depende de la raíz de la partida, vuelta y día; nunca del
## orden de llamadas ni del reloj de la máquina.
static func seleccionar(jornada: Dictionary, raiz: int) -> Dictionary:
	var disponibles := candidatos(jornada)
	if disponibles.is_empty():
		return {}
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var vuelta := maxi(1, int(jornada.get("vuelta", 1)))
	var semilla := Azar.derivar(raiz, "oficina_infinita", [vuelta, dia, 1998])
	var indice := int(semilla % disponibles.size())
	return MutadoresSueno.definicion(disponibles[indice])


## Añadir presentación del mutador sobre una copia profunda del espacio de oficina.
## Las claves del espacio original —bloques, entrada, salida, objetivos, figuras—/
## quedan intactas y el llamador puede ignorar por completo esta metadata.
static func aplicar(
	espacio: Dictionary, mutador: Dictionary, reduccion_movimiento: bool = false
) -> Dictionary:
	var resultado := espacio.duplicate(true)
	var id := String(mutador.get("id", ""))
	if not MutadoresSueno.IDS.has(id):
		return resultado
	resultado["mutador_nocturno"] = _presentacion(id, reduccion_movimiento)
	return resultado


## Presentación visual del mutador sobre el espacio de oficina.
## Cada id tiene su perfil de afectación de luz, animación y particulas.
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
