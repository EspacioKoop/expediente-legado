## Objetos físicos que el día deja disponibles para deformar en el sueño (#79/#87).
##
## La memoria es deliberadamente pequeña: solo IDs canónicos de familias visuales
## ya existentes. El registro vive dentro de Jornada porque debe sobrevivir a un
## guardado entre vigilia y sueño, pero lleva su propio número de día para que un
## guardado antiguo o una noche anterior nunca contaminen la siguiente.
class_name ObjetosOniricos
extends RefCounted

const CLAVE := "objetos_tocados_sueno"


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
