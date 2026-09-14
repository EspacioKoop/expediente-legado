## Gestión de semillas oníricas: activación de familias de sueño por interacciones fuera de la oficina.
## Implementa el contrato descrito en el issue #442.
##
## La semilla se activa mediante interacciones voluntarias con fuentes externas
## (ROM/TV/póster/libro/juguete/cartel, etc.). Cada fuente distinta aumenta la
## intensidad del mito hasta un límite. La activación es idempotente por fuente.
##
## Uso:
##   SemillasOniricas.activar_semilla_onirica("gilgamesh", "ROM_GBC", 1)
##   var activas = SemillasOniricas.obtener_semillas()

class_name SemillasOniricas
extends RefCounted

const MITOS_VALIDOS := [
	"gilgamesh",
	"minotauro",
]

const INTENSIDAD_MAX := 3

const MITO_CONTENIDO := {
	"gilgamesh": {
		"frases": ["¿Quién vigila al vigilante?", "La eternidad es una carga"],
		"figuras": [{"nombre": "Gilgamesh", "acusado": false}],
	},
	"minotauro": {
		"frases": ["El laberinto no tiene salida", "El rugido resuena en la piedra"],
		"figuras": [{"nombre": "Minotauro", "acusado": false}],
	},
}

# Estado efímero del singleton. El wiring con la jornada pertenece al PR de
# semillas; esta clase no inventa una API de Jornada que no existe.
var semillas_oniricas_hoy: Dictionary = {}
var _dia_actual := 0

static var _instancia: SemillasOniricas = null


static func reiniciar_dia() -> void:
	_get_instancia()._reiniciar_dia_interno()


static func activar_semilla_onirica(id_mito: String, fuente: String, intensidad: int = 1) -> void:
	_get_instancia()._activar_interno(id_mito, fuente, intensidad)


static func obtener_semillas() -> Dictionary:
	return _get_instancia().semillas_oniricas_hoy.duplicate(true)


static func obtener_contenido_onirico() -> Dictionary:
	var instancia := _get_instancia()
	var frases: Array[String] = []
	var figuras: Array[Dictionary] = []
	for mito_id in instancia.semillas_oniricas_hoy.keys():
		var datos: Dictionary = instancia.semillas_oniricas_hoy[mito_id]
		if int(datos.get("intensidad", 0)) <= 0:
			continue
		var contenido: Dictionary = MITO_CONTENIDO.get(mito_id, {})
		for frase in contenido.get("frases", []):
			var texto := String(frase)
			if not frases.has(texto):
				frases.append(texto)
		for figura in contenido.get("figuras", []):
			var figura_dict: Dictionary = figura
			var repetida := false
			for existente in figuras:
				if existente.get("nombre", "") == figura_dict.get("nombre", ""):
					repetida = true
					break
			if not repetida:
				figuras.append(figura_dict.duplicate(true))
	return {"frases": frases, "figuras": figuras}


func _reiniciar_dia_interno() -> void:
	semillas_oniricas_hoy.clear()
	_dia_actual = 0


func _activar_interno(id_mito: String, fuente: String, intensidad: int) -> void:
	if not MITOS_VALIDOS.has(id_mito):
		push_warning("SemillasOniricas: mito no válido: %s" % id_mito)
		return
	if fuente.is_empty():
		return

	if not semillas_oniricas_hoy.has(id_mito):
		semillas_oniricas_hoy[id_mito] = {
			"intensidad": 0,
			"fuentes": [],
			"activada_en": _dia_actual,
		}

	var entrada: Dictionary = semillas_oniricas_hoy[id_mito]
	var fuentes: Array = entrada["fuentes"]
	if fuentes.has(fuente):
		return

	fuentes.append(fuente)
	entrada["intensidad"] = mini(int(entrada["intensidad"]) + maxi(intensidad, 0), INTENSIDAD_MAX)


static func _get_instancia() -> SemillasOniricas:
	if _instancia == null:
		_instancia = SemillasOniricas.new()
	return _instancia
