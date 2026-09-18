## Estado ambiental mínimo del puerto infrarrojo de la Portátil Color 98 (#245).
##
## No implementa el protocolo IR del hardware ni conoce SameBoy. Solo expone un
## pulso local para que carcasa y UI compartan una respuesta visual desacoplada.
class_name PuertoIRPortatil
extends RefCounted

signal pulso_emitido(secuencia: int)

var _pulsos_emitidos := 0


func pulsos_emitidos() -> int:
	return _pulsos_emitidos


func emitir_pulso() -> int:
	_pulsos_emitidos += 1
	pulso_emitido.emit(_pulsos_emitidos)
	return _pulsos_emitidos
