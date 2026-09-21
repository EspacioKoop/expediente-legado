## Estado pasivo de atención documental para #961.
##
## No existe una barra visible ni una habilidad que bloquee progreso. La capa del
## visor registra gestos deliberados ya disponibles y este contrato conserva
## únicamente hechos del día actual dentro de Jornada. Repetir el mismo gesto
## sobre el mismo documento es idempotente.
class_name Meticulosidad
extends RefCounted

const CAMPO_JORNADA := "meticulosidad_hoy"
const PUNTOS_MAX := 12
const EVENTOS_VALIDOS := {
	"lectura_completa": 2,
	"relectura": 1,
	"marcador": 1,
	"relacion": 2,
}
const MOTIVOS_VALIDOS := ["fecha", "margen", "folio", "relacion", "relectura"]


static func registrar(
	jornada: Dictionary,
	documento_id: String,
	evento: String,
	motivo: String,
) -> bool:
	var id := documento_id.strip_edges()
	var motivo_limpio := motivo.strip_edges()
	if id.is_empty() or not EVENTOS_VALIDOS.has(evento) or not MOTIVOS_VALIDOS.has(motivo_limpio):
		return false

	var estado := _normalizar_dia(jornada)
	var documentos: Dictionary = estado["documentos"]
	var ficha: Dictionary = documentos.get(id, {"eventos": []})
	var eventos: Array = ficha.get("eventos", [])
	if eventos.has(evento):
		return false

	eventos.append(evento)
	ficha["eventos"] = eventos
	documentos[id] = ficha
	estado["puntos"] = mini(
		PUNTOS_MAX,
		int(estado.get("puntos", 0)) + int(EVENTOS_VALIDOS[evento]),
	)

	var motivos: Dictionary = estado["motivos"]
	motivos[motivo_limpio] = int(motivos.get(motivo_limpio, 0)) + int(EVENTOS_VALIDOS[evento])
	return true


static func puntos(jornada: Dictionary) -> int:
	return int(_normalizar_dia(jornada).get("puntos", 0))


## Motivos que pueden reaparecer esa noche. No decide objetivos ni altera la
## selección de escenas: solo devuelve una lista estable para dressing visual.
static func motivos_oniricos(jornada: Dictionary, maximo: int = 3) -> Array[String]:
	var motivos: Dictionary = _normalizar_dia(jornada).get("motivos", {})
	var ordenados: Array[String] = []
	for motivo in motivos:
		ordenados.append(String(motivo))
	ordenados.sort_custom(
		func(a: String, b: String) -> bool:
			var puntos_a := int(motivos.get(a, 0))
			var puntos_b := int(motivos.get(b, 0))
			if puntos_a == puntos_b:
				return a < b
			return puntos_a > puntos_b
	)
	if maximo < ordenados.size():
		ordenados.resize(maxi(0, maximo))
	return ordenados


static func _normalizar_dia(jornada: Dictionary) -> Dictionary:
	var dia := int(jornada.get("dia", 0))
	var vuelta := int(jornada.get("vuelta", 1))
	var crudo: Variant = jornada.get(CAMPO_JORNADA, {})
	if (
		not crudo is Dictionary
		or int((crudo as Dictionary).get("dia", -1)) != dia
		or int((crudo as Dictionary).get("vuelta", -1)) != vuelta
	):
		jornada[CAMPO_JORNADA] = {
			"dia": dia,
			"vuelta": vuelta,
			"puntos": 0,
			"documentos": {},
			"motivos": {},
		}
		return jornada[CAMPO_JORNADA]

	var estado := crudo as Dictionary
	if not estado.get("documentos", {}) is Dictionary:
		estado["documentos"] = {}
	if not estado.get("motivos", {}) is Dictionary:
		estado["motivos"] = {}
	estado["puntos"] = clampi(int(estado.get("puntos", 0)), 0, PUNTOS_MAX)
	return estado
