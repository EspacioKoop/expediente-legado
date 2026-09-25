## Objetos físicos que el día deja disponibles para deformar en el sueño (#79/#87).
##
## La memoria es deliberadamente pequeña: solo IDs canónicos de familias visuales
## ya existentes. El registro vive dentro de Jornada porque debe sobrevivir a un
## guardado entre vigilia y sueño, pero lleva su propio número de día para que un
## guardado antiguo o una noche anterior nunca contaminen la siguiente.
class_name ObjetosOniricos
extends RefCounted

const CLAVE := "objetos_tocados_sueno"

## Metadatos físicos reutilizables por sistemas oníricos que necesiten una
## propiedad cuantitativa observable. Son unidades relativas, no kilogramos:
## importan las diferencias y la reproducibilidad, no simular una báscula real.
const PERFILES_PESO := {
	"silla": {"peso": 2.0, "peso_sellado": 2.5},
	"monitor": {"peso": 4.0, "peso_sellado": 3.5},
	"archivador": {"peso": 6.0, "peso_sellado": 7.0},
	"armario_hogar": {"peso": 8.0, "peso_sellado": 6.5},
	"televisor_casa": {"peso": 5.0, "peso_sellado": 4.0},
}


## Registra una interacción deliberada. Devuelve true solo cuando aparece una
## familia nueva y, por tanto, merece escribir la partida una vez.
static func registrar(jornada: Dictionary, objeto_id: String) -> bool:
	var id := objeto_id.strip_edges()
	if id.is_empty():
		return false
	var dia := int(jornada.get("dia", 0))
	var registro = jornada.get(CLAVE, {})
	if not registro is Dictionary or int(registro.get("dia", -1)) != dia:
		registro = {"dia": dia, "ids": []}
		jornada[CLAVE] = registro
	var ids = registro.get("ids", [])
	if not ids is Array:
		ids = []
		registro["ids"] = ids
	if ids.has(id):
		return false
	ids.append(id)
	return true


## Lee únicamente la memoria de la jornada activa. No migra ni muta: si el
## formato es viejo, roto o pertenece a otro día, el sueño recibe una lista
## vacía y no inventa objetos para rellenar el hueco.
static func del_dia(jornada: Dictionary) -> Array:
	var registro = jornada.get(CLAVE, {})
	if not registro is Dictionary:
		return []
	if int(registro.get("dia", -1)) != int(jornada.get("dia", 0)):
		return []
	var ids = registro.get("ids", [])
	if not ids is Array:
		return []
	var validos := []
	for valor in ids:
		var id := String(valor).strip_edges()
		if not id.is_empty() and not validos.has(id):
			validos.append(id)
	return validos


## Traduce únicamente objetos realmente tocados hoy a perfiles aptos para un
## pesaje. Un ID conocido por otros sueños pero sin perfil físico se ignora:
## ningún consumidor obtiene objetos de relleno ni inventa propiedades.
static func para_pesaje(jornada: Dictionary) -> Array:
	var resultado := []
	for valor in del_dia(jornada):
		var id := String(valor)
		if not PERFILES_PESO.has(id):
			continue
		var perfil: Dictionary = PERFILES_PESO[id]
		resultado.append(
			{
				"id": id,
				"peso": float(perfil.get("peso", 0.0)),
				"peso_sellado": float(perfil.get("peso_sellado", perfil.get("peso", 0.0))),
				"manipulado_hoy": true,
			}
		)
	return resultado
