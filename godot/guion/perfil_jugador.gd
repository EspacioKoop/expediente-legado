## Identidad del protagonista: forma, límites y vocabulario narrativo.
##
## La persistencia pertenece a Partida. Este módulo solo define y normaliza la
## apariencia y el trasfondo para que movimiento, UI y narrativa consuman la
## misma forma sin crear una segunda autoridad de guardado.
class_name PerfilJugador
extends RefCounted

const VERSION := 1

## Los cuerpos entre los que se elige: avatares Rocketbox (MIT) que no usa
## nadie más del juego, para que el protagonista no se cruce consigo mismo en
## la oficina. Cada uno trae su cara, su pelo y su ropa de serie: por eso la
## ficha elige un cuerpo entero en vez de deformar un maniquí, que es lo que
## hacía antes y lo que dejaba al protagonista peor que cualquier NPC.
## `nombre` es clave de textos.csv.
const AVATARES := [
	{"id": "rocketbox/male_adult_11", "nombre": "PERSONAJE_AVATAR_CAMISA_OSCURA"},
	{"id": "rocketbox/female_adult_07", "nombre": "PERSONAJE_AVATAR_CHAQUETA_MARRON"},
	{"id": "rocketbox/male_adult_06", "nombre": "PERSONAJE_AVATAR_CAMISETA_ROJA"},
	{"id": "rocketbox/female_adult_04", "nombre": "PERSONAJE_AVATAR_CAZADORA_CUERO"},
	{"id": "rocketbox/male_adult_12", "nombre": "PERSONAJE_AVATAR_CAZADORA_VAQUERA"},
	{"id": "rocketbox/female_adult_13", "nombre": "PERSONAJE_AVATAR_CHALECO_GRIS"},
]

## Los trasfondos son pasado, no profesión actual ni alineamiento. Las etiquetas
## son vocabulario narrativo para futuros diálogos, recuerdos, sueños u objetos;
## no conceden por sí solas pistas, dinero, acciones ni una decisión óptima.
## Nombre y descripción son claves de textos.csv: se traducen al mostrarse.
const TRASFONDOS := [
	{
		"id": "auxiliar_administrativo",
		"nombre": "TRASFONDO_AUXILIAR",
		"descripcion": "TRASFONDO_AUXILIAR_DESCRIPCION",
		"etiquetas": ["oficina", "papel", "burocracia"],
	},
	{
		"id": "almacen_fabrica",
		"nombre": "TRASFONDO_ALMACEN",
		"descripcion": "TRASFONDO_ALMACEN_DESCRIPCION",
		"etiquetas": ["trabajo_manual", "almacen", "turnos"],
	},
	{
		"id": "informatica_autodidacta",
		"nombre": "TRASFONDO_INFORMATICA",
		"descripcion": "TRASFONDO_INFORMATICA_DESCRIPCION",
		"etiquetas": ["tecnica", "ordenadores", "autodidacta"],
	},
	{
		"id": "estudiante_nocturno",
		"nombre": "TRASFONDO_ESTUDIANTE",
		"descripcion": "TRASFONDO_ESTUDIANTE_DESCRIPCION",
		"etiquetas": ["estudio", "biblioteca", "nocturno"],
	},
	{
		"id": "cuidados_familiares",
		"nombre": "TRASFONDO_CUIDADOS",
		"descripcion": "TRASFONDO_CUIDADOS_DESCRIPCION",
		"etiquetas": ["cuidados", "casa", "responsabilidad"],
	},
	{
		"id": "recien_llegado",
		"nombre": "TRASFONDO_RECIEN_LLEGADO",
		"descripcion": "TRASFONDO_RECIEN_LLEGADO_DESCRIPCION",
		"etiquetas": ["calle", "transporte", "forastero"],
	},
]


static func nuevo() -> Dictionary:
	return {
		"version": VERSION,
		# `true` es el fallback compatible para partidas anteriores a #701. El
		# flujo explícito de Nueva partida lo cambia a `false` antes de guardar,
		# obligando solo a las partidas nuevas a completar su ficha inicial.
		"configurado": true,
		"apariencia":
		{
			"avatar": String(AVATARES[0]["id"]),
			# Es visual a propósito: la colisión del caminante sigue siendo la
			# misma para que crear un avatar no cambie qué puertas puede cruzar.
			"altura": 1.0,
		},
		"trasfondo": "auxiliar_administrativo",
	}


static func completar(valor) -> Dictionary:
	var base := nuevo()
	if typeof(valor) != TYPE_DICTIONARY:
		return base
	if typeof(valor.get("configurado", true)) == TYPE_BOOL:
		base["configurado"] = valor.get("configurado", true)
	var apariencia = valor.get("apariencia", {})
	if typeof(apariencia) == TYPE_DICTIONARY:
		# Una ficha de antes de los avatares (complexión, piel, peinado...) no
		# tiene `avatar`: se queda con el primero y conserva su altura.
		var avatar := String(apariencia.get("avatar", ""))
		if not avatar_por_id(avatar).is_empty():
			base["apariencia"]["avatar"] = avatar
		base["apariencia"]["altura"] = clampf(float(apariencia.get("altura", 1.0)), 0.92, 1.08)
	var trasfondo := String(valor.get("trasfondo", base["trasfondo"]))
	if not trasfondo_por_id(trasfondo).is_empty():
		base["trasfondo"] = trasfondo
	return base


static func esta_configurado(perfil: Dictionary) -> bool:
	return bool(completar(perfil)["configurado"])


static func avatar_por_id(id: String) -> Dictionary:
	for avatar in AVATARES:
		if String(avatar["id"]) == id:
			return Dictionary(avatar).duplicate(true)
	return {}


static func trasfondo_por_id(id: String) -> Dictionary:
	for trasfondo in TRASFONDOS:
		if String(trasfondo["id"]) == id:
			return Dictionary(trasfondo).duplicate(true)
	return {}


static func etiquetas(perfil: Dictionary) -> Array:
	var normalizado := completar(perfil)
	var trasfondo := trasfondo_por_id(String(normalizado["trasfondo"]))
	return Array(trasfondo.get("etiquetas", [])).duplicate()
