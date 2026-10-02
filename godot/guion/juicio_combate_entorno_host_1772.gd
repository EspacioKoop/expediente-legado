## Wiring del entorno de combate #1772 extraido del host principal.
##
## Conserva la prioridad ACTIVAR -> EMPUJAR -> VOLCAR y los mismos motivos
## recuperables. No monta nodos ni toca progreso.
class_name JuicioCombateEntornoHost1772
extends RefCounted

const AMBIENTAL = preload("res://guion/juicio_combate_ambiental_1772.gd")
const EMPUJAR = preload("res://guion/juicio_combate_ambiental_empujar_1772.gd")
const VOLCAR = preload("res://guion/juicio_combate_ambiental_volcar_1772.gd")


static func montar(anfitrion: Node3D) -> Dictionary:
	return {
		"activar": AMBIENTAL.montar(anfitrion),
		"empujar": EMPUJAR.montar(anfitrion),
		"volcar": VOLCAR.montar(anfitrion),
	}


static func avanzar(empujar: Dictionary, volcar: Dictionary, delta: float) -> void:
	if not empujar.is_empty():
		EMPUJAR.avanzar(empujar, delta)
	if not volcar.is_empty():
		VOLCAR.avanzar(volcar, delta)


static func usar(
	habilitada: bool,
	acabado: bool,
	jugador: CharacterBody3D,
	ambiental: Dictionary,
	empujar: Dictionary,
	volcar: Dictionary,
) -> bool:
	if not habilitada or acabado or jugador == null or not is_instance_valid(jugador):
		return false
	var posicion := jugador.global_position
	var resultado := {}
	var continuar := true
	if not ambiental.is_empty():
		resultado = AMBIENTAL.activar(ambiental, posicion, true)
		continuar = (
			not bool(resultado.get("ok", false))
			and String(resultado.get("motivo", "")) in ["fuera_de_alcance", "ya_activado"]
		)
	if continuar and not empujar.is_empty():
		resultado = EMPUJAR.empujar(empujar, posicion, true)
		continuar = (
			not bool(resultado.get("ok", false))
			and (
				String(resultado.get("motivo", ""))
				in ["fuera_de_alcance", "sin_usos", "en_recarga"]
			)
		)
	if continuar and not volcar.is_empty():
		resultado = VOLCAR.volcar(volcar, posicion, true)
	return bool(resultado.get("ok", false))


static func estado(ambiental: Dictionary) -> Dictionary:
	if ambiental.is_empty():
		return {}
	var valor: Variant = ambiental.get("estado", {})
	return (valor as Dictionary).duplicate(true) if valor is Dictionary else {}
