## Identidad del protagonista: forma, límites y vocabulario narrativo.
##
## La persistencia pertenece a Partida. Este módulo solo define y normaliza la
## apariencia y el trasfondo para que movimiento, UI y narrativa consuman la
## misma forma sin crear una segunda autoridad de guardado.
class_name PerfilJugador
extends RefCounted

const VERSION := 1

const CUERPOS := {
	"delgado":
	{
		"ancho": 0.88,
		"fondo": 0.88,
		"hombros": 0.94,
		"cintura": 0.88,
		"extremidad": 0.90,
	},
	"medio":
	{
		"ancho": 1.00,
		"fondo": 1.00,
		"hombros": 1.00,
		"cintura": 1.00,
		"extremidad": 1.00,
	},
	"robusto":
	{
		"ancho": 1.10,
		"fondo": 1.08,
		"hombros": 1.08,
		"cintura": 1.10,
		"extremidad": 1.08,
	},
}

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

const PRENDAS := ["camisa", "jersey", "chaqueta"]
const PEINADOS := ["corto", "medio", "rapado", "recogido"]


static func nuevo() -> Dictionary:
	return {
		"version": VERSION,
		# `true` es el fallback compatible para partidas anteriores a #701. El
		# flujo explícito de Nueva partida lo cambia a `false` antes de guardar,
		# obligando solo a las partidas nuevas a completar su ficha inicial.
		"configurado": true,
		"apariencia":
		{
			"cuerpo": "medio",
			# Es visual a propósito: la colisión del caminante sigue siendo la
			# misma para que crear un avatar no cambie qué puertas puede cruzar.
			"altura": 1.0,
			"hombros": 1.0,
			"cintura": 1.0,
			"piel": "#c9916b",
			"cabello": "#30251f",
			"peinado": "corto",
			"prenda": "camisa",
			"ropa": "#59616b",
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
		var cuerpo := String(apariencia.get("cuerpo", base["apariencia"]["cuerpo"]))
		if CUERPOS.has(cuerpo):
			base["apariencia"]["cuerpo"] = cuerpo
		base["apariencia"]["altura"] = clampf(float(apariencia.get("altura", 1.0)), 0.92, 1.08)
		base["apariencia"]["hombros"] = clampf(float(apariencia.get("hombros", 1.0)), 0.88, 1.12)
		base["apariencia"]["cintura"] = clampf(float(apariencia.get("cintura", 1.0)), 0.88, 1.12)
		for clave in ["piel", "cabello", "ropa"]:
			var color := String(apariencia.get(clave, base["apariencia"][clave]))
			if Color.from_string(color, Color.TRANSPARENT) != Color.TRANSPARENT:
				base["apariencia"][clave] = color
		var peinado := String(apariencia.get("peinado", base["apariencia"]["peinado"]))
		if peinado in PEINADOS:
			base["apariencia"]["peinado"] = peinado
		var prenda := String(apariencia.get("prenda", base["apariencia"]["prenda"]))
		if prenda in PRENDAS:
			base["apariencia"]["prenda"] = prenda
	var trasfondo := String(valor.get("trasfondo", base["trasfondo"]))
	if not trasfondo_por_id(trasfondo).is_empty():
		base["trasfondo"] = trasfondo
	return base


static func esta_configurado(perfil: Dictionary) -> bool:
	return bool(completar(perfil)["configurado"])


static func perfil_cuerpo(id: String) -> Dictionary:
	return Dictionary(CUERPOS.get(id, CUERPOS["medio"])).duplicate(true)


static func trasfondo_por_id(id: String) -> Dictionary:
	for trasfondo in TRASFONDOS:
		if String(trasfondo["id"]) == id:
			return Dictionary(trasfondo).duplicate(true)
	return {}


static func etiquetas(perfil: Dictionary) -> Array:
	var normalizado := completar(perfil)
	var trasfondo := trasfondo_por_id(String(normalizado["trasfondo"]))
	return Array(trasfondo.get("etiquetas", [])).duplicate()
