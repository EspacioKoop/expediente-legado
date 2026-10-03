## Presentación cultural del Arconte de Umbral sobre runtime CONTROLADOR.
##
## Implementa la lectura visual basada en planos superpuestos y copias imperfectas,
## distinguiendo marca, zona activa y recuperación sin duplicar la mecánica.
class_name JuicioCombateArconte3D
extends RefCounted

const CONTROLADOR = preload("res://guion/juicio_combate_controlador_3d.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")


static func montar_zonas(anfitrion: Node3D, cantidad: int = 2) -> Array:
	var zonas := CONTROLADOR.montar_zonas(anfitrion, cantidad)
	for zona_variant in zonas:
		var zona := zona_variant as MeshInstance3D
		if zona == null:
			continue

		# El Arconte se manifiesta como planos superpuestos (copias imperfectas)
		# Añadimos un desfase visual leve para crear el efecto de "umbrales"
		var copia := zona.duplicate()
		copia.name = zona.name + "_copia"
		copia.position += Vector3(0.05, 0.01, 0.05)
		copia.material_override = FEEDBACK.material(Color(0.8, 0.8, 1.0, 0.2), true)
		anfitrion.add_child(copia)
	return zonas


static func avanzar(
	unidad: Dictionary,
	delta: float,
	posicion_rival: Vector3,
	posicion_jugador: Vector3,
	zonas: Array,
	zonas_activas: int = 0,
	queda_salida_valida: bool = true,
) -> Dictionary:
	var resultado := CONTROLADOR.avanzar(
		unidad, delta, posicion_rival, posicion_jugador, zonas, zonas_activas, queda_salida_valida
	)
	var nueva: Dictionary = resultado["unidad"]
	var estado := String(nueva.get("estado", ""))

	_actualizar_estetica_umbral(zonas, nueva, estado)

	return resultado


static func _actualizar_estetica_umbral(zonas: Array, unidad: Dictionary, estado: String) -> void:
	var indice := clampi(int(unidad.get("_zona_indice", 0)), 0, zonas.size() - 1)
	if indice < 0 or indice >= zonas.size():
		return

	var zona := zonas[indice] as MeshInstance3D
	if zona == null:
		return

	# Estado MARCAR_ZONA: Distinguible del sector activo (Luz tenue/pulso)
	if estado == ARQUETIPOS.MARCAR_ZONA:
		zona.material_override = FEEDBACK.material(Color(0.4, 0.6, 1.0, 0.4), true)
	# Estado ACTIVAR_ZONA: Conserva geometría pero con intensidad de autoridad
	elif estado == ARQUETIPOS.ACTIVAR_ZONA:
		zona.material_override = FEEDBACK.material(Color(1.0, 1.0, 1.0, 0.8), true)
	# Estado RECUPERAR: Apaga autoridad espacial
	elif estado == ARQUETIPOS.RECUPERAR:
		zona.visible = false
	else:
		# No interferimos con la visibilidad gestionada por CONTROLADOR si no es RECUPERAR
		pass


static func presentacion(unidad: Dictionary, reduccion_movimiento: bool) -> Dictionary:
	# Conserva la misma geometría lógica del runtime
	return CONTROLADOR.presentacion(unidad, reduccion_movimiento)
