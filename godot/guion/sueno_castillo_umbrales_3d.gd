## Ecos visuales entre alas del castillo onírico (#947).
##
## Reutiliza umbrales ya presentes en cada composición para insinuar otra ala al
## fondo. Solo añade presentación: no crea colisión, teletransporte ni estado de
## progreso, y la navegación continúa perteneciendo a la familia ANULAR.
class_name SuenoCastilloUmbrales3D
extends RefCounted

const GRUPO_UMBRAL := "castillo_umbral"
const ESCENA_PORTADA := preload("res://escenas/suenos/props_284/muro_torre_castillo.tscn")
const ESCENA_ARCADA := preload("res://escenas/suenos/props_284/arcada_claustro_castillo.tscn")
const ESCENA_TORRE := preload("res://escenas/suenos/props_284/torre_castillo.tscn")
const ESCENA_ESCALERA := preload("res://escenas/suenos/props_284/escalera_anular_castillo.tscn")
const ESCENA_ESTANTARTE := preload("res://escenas/suenos/props_284/estandarte_anular.tscn")

const SIGUIENTE := {
	"patio": "scriptorium",
	"scriptorium": "claustro_reflejado",
	"claustro_reflejado": "torre_capilla",
	"torre_capilla": "patio",
}


static func montar(arquitectura: Node3D, variante: String) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "EcosEntreAlas"
	arquitectura.add_child(raiz)

	var destino := String(SIGUIENTE.get(variante, "scriptorium"))
	for candidato in arquitectura.find_children("*", "Node3D", true, false):
		var umbral := candidato as Node3D
		if umbral == null or not umbral.is_in_group(GRUPO_UMBRAL):
			continue

		var eco := Node3D.new()
		eco.name = "EcoHacia_" + destino
		eco.position = Vector3(0.0, 0.0, 0.75)
		umbral.add_child(eco)
		_montar_motivo(eco, destino)
		_montar_luz(eco)

	return raiz


static func _montar_motivo(eco: Node3D, destino: String) -> void:
	match destino:
		"torre_capilla":
			_instanciar(eco, ESCENA_TORRE, "TorreLejana", Vector3(0.0, 0.0, -0.95), 0.34)
		"claustro_reflejado":
			_instanciar(eco, ESCENA_ARCADA, "ArcadaEcoA", Vector3(-0.75, 0.0, -0.75), 0.30)
			_instanciar(eco, ESCENA_ARCADA, "ArcadaEcoB", Vector3(0.75, 0.0, -0.75), 0.30)
		"patio":
			_instanciar(eco, ESCENA_PORTADA, "PortadaLejana", Vector3(0.0, 0.0, -0.9), 0.22)
		_:
			_instanciar(eco, ESCENA_ESCALERA, "EscaleraArchivoLejana", Vector3(0.0, 0.0, -0.75), 0.27)
			var estandarte := _instanciar(
				eco,
				ESCENA_ESTANTARTE,
				"EstandarteArchivoLejano",
				Vector3(0.55, 0.9, -0.8),
				0.36,
			)
			estandarte.rotation_degrees.y = -18.0


static func _instanciar(
	padre: Node3D,
	escena: PackedScene,
	nombre: String,
	posicion: Vector3,
	escala_uniforme: float,
) -> Node3D:
	var nodo := escena.instantiate() as Node3D
	nodo.name = nombre
	nodo.position = posicion
	nodo.scale = Vector3.ONE * escala_uniforme
	padre.add_child(nodo)
	return nodo


static func _montar_luz(eco: Node3D) -> void:
	var luz := OmniLight3D.new()
	luz.name = "LuzUmbral"
	luz.position = Vector3(0.0, 1.45, -0.35)
	luz.light_color = Color(0.46, 0.37, 0.28, 1.0)
	luz.light_energy = 0.18
	luz.omni_range = 3.0
	luz.shadow_enabled = false
	eco.add_child(luz)
