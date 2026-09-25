## Carga los expedientes desde datos/casos.json o su copia localizada compatible.
##
## Sustituye a [code]DataSeeder[/code] y a los repositorios JPA: el contenido
## ya no es código, así que escribir un caso nuevo no es recompilar nada.
##
## Las copias por idioma son deliberadamente conservadoras: solo se usan si
## conservan la misma estructura y los mismos valores no traducibles que el
## catálogo canónico. Una traducción atrasada nunca puede quitar un caso,
## cambiar una pista ni alterar una regla de juego; en ese caso se usa español.
class_name Contenido
extends RefCounted

const RUTA := "res://datos/casos.json"
const IDIOMA_CANONICO := "es"
const RUTA_ESTADO_LOCALES := "res://datos/catalogos.locales.json"
const CAMPOS_TRADUCIBLES := [
	"titulo",
	"descripcion",
	"contenido",
	"fraseGatillo",
	"nombre",
	"desenlace",
	"resumen",
	"requisito",
	"texto",
	"etiqueta",
	"secuelaUtil",
	"secuelaConfusion",
]

var casos: Array = []
var conceptos: Array = []


func cargar(ruta: String = "") -> bool:
	var seleccionada := ruta if not ruta.is_empty() else ruta_catalogo("casos")
	var crudo := _leer_json(seleccionada, true)
	if crudo.is_empty():
		return false
	casos = crudo.get("casos", [])
	conceptos = crudo.get("conceptos", [])
	_enteros()
	return true


## Resuelve una copia por idioma solo cuando es intercambiable con el canónico.
## [param locale] se puede fijar en pruebas; vacío usa el locale real de Godot.
static func ruta_catalogo(nombre: String, locale: String = "") -> String:
	var canonica := "res://datos/%s.json" % nombre
	var idioma := _idioma(locale)
	if idioma.is_empty() or idioma == IDIOMA_CANONICO:
		return canonica

	var candidata := "res://datos/%s.%s.json" % [nombre, idioma]
	if not FileAccess.file_exists(candidata) or not _catalogo_localizado_completo(nombre, idioma):
		return canonica

	var base := _leer_json(canonica, false)
	var localizada := _leer_json(candidata, false)
	if base.is_empty() or localizada.is_empty() or not _misma_estructura(base, localizada):
		push_warning(
			"Catálogo %s desincronizado para %s; se usa %s" % [nombre, idioma, IDIOMA_CANONICO]
		)
		return canonica
	return candidata


static func _catalogo_localizado_completo(nombre: String, idioma: String) -> bool:
	var estado := _leer_json(RUTA_ESTADO_LOCALES, false)
	if estado.is_empty():
		return false
	var catalogo = estado.get(nombre, {})
	return typeof(catalogo) == TYPE_DICTIONARY and bool(catalogo.get(idioma, false))


static func _idioma(locale: String) -> String:
	var valor := locale if not locale.is_empty() else TranslationServer.get_locale()
	valor = valor.strip_edges().to_lower().replace("-", "_")
	return valor.get_slice("_", 0)


## Compara forma y reglas, permitiendo que cambie únicamente el texto visible.
## Así una copia localizada no puede perder un caso, pista o flag por detrás.
static func _misma_estructura(base: Variant, localizada: Variant, campo: String = "") -> bool:
	if typeof(base) != typeof(localizada):
		return false
	if base is Dictionary:
		if base.size() != localizada.size():
			return false
		for clave in base:
			if not localizada.has(clave):
				return false
			if not _misma_estructura(base[clave], localizada[clave], String(clave)):
				return false
		return true
	if base is Array:
		if base.size() != localizada.size():
			return false
		for indice in range(base.size()):
			if not _misma_estructura(base[indice], localizada[indice], campo):
				return false
		return true
	if campo in CAMPOS_TRADUCIBLES:
		return true
	return base == localizada


static func _leer_json(ruta: String, avisar: bool) -> Dictionary:
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		if avisar:
			push_error("No se pudo abrir %s" % ruta)
		return {}
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(crudo) != TYPE_DICTIONARY:
		if avisar:
			push_error("%s no contiene un objeto JSON" % ruta)
		return {}
	return crudo


## JSON no distingue entero de decimal, así que todo número vuelve en coma
## flotante y un año se muestra como "1999.0". Ya había salido dos veces —en la
## barra de título del visor y en la racha de la Ventanilla— y las dos se
## arreglaron donde se veía. Se arregla aquí, que es por donde entra.
func _enteros() -> void:
	for caso in casos:
		if caso.get("anioSuceso") != null:
			caso["anioSuceso"] = int(caso["anioSuceso"])


## Los casos que cuentan para el final principal. El caso 8 está marcado como
## no principal en el contenido original.
func principales() -> Array:
	return casos.filter(func(c): return c.get("principal", true))


func caso(id: String) -> Dictionary:
	for c in casos:
		if c["id"] == id:
			return c
	return {}


## Los conceptos que el jugador ya conoce: los que tienen al menos una de sus
## pistas descubierta. Un concepto del que aún no se sabe nada no puede
## aparecer en el corcho ni presentarse en la Ventanilla.
func conceptos_desbloqueados(descubiertas: Array) -> Array:
	return conceptos.filter(
		func(c): return c.get("pistas", []).any(func(p): return descubiertas.has(p))
	)


## Quiénes pueden reclamar en la Ventanilla: personas y comités que el jugador
## ya conoce. Las empresas, lugares y documentos no se presentan a reclamar.
func reclamantes(descubiertas: Array) -> Array:
	return conceptos_desbloqueados(descubiertas).filter(
		func(c): return c["tipo"] in ["PERSONA", "COMITE"]
	)


## Las pistas cuya frase gatillo vive en un registro dado.
func pistas_de_registro(un_caso: Dictionary, registro_id: String) -> Array:
	return un_caso.get("pistas", []).filter(func(p): return p.get("registroOrigen") == registro_id)
