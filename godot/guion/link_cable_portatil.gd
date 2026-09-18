## Estado diegético mínimo del Link Cable de la Portátil Color 98 (#245).
##
## No emula el puerto serie ni conoce el núcleo GB. Es un contrato local que
## permite representar conectar/desconectar hoy y sustituir el backend mañana.
class_name LinkCablePortatil
extends RefCounted

signal estado_cambiado(conectado: bool)

var _conectado := false


func esta_conectado() -> bool:
	return _conectado


func conectar() -> void:
	if _conectado:
		return
	_conectado = true
	estado_cambiado.emit(true)


func desconectar() -> void:
	if not _conectado:
		return
	_conectado = false
	estado_cambiado.emit(false)


func alternar() -> bool:
	if _conectado:
		desconectar()
	else:
		conectar()
	return _conectado
