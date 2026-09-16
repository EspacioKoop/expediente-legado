## Presentación 3D del castillo onírico (#284).
##
## La navegación sigue perteneciendo a la familia ANULAR: esta capa solo viste
## el hueco interior con el patio medieval original de #587 y añade la anomalía
## sonora. No crea colisión paralela ni cambia entrada, salida o progreso.
class_name SuenoCastillo3D
extends RefCounted

const ESCENA_PATIO := preload("res://escenas/suenos/props_284/patio_castillo_onirico.tscn")


static func montar(mundo: Node3D, espacio: Dictionary) -> Node3D:
	if mundo == null or String(espacio.get("identidad_onirica", "")) != SuenoCastillo.ID:
		return null

	var presentacion := Node3D.new()
	presentacion.name = "PresentacionCastillo284"
	mundo.add_child(presentacion)

	# El patio ocupa el vacío central del anillo: se ve como arquitectura
	# imposible al otro lado del recorrido, pero no suplanta la malla/colisión
	# derivada del contorno ANULAR.
	var patio := ESCENA_PATIO.instantiate() as Node3D
	patio.name = "PatioMedieval"
	presentacion.add_child(patio)

	# La fuente no tiene campana visible. La posición alta y central hace que el
	# sonido pertenezca al patio completo en lugar de delatar un objeto emisor.
	var campanas := AudioStreamPlayer3D.new()
	campanas.name = "CampanasSinFuente"
	campanas.stream = SuenoCastilloAudio.campanadas()
	campanas.position = Vector3(0.0, 5.5, 0.0)
	campanas.volume_db = -14.0
	campanas.unit_size = 7.0
	campanas.max_distance = 52.0
	presentacion.add_child(campanas)
	campanas.play()

	return presentacion
