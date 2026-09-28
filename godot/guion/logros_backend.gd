## Contrato desacoplado para espejar logros internos en una plataforma externa (#114).
##
## Prometeo/Partida siguen siendo la fuente de verdad. Un backend externo solo
## recibe logros ya desbloqueados; nunca decide reglas, bloquea logros ni muta la partida.
class_name LogrosBackend
extends RefCounted


func disponible() -> bool:
	return false


func esta_desbloqueado(_logro_id: String) -> bool:
	return false


func desbloquear(_logro_id: String) -> bool:
	return false


func guardar() -> bool:
	return true
