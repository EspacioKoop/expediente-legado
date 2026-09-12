## Sellos cosméticos internos de SIGA.
##
## Este módulo no concede recursos ni decide reglas de juego. Solo conoce el
## catálogo y registra ids ya concedidos dentro de un diccionario de estado.
## Quien persista ese diccionario (Partida en el siguiente corte) conserva los
## sellos sin que esta capa tenga que saber nada de disco ni plataformas externas.
class_name Sellos
extends RefCounted

const RUTA_CATALOGO := "res://datos/sellos.json"
const CLAVE_ESTADO := "sellos_obtenidos"


static func catalogo() -> Array:
	var fichero := FileAccess.open(RUTA_CATALOGO, FileAccess.READ)
	if fichero == null:
		push_error("No se pudo abrir %s" % RUTA_CATALOGO)
		return []
	var datos = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(datos) != TYPE_ARRAY:
		push_error("El catálogo de sellos no es una lista")
		return []
	return datos


static func ficha(sello_id: String) -> Dictionary:
	for entrada in catalogo():
		if String(entrada.get("id", "")) == sello_id:
			return entrada
	return {}


static func tiene_sello(estado: Dictionary, sello_id: String) -> bool:
	var obtenidos: Array = estado.get(CLAVE_ESTADO, [])
	return obtenidos.has(sello_id)


## Registra una sola vez un sello conocido.
##
## Devuelve un resultado explícito para que herramientas/tests puedan distinguir
## una clave inválida de una concesión repetida sin excepciones ni estado oculto.
static func registrar_sello(estado: Dictionary, sello_id: String) -> Dictionary:
	var entrada := ficha(sello_id)
	if entrada.is_empty():
		push_warning("Sello desconocido: %s" % sello_id)
		return {"resultado": "desconocido", "id": sello_id}
	if not bool(entrada.get("disponible", true)):
		return {"resultado": "no-disponible", "id": sello_id}

	var obtenidos: Array = estado.get(CLAVE_ESTADO, []).duplicate()
	if obtenidos.has(sello_id):
		return {"resultado": "ya-obtenido", "id": sello_id}

	obtenidos.append(sello_id)
	estado[CLAVE_ESTADO] = obtenidos
	return {"resultado": "registrado", "id": sello_id}
