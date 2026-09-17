## Red de seguridad de navegación para el playtest (#784).
##
## Esta capa se inserta en la cadena histórica del día sin sustituir el script
## raíz de `dia.tscn`:
## - si una salida se dispara durante el paso de física, espera al siguiente
##   frame de proceso antes de dejar que la capa base desmonte el mundo actual;
## - si el caminante cae por debajo del mundo, vuelve a la entrada del espacio
##   actual con velocidad cero mediante el contrato existente de `situar()`.
extends "res://guion/dia_onboarding_app.gd"

const UMBRAL_RESCATE_CAIDA := -8.0


func _process(_delta: float) -> void:
	_rescatar_caida()


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if Engine.is_in_physics_frame():
		_continuar_salida_fuera_de_fisica(cuerpo, salida)
		return
	super._al_pisar_salida(cuerpo, salida)


func _continuar_salida_fuera_de_fisica(cuerpo: Node3D, salida: Area3D) -> void:
	await get_tree().process_frame
	if not is_instance_valid(cuerpo) or not is_instance_valid(salida):
		return
	super._al_pisar_salida(cuerpo, salida)


func _rescatar_caida() -> void:
	if not is_instance_valid(_caminante) or _espacio_actual.is_empty():
		return
	if _caminante.position.y >= UMBRAL_RESCATE_CAIDA:
		return
	var entrada: Vector3 = _espacio_actual.get("entrada", Vector3.ZERO)
	_caminante.situar(entrada, _espacio_actual.get("mirada", NAN))
