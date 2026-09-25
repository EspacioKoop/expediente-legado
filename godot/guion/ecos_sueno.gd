## Ecos del día en el sueño: la gente con la que has hablado vuelve de noche.
##
## En el sueño los sospechosos son siluetas sin cara a propósito (ver
## `Espacio3D`): a quien acusas no se le ve. Quien entra aquí es lo contrario,
## gente del barrio a la que has visto la cara esa misma mañana, y por eso
## conserva la suya. Dice una versión soñada de su voz, no una frase de su
## repertorio diurno.
##
## Como `GatoEcoSueno`, solo guarda lo observable del día en curso: a quién le
## has dado conversación. El día etiqueta la huella, así que una noche no hereda
## a nadie de jornadas viejas.
##
## Reparto por sala: cada sala de la noche trae a uno de los que has hablado
## hoy, rotando. Si hoy no has hablado con nadie, la última sala antes de
## despertar trae a uno igualmente, uno que no te conoce pero te ha visto
## pasar; las demás quedan vacías de ecos, porque un sueño lleno de
## desconocidos ya no es tu barrio. Las salas se cuentan por las que QUEDAN
## (`sueno_escenas` va perdiendo la de delante al cruzarla), que es lo único
## fijo: cuántas tiene la noche depende de las opciones del sueño.
class_name EcosSueno
extends RefCounted

const CLAVE := "ecos_sueno_hoy"
const VARIANTES := 3


static func registrar(jornada: Dictionary, id: String) -> bool:
	if DependientesTiendas.de(id).is_empty():
		return false
	var dia := int(jornada.get("dia", 1))
	var eco = jornada.get(CLAVE, {})
	if typeof(eco) != TYPE_DICTIONARY or int(eco.get("dia", -1)) != dia:
		eco = {"dia": dia, "personas": []}
	var personas: Array = eco.get("personas", [])
	if not personas.has(id):
		personas.append(id)
	eco["personas"] = personas
	jornada[CLAVE] = eco
	return true


## Con quién has hablado hoy, en el orden en que lo hiciste. Lo que no sea un
## dependiente conocido se ignora: una partida editada a mano no mete a nadie.
static func hablados_hoy(jornada: Dictionary) -> Array[String]:
	var salida: Array[String] = []
	var eco = jornada.get(CLAVE, {})
	if typeof(eco) != TYPE_DICTIONARY or int(eco.get("dia", -1)) != int(jornada.get("dia", 1)):
		return salida
	var personas = eco.get("personas", [])
	if typeof(personas) != TYPE_ARRAY:
		return salida
	for valor in personas:
		if typeof(valor) not in [TYPE_STRING, TYPE_STRING_NAME]:
			continue
		var id := String(valor)
		if not DependientesTiendas.de(id).is_empty() and not salida.has(id):
			salida.append(id)
	return salida


## Quién aparece en la sala de la que quedan [param quedan] por detrás (0 es
## la última de la noche) y qué dice. Vacío si en esa sala no hay eco.
static func de_sala(jornada: Dictionary, quedan: int) -> Dictionary:
	var dia := maxi(int(jornada.get("dia", 1)), 1)
	var hablados := hablados_hoy(jornada)
	var dependiente: Dictionary
	var clave := ""
	if not hablados.is_empty():
		dependiente = DependientesTiendas.de(hablados[quedan % hablados.size()])
		# La variante rota con el día y con la sala: la misma persona en dos
		# salas de la misma noche no repite.
		clave = "%s_SUENO_%d" % [dependiente["clave"], (dia + quedan - 1) % VARIANTES + 1]
	elif quedan == 0:
		var todos := DependientesTiendas.todos()
		dependiente = todos[(dia - 1) % todos.size()]
		clave = "%s_SUENO_EXTRANO" % dependiente["clave"]
	else:
		return {}
	return {"id": dependiente["id"], "dependiente": dependiente, "frase": clave}


## Todas las claves oníricas de [param dependiente], para las pruebas.
static func claves(dependiente: Dictionary) -> Array[String]:
	var base := String(dependiente["clave"])
	var salida: Array[String] = []
	for n in range(1, VARIANTES + 1):
		salida.append("%s_SUENO_%d" % [base, n])
	salida.append("%s_SUENO_EXTRANO" % base)
	return salida
