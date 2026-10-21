## Selector determinista de habitaciones para el Hotel de los Olvidados (#2486).
##
## No guarda estado ni toca Partida/Jornada. La visita y la raíz llegan del
## host; con los mismos valores siempre devuelve la misma pareja, sin repetir
## habitación dentro de una visita. Entre visitas contiguas rota el inicio de
## la selección para evitar repetir la misma pareja cuando hay alternativas.
class_name SelectorHabitacionesHotel
extends RefCounted

const CATALOGO_HABITACIONES = preload("res://guion/hotel_olvidados/catalogo_habitaciones.gd")

const HABITACIONES_POR_VISITA := 2


static func _indice_shuffle(raiz: int, tamano: int) -> Array:
	var indices: Array = []
	for indice in range(tamano):
		indices.append(indice)

	var rng := Azar.generador(raiz, "sueno", [2475])
	for i in range(indices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = indices[i]
		indices[i] = indices[j]
		indices[j] = tmp
	return indices


static func seleccionar(raiz: int, visita: int, cantidad: int = HABITACIONES_POR_VISITA) -> Array:
	var catalogo: Array = CATALOGO_HABITACIONES.CATALOGO
	if catalogo.is_empty():
		return []

	var cuantos := clampi(cantidad, 0, catalogo.size())
	if cuantos == 0:
		return []

	var indices := _indice_shuffle(raiz, catalogo.size())

	# La permutación permanece fija para una raíz y la ventana avanza con cada
	# visita: si existen habitaciones alternativas, la pareja contigua cambia.
	var inicio := posmod(visita, catalogo.size())
	var seleccion := []
	for k in range(cuantos):
		var idx := (inicio + k) % catalogo.size()
		seleccion.append((catalogo[int(indices[idx])] as Dictionary).duplicate(true))
	return seleccion


static func indices_seleccionados(
	raiz: int, visita: int, cantidad: int = HABITACIONES_POR_VISITA
) -> Array:
	var catalogo: Array = CATALOGO_HABITACIONES.CATALOGO
	var cuantos := clampi(cantidad, 0, catalogo.size())
	if cuantos == 0:
		return []

	var indices := _indice_shuffle(raiz, catalogo.size())

	var inicio := posmod(visita, catalogo.size())
	var resultado := []
	for k in range(cuantos):
		var idx := (inicio + k) % catalogo.size()
		resultado.append(indices[idx])
	return resultado
