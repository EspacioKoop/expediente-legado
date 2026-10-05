## Selector determinista de habitaciones para el Hotel de los Olvidados (#2486).
##
## No guarda estado ni toca Partida/Jornada. La visita y la raíz llegan del
## host; con los mismos valores siempre devuelve la misma pareja, sin repetir
## habitación dentro de una visita.
class_name SelectorHabitacionesHotel
extends RefCounted

const CATALOGO_HABITACIONES = preload("res://guion/hotel_olvidados/catalogo_habitaciones.gd")

const HABITACIONES_POR_VISITA := 2


static func seleccionar(raiz: int, visita: int, cantidad: int = HABITACIONES_POR_VISITA) -> Array:
	var catalogo: Array = CATALOGO_HABITACIONES.CATALOGO
	if catalogo.is_empty():
		return []

	var cuantos := clampi(cantidad, 0, catalogo.size())
	if cuantos == 0:
		return []

	var indices: Array = []
	for indice in range(catalogo.size()):
		indices.append(indice)

	var rng := Azar.generador(raiz, "sueno", [maxi(0, visita), 2475])
	for i in range(indices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = indices[i]
		indices[i] = indices[j]
		indices[j] = tmp

	var seleccion := []
	for indice in indices.slice(0, cuantos):
		seleccion.append((catalogo[int(indice)] as Dictionary).duplicate(true))
	return seleccion


static func indices_seleccionados(
	raiz: int, visita: int, cantidad: int = HABITACIONES_POR_VISITA
) -> Array:
	var catalogo: Array = CATALOGO_HABITACIONES.CATALOGO
	var cuantos := clampi(cantidad, 0, catalogo.size())
	if cuantos == 0:
		return []

	var indices: Array = []
	for indice in range(catalogo.size()):
		indices.append(indice)

	var rng := Azar.generador(raiz, "sueno", [maxi(0, visita), 2475])
	for i in range(indices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = indices[i]
		indices[i] = indices[j]
		indices[j] = tmp

	return indices.slice(0, cuantos)
