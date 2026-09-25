## Catálogo declarativo para reconstrucciones 3D basadas en documentos.
##
## Este módulo no decide qué ocurrió realmente. Solo convierte una reconstrucción
## catalogada en un plan de cámara si el folio de origen ya está disponible para
## el jugador. Los fragmentos son evidencia editorial y se validan contra
## casos.json mediante la regresión de #286.
class_name ReconstruccionDocumental3D
extends RefCounted

const RUTA := "res://datos/reconstrucciones_documentales.json"

const CAMARAS := {
	"general": {"camara": Vector3(0.0, 1.65, 4.2), "mira": Vector3(0.0, 1.35, 0.0)},
	"detalle": {"camara": Vector3(1.15, 1.35, 1.65), "mira": Vector3(0.0, 1.05, 0.0)},
	"fijo": {"camara": Vector3(-1.8, 1.55, 2.9), "mira": Vector3(0.0, 1.3, 0.0)},
	"cenital": {"camara": Vector3(0.0, 5.6, 0.1), "mira": Vector3(0.0, 0.0, 0.0)},
}


static func catalogo() -> Dictionary:
	var archivo := FileAccess.open(RUTA, FileAccess.READ)
	if archivo == null:
		return {}
	var datos = JSON.parse_string(archivo.get_as_text())
	return datos if typeof(datos) == TYPE_DICTIONARY else {}


static func para_registros(caso_id: String, registros_leidos: Array) -> Array:
	var disponibles: Array = []
	for reconstruccion in catalogo().get("reconstrucciones", []):
		if typeof(reconstruccion) != TYPE_DICTIONARY:
			continue
		if String(reconstruccion.get("caso", "")) != caso_id:
			continue
		if not registros_leidos.has(String(reconstruccion.get("registro", ""))):
			continue
		disponibles.append(reconstruccion.duplicate(true))
	return disponibles


static func planos_de(reconstruccion: Dictionary, reduccion_movimiento := false) -> Array:
	var planos: Array = []
	var titulo := String(reconstruccion.get("titulo", ""))
	var folio := String(reconstruccion.get("folio", ""))
	for indice in reconstruccion.get("planos", []).size():
		var fuente: Dictionary = reconstruccion["planos"][indice]
		var encuadre := String(fuente.get("encuadre", "fijo"))
		if reduccion_movimiento:
			encuadre = "fijo"
		var camara: Dictionary = CAMARAS.get(encuadre, CAMARAS["fijo"])
		(
			planos
			. append(
				{
					"tipo": "3d",
					"nombre":
					"%s_%d" % [String(reconstruccion.get("id", "reconstruccion")), indice],
					"camara": camara["camara"],
					"mira": camara["mira"],
					"segundos": maxf(0.2, float(fuente.get("duracion", 1.0))),
					"rotulo": "%s · %s" % [folio, titulo] if indice == 0 else "",
					"motivo": String(fuente.get("motivo", "")),
				}
			)
		)
	return planos
