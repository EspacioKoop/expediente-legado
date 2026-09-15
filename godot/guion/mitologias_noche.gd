## Asignación estable de familias mitológicas a escenas de una noche (#435).
##
## `SemillasOniricas` sigue siendo la única fuente de selección. Este módulo no
## pesa, mezcla ni activa familias: solo evita que dos familias ya elegidas se
## materialicen encima una de otra en la misma sala.
class_name MitologiasNoche
extends RefCounted

const MAX_FAMILIAS_NOCHE := 2


## La posición devuelta por `SemillasOniricas` define el orden de aparición.
## Una familia seleccionada ocupa como máximo una escena y nunca se inventan
## huecos por encima de las escenas disponibles.
static func asignar(familias: Array, cantidad_escenas: int) -> Dictionary:
	var asignacion := {}
	var limite := mini(MAX_FAMILIAS_NOCHE, mini(familias.size(), maxi(cantidad_escenas, 0)))
	for indice in range(limite):
		var familia := String(familias[indice])
		if familia.is_empty() or asignacion.has(familia):
			continue
		asignacion[familia] = indice
	return asignacion


## `sueno_escenas` conserva la escena actual en posición 0 hasta que se pisa su
## salida. Por eso total - pendientes produce 0 en la primera, 1 en la segunda…
static func indice_escena_actual(cantidad_escenas: int, pendientes: int) -> int:
	if cantidad_escenas <= 0:
		return -1
	return clampi(cantidad_escenas - pendientes, 0, cantidad_escenas - 1)


static func corresponde_a_escena(
	familia: String,
	familias: Array,
	cantidad_escenas: int,
	pendientes: int,
) -> bool:
	var asignacion := asignar(familias, cantidad_escenas)
	if not asignacion.has(familia):
		return false
	return int(asignacion[familia]) == indice_escena_actual(cantidad_escenas, pendientes)
