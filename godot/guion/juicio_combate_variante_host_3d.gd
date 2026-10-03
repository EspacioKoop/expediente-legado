## Router de variantes oníricas del host 3D (#2249).
##
## Centraliza únicamente el despacho a adaptadores ya seleccionados. No decide
## cultura, arquetipo mecánico, daño ni consecuencias.
class_name JuicioCombateVarianteHost3D
extends RefCounted


static func montar(
	anfitrion,
	acusado: Dictionary,
	rival: CharacterBody3D,
	raiz: int,
) -> Dictionary:
	if rival == null:
		return {}
	var variante := String(acusado.get("_variante_onirica", ""))
	if variante == JuicioCombateGargolaHost3D.VARIANTE:
		return JuicioCombateGargolaHost3D.montar(anfitrion, rival, raiz)
	return {}


static func avanzar(anfitrion, estado: Dictionary, delta: float) -> bool:
	if JuicioCombateGargolaHost3D.es_estado(estado):
		JuicioCombateGargolaHost3D.avanzar(anfitrion, estado, delta)
		return true
	return false


static func controla_movimiento(estado: Dictionary) -> bool:
	return JuicioCombateGargolaHost3D.es_estado(estado)
