## Estado de una bandeja de archivado (#157).
##
## Separa la sesión de juego de la escena 3D. La pantalla puede transportar una
## carpeta y llamar a `colocar`; esta capa conserva los errores para que la
## carpeta siga existiendo y delega la regla de destino en `Archivado` (#169).
class_name ArchivadoBandeja
extends RefCounted


static func nueva(casos: Array, folios_leidos: Array) -> Dictionary:
	return {
		"casos": casos.duplicate(true),
		"folios_leidos": folios_leidos.duplicate(),
		"colocaciones": [],
		"pendientes": casos.duplicate(true),
		"cerrada": false,
		"abandonada": false,
	}


## Coloca una carpeta si el jugador conoce su contenido y devuelve si se aceptó.
## Una colocación incorrecta no destruye el caso: permanece en pendientes.
static func colocar(estado: Dictionary, caso: Dictionary, destino: String) -> bool:
	if (
		estado.get("cerrada", false)
		or not Archivado.es_clasificable(caso, estado.get("folios_leidos", []))
	):
		return false
	var colocacion := {"caso": caso, "destino": destino, "folios_leidos": estado["folios_leidos"]}
	estado["colocaciones"].append(colocacion)
	var correcta := destino == Archivado.destino_de(caso)
	if not correcta:
		return false
	for pendiente in estado["pendientes"]:
		if pendiente.get("id", "") == caso.get("id", ""):
			estado["pendientes"].erase(pendiente)
			break
	return true


static func cerrar(estado: Dictionary) -> Dictionary:
	estado["cerrada"] = true
	return Archivado.evaluar(estado["colocaciones"])


static func abandonar(estado: Dictionary) -> Dictionary:
	# No cambia la bandeja ni la jornada: devuelve el resultado parcial y permite
	# que la futura escena simplemente se descarte.
	estado["abandonada"] = true
	var resultado := Archivado.evaluar(estado.get("colocaciones", []))
	resultado["abandonada"] = true
	return resultado
