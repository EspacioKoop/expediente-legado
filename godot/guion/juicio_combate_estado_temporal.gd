## Estado temporal mutable del Juicio por Combate.
##
## Agrupa contadores efímeros que antes vivían dispersos en JuicioCombate3D.
## La regla de descuento sigue siendo pura y vive en JuicioCombateReglas; este
## objeto conserva los valores entre frames y devuelve únicamente expiraciones.
class_name JuicioCombateEstadoTemporal
extends RefCounted

const REGLAS = preload("res://guion/juicio_combate_reglas.gd")

var recarga_jugador := 0.0
var recarga_rival := 0.0
var esquiva := 0.0
var enredo := 0.0
var invulnerabilidad_jungiana := 0.0
var sacudida_camara := 0.0
var aviso_jungiano := 0.0
var doctrina := 0.0


func descontar(delta: float) -> Array:
	var paso := (
		REGLAS
		. descontar_temporizadores(
			{
				"recarga_jugador": recarga_jugador,
				"recarga_rival": recarga_rival,
				"esquiva": esquiva,
				"enredo": enredo,
				"invulnerabilidad_jungiana": invulnerabilidad_jungiana,
				"sacudida_camara": sacudida_camara,
				"aviso_jungiano": aviso_jungiano,
				"doctrina": doctrina,
			},
			delta,
		)
	)
	var restantes: Dictionary = paso["restantes"]
	recarga_jugador = float(restantes["recarga_jugador"])
	recarga_rival = float(restantes["recarga_rival"])
	esquiva = float(restantes["esquiva"])
	enredo = float(restantes["enredo"])
	invulnerabilidad_jungiana = float(restantes["invulnerabilidad_jungiana"])
	sacudida_camara = float(restantes["sacudida_camara"])
	aviso_jungiano = float(restantes["aviso_jungiano"])
	doctrina = float(restantes["doctrina"])
	return paso["expirados"]
