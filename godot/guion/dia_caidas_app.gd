## Red de seguridad de navegación para el playtest (#784).
##
## Esta capa se mantiene sobre la raíz de día sin modificar las capas históricas:
## - si una salida se dispara durante el paso de física, difiere la transición
##   completa para no liberar Areas mientras el servidor aún las está recorriendo;
## - si el caminante cae por debajo del mundo, vuelve a la entrada del espacio
##   actual con velocidad cero mediante el contrato existente de `situar()`.
extends "res://guion/dia_clima_app.gd"

const UMBRAL_RESCATE_CAIDA := -8.0


func _process(delta: float) -> void:
	super._process(delta)
	_rescatar_caida()


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if Engine.is_in_physics_frame():
		call_deferred("_al_pisar_salida", cuerpo, salida)
		return
	super._al_pisar_salida(cuerpo, salida)


func _rescatar_caida() -> void:
	if not is_instance_valid(_caminante) or _espacio_actual.is_empty():
		return
	if _caminante.position.y >= UMBRAL_RESCATE_CAIDA:
		return
	var entrada: Vector3 = _espacio_actual.get("entrada", Vector3.ZERO)
	_caminante.situar(entrada, _espacio_actual.get("mirada", NAN))
