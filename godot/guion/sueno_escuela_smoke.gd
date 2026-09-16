## Smoke intencionalmente mínimo para que Godot importe las clases nuevas de
## escuela como parte del proyecto incluso si la escena concreta no sale en la
## primera noche del playtest automático.
class_name SuenoEscuelaSmoke
extends RefCounted


static func valido() -> bool:
	return (
		SuenoEscuela.es_forma(SuenoEscuela.FORMA)
		and SuenoEscuelaAudio.timbre() != null
		and SuenoEscuelaAudio.voces_vacias() != null
	)
