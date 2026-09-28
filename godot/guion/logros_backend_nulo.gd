## Backend por defecto para builds sin plataforma externa (#114).
##
## Permite que itch/export local arranquen y sincronicen sin GodotSteam.
class_name LogrosBackendNulo
extends LogrosBackend


func disponible() -> bool:
	return false


func guardar() -> bool:
	return true
