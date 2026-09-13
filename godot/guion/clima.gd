## Clima diario determinista (#143).
##
## No se guarda nada: el estado sale únicamente del número de día. Así recargar
## conserva el mismo tiempo y una nueva vuelta vuelve al día 1 despejado.
class_name Clima
extends RefCounted

const DESPEJADO := "despejado"
const NUBLADO := "nublado"
const LLUVIA := "lluvia"
const NIEBLA := "niebla"
const NIEVE := "nieve"

const RUEDA := [NUBLADO, LLUVIA, DESPEJADO, NIEBLA, NIEVE]


static func estado(dia: int) -> String:
	if dia <= 1:
		return DESPEJADO
	return RUEDA[(dia - 2) % RUEDA.size()]


static func precipitacion(estado_clima: String) -> bool:
	return estado_clima == LLUVIA or estado_clima == NIEVE
