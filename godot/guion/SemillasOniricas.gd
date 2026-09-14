## Gestión de semillas oníricas: activación de familias de sueño por interacciones fuera de la oficina.
## Implementa el contrato descrito en el issue #442.
##
## La semilla se activa mediante interacciones voluntarias con fuentes externas
## (ROM/TV/póster/libro/juguete/cartel, etc.). Cada fuente distinta aumenta la
## intensidad del mito hasta un límite. La activación es idempotente por fuente.
## Al comenzar una nueva jornada, se reinicia el estado (según política #435).
##
## Uso:
##   SemillasOniricas.activar_semilla_onirica("gilgamesh", "ROM_GBC", 1)
##   var activas = SemillasOniricas.semillas_oniricas_hoy
##   # En la generación del sueño, consultar activas para pesar familias.

class_name SemillasOniricas extends RefCounted

# Índices de mito válidos (cerrados/catalogados). Se pueden ampliar.
const MITOS_VALIDOS := [
	"gilgamesh",
	"minotauro",
	# Añadir más según se definan en el diseño.
]

# Intensidad máxima por mito (suma de contribuciones de fuentes distintas).
const INTENSIDAD_MAX := 3

# Mapeo de mito a contenido onírico de ejemplo (para demostración).
# En un juego real, esto vendría de datos externos o diseño.
const MITO_CONTENIDO := {	"gilgamesh": {		"frases": ["¿Quién vigila al vigilante?", "La eternidad es una carga"],		"figuras": [{"nombre": "Gilgamesh", "acusado": false}]	},	"minotauro": {		"frases": ["El laberinto no tiene salida", "El rugido resuena en la piedra"],		"figuras": [{"nombre": "Minotauro", "acusado": false}]	}	# Añadir más mitos según se definan.}
# Estado del día actual: diccionario vacío al inicio.
# Formato: { mito_id: { intensidad: int, fuentes: Array[String], activada_en: int (día) } }
var semillas_oniricas_hoy := {}
# Día al que pertenece el estado actual.
var _dia_actual := 0

func _init() -> void:
	pass

# Reinicia el estado para un nuevo día. Llamar al despertar.
static func reiniciar_dia() -> void:
	SemillasOniricas._get_instancia()._reiniciar_dia_interno()

# Activa una semilla de mito mediante una fuente.
# id_mito: identificador del mito (debe estar en MITOS_VALIDOS).
# fuente: descripción de la fuente interactuada (ej. "ROM_GBC", "TV_anuncio").
# intensidad: cantidad a agregar (por defecto 1). Se ignora si la fuente ya contributed.
static func activar_semilla_onirica(id_mito: String, fuente: String, intensidad: int = 1) -> void:
	var instancia := SemillasOniricas._get_instancia()
	instancia._activar_interno(id_mito, fuente, intensidad)

# Devuelve el diccionario completo de semillas activas hoy (solo lectura).
static func obtener_semillas() -> Dictionary:
	return SemillasOniricas._get_instancia().semillas_oniricas_hoy.duplicate()

# --- Implementación interna ---

func _reiniciar_dia_interno() -> void:
	var instancia := SemillasOniricas._get_instancia()
	instancia.semillas_oniricas_hoy = {}
	instancia._dia_actual = 0

func _activar_interno(id_mito: String, fuente: String, intensidad: int) -> void:
	# Actualizar día si cambió (obtener día actual de la jornada).
	var dia_actual := Jornada.obtener_dia_actual()  # Necesitamos agregar esta función o leer desde partida.
	if dia_actual != _dia_actual:
		_reiniciar_dia_interno()
		_dia_actual = dia_actual

	# Validar mito.
	if not MITOS_VALIDOS.has(id_mito):
		push_warning("SemillasOniricas: mito no válido: %s" % id_mito)
		return

	# Inicializar entrada si no existe.
	if not semillas_oniricas_hoy.has(id_mito):
		semillas_oniricas_hoy[id_mito] = {
			"intensidad": 0,
			"fuentes": [],
			"activada_en": _dia_actual
		}

	var entrada := semillas_oniricas_hoy[id_mito]
	# Si la fuente ya contribuyó hoy, no hacer nada (idempotente).
	if fuente in entrada["fuentes"]:
		return

	# Añadir fuente y aumentar intensidad, respetando límite.
	entrada["fuentes"].append(fuente)
	entrada["intensidad"] = min(entrada["intensidad"] + intensidad, INTENSIDAD_MAX)
	# activada_en se mantiene como el día de primera activación.

# Obtener instancia singleton (autoload-like).
static func _get_instancia() -> SemillasOniricas:
	if not _instancia:
		_instancia = SemillasOniricas.new()
	return _instancia

static var _instancia := null

# Función simulada para obtener día actual desde Jornada (por implementar).
# En realidad, deberíamos leer la jornada desde Partida.estado o similar.
# Por ahora, devolvemos 0 para no romper; se debe reemplazar.
static func Jornada.obtener_dia_actual() -> int:
	# TODO: leer día actual de la partida/jornada.
	return 0
