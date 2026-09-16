## Identidad persistente del protagonista.
##
## Se mantiene separada del controlador de movimiento: apariencia y pasado no
## cambian cápsula, velocidad ni navegación. El cuerpo 3D consume esta forma y
## los sistemas narrativos pueden consultar las etiquetas del trasfondo sin
## convertirlo en una clase con una respuesta correcta.
class_name PerfilJugador
extends RefCounted

const RUTA := "user://perfil_jugador.json"
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
const TRASFONDOS := [
	{
		"id": "auxiliar_administrativo",
		"nombre": "Auxiliar administrativo",
		"descripcion":
		"Años de ventanillas, fotocopias y contratos temporales. Sabes cómo suena una oficina antes de saber quién manda en ella.",
		"etiquetas": ["oficina", "papel", "burocracia"],
	},
	{
		"id": "almacen_fabrica",
		"nombre": "Almacén y fábrica",
		"descripcion":
		"Turnos, inventarios, muelles de carga y encargados con prisa. Estás acostumbrado a leer un espacio por cómo trabaja la gente dentro.",
		"etiquetas": ["trabajo_manual", "almacen", "turnos"],
	},
	{
		"id": "informatica_autodidacta",
		"nombre": "Informática autodidacta",
		"descripcion":
		"Aprendiste con manuales, disquetes prestados y ordenadores que nadie quería tocar. Entiendes sistemas por insistencia, no por título.",
		"etiquetas": ["tecnica", "ordenadores", "autodidacta"],
	},
	{
		"id": "estudiante_nocturno",
		"nombre": "Estudiante nocturno",
		"descripcion":
		"Trabajas de día y estudias cuando puedes. Tienes práctica reuniendo fragmentos, tomando notas y funcionando con horarios poco razonables.",
		"etiquetas": ["estudio", "biblioteca", "nocturno"],
	},
	{
		"id": "cuidados_familiares",
		"nombre": "Cuidados familiares",
		"descripcion":
		"Antes de SIGA ya organizabas citas, compras, papeles y días alrededor de otra persona. Conoces la logística invisible de sostener una casa.",
		"etiquetas": ["cuidados", "casa", "responsabilidad"],
	},
	{
		"id": "recien_llegado",
		"nombre": "Recién llegado a la ciudad",
		"descripcion":
		"Todavía estás aprendiendo barrios, líneas, horarios y costumbres. Miras lugares cotidianos con la atención de quien aún no los da por hechos.",
		"etiquetas": ["calle", "transporte", "forastero"],
	},
]

const PRENDAS := ["camisa", "jersey", "chaqueta"]
const PEINADOS := ["corto", "medio", "rapado", "recogido"]


static func nuevo() -> Dictionary:
	return {
		"version": VERSION,
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


static func cargar(ruta: String = RUTA) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return nuevo()
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		return nuevo()
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	return completar(crudo)


static func guardar(perfil: Dictionary, ruta: String = RUTA) -> bool:
	var normalizado := completar(perfil)
	var temporal := ruta + ".nuevo"
	var fichero := FileAccess.open(temporal, FileAccess.WRITE)
	if fichero == null:
		return false
	fichero.store_string(JSON.stringify(normalizado, "\t"))
	fichero.close()
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporal), ProjectSettings.globalize_path(ruta)
	)
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporal))
		return false
	return true


static func reiniciar(ruta: String = RUTA) -> bool:
	if FileAccess.file_exists(ruta):
		return DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta)) == OK
	return true


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
