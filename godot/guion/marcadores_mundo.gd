## Marcadores diegéticos persistentes de #957.
##
## Esta capa solo administra estado JSON-safe dentro de Jornada. No conoce
## escenas, input ni disco: Partida persiste la Jornada completa como ya hace
## con el resto de herramientas auxiliares.
class_name MarcadoresMundo
extends RefCounted

const CLAVE := "marcadores_mundo"
const LIMITE_POR_ZONA := 5
const MAX_TEXTO := 24

const TIPO_TIZA := "tiza"
const TIPO_CINTA := "cinta"
const TIPO_NOTA := "nota"
const TIPO_CARBON := "carbon"
const TIPO_OBJETO := "objeto"
const TIPOS := [TIPO_TIZA, TIPO_CINTA, TIPO_NOTA, TIPO_CARBON, TIPO_OBJETO]

const COLOR_BLANCO := "blanco"
const COLOR_AMARILLO := "amarillo"
const COLOR_ROJO := "rojo"
const COLOR_AZUL := "azul"
const COLOR_VERDE := "verde"
const COLORES := [COLOR_BLANCO, COLOR_AMARILLO, COLOR_ROJO, COLOR_AZUL, COLOR_VERDE]


static func asegurar(jornada: Dictionary) -> Dictionary:
	var estado = jornada.get(CLAVE, {})
	if typeof(estado) != TYPE_DICTIONARY:
		estado = {}
		jornada[CLAVE] = estado

	if typeof(estado.get("zonas", {})) != TYPE_DICTIONARY:
		estado["zonas"] = {}
	elif not estado.has("zonas"):
		estado["zonas"] = {}

	var secuencia = estado.get("secuencia", 0)
	if typeof(secuencia) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(secuencia)):
		secuencia = 0
	estado["secuencia"] = maxi(0, int(secuencia))
	jornada[CLAVE] = estado
	return estado


static func colocar(
	jornada: Dictionary,
	zona: String,
	tipo: String,
	color: String,
	texto: String,
	posicion: Vector3,
	normal: Vector3,
	solo_sueno := false,
) -> Dictionary:
	var zona_limpia := zona.strip_edges()
	if zona_limpia.is_empty():
		return {"ok": false, "motivo": "zona_invalida"}
	if not TIPOS.has(tipo):
		return {"ok": false, "motivo": "tipo_invalido"}
	if not COLORES.has(color):
		return {"ok": false, "motivo": "color_invalido"}
	if not _vector_finito(posicion) or not _vector_finito(normal):
		return {"ok": false, "motivo": "transformacion_invalida"}

	var estado := asegurar(jornada)
	var zonas: Dictionary = estado["zonas"]
	var actuales := _lista_valida(zonas.get(zona_limpia, []))
	if actuales.size() >= LIMITE_POR_ZONA:
		return {"ok": false, "motivo": "limite_zona"}

	var secuencia := int(estado.get("secuencia", 0)) + 1
	estado["secuencia"] = secuencia
	var normal_limpia := normal.normalized() if normal.length_squared() > 0.000001 else Vector3.UP
	var texto_limpio := texto.strip_edges().substr(0, MAX_TEXTO)
	if tipo not in [TIPO_CINTA, TIPO_NOTA]:
		texto_limpio = ""

	var marcador := {
		"id": "m%06d" % secuencia,
		"tipo": tipo,
		"color": color,
		"texto": texto_limpio,
		"posicion": _vector_a_lista(posicion),
		"normal": _vector_a_lista(normal_limpia),
		"solo_sueno": solo_sueno,
	}
	actuales.append(marcador)
	zonas[zona_limpia] = actuales
	estado["zonas"] = zonas
	jornada[CLAVE] = estado
	return {"ok": true, "motivo": "", "marcador": marcador.duplicate(true)}


static func listar(jornada: Dictionary, zona: String) -> Array:
	var estado := asegurar(jornada)
	var zonas: Dictionary = estado["zonas"]
	var resultado: Array = []
	for marcador in _lista_valida(zonas.get(zona.strip_edges(), [])):
		resultado.append(marcador.duplicate(true))
	return resultado


static func eliminar(jornada: Dictionary, zona: String, marcador_id: String) -> bool:
	var estado := asegurar(jornada)
	var zonas: Dictionary = estado["zonas"]
	var clave := zona.strip_edges()
	var actuales := _lista_valida(zonas.get(clave, []))
	for indice in range(actuales.size()):
		if String(actuales[indice].get("id", "")) == marcador_id:
			actuales.remove_at(indice)
			if actuales.is_empty():
				zonas.erase(clave)
			else:
				zonas[clave] = actuales
			estado["zonas"] = zonas
			jornada[CLAVE] = estado
			return true
	return false


static func eliminar_zona(jornada: Dictionary, zona: String) -> int:
	var estado := asegurar(jornada)
	var zonas: Dictionary = estado["zonas"]
	var clave := zona.strip_edges()
	var cantidad := _lista_valida(zonas.get(clave, [])).size()
	zonas.erase(clave)
	estado["zonas"] = zonas
	jornada[CLAVE] = estado
	return cantidad


static func visible_en(marcador: Dictionary, en_sueno: bool) -> bool:
	return not bool(marcador.get("solo_sueno", false)) or en_sueno


static func posicion_de(marcador: Dictionary) -> Vector3:
	return vector3_de(marcador.get("posicion", []), Vector3.ZERO)


static func normal_de(marcador: Dictionary) -> Vector3:
	var normal := vector3_de(marcador.get("normal", []), Vector3.UP)
	return normal.normalized() if normal.length_squared() > 0.000001 else Vector3.UP


static func vector3_de(valor, respaldo: Vector3) -> Vector3:
	if typeof(valor) != TYPE_ARRAY or valor.size() < 3:
		return respaldo
	for componente in valor.slice(0, 3):
		if typeof(componente) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(componente)):
			return respaldo
	return Vector3(float(valor[0]), float(valor[1]), float(valor[2]))


static func _lista_valida(valor) -> Array:
	if typeof(valor) != TYPE_ARRAY:
		return []
	var resultado: Array = []
	for marcador in valor:
		if typeof(marcador) == TYPE_DICTIONARY:
			resultado.append(marcador)
	return resultado


static func _vector_a_lista(vector: Vector3) -> Array:
	return [vector.x, vector.y, vector.z]


static func _vector_finito(vector: Vector3) -> bool:
	return is_finite(vector.x) and is_finite(vector.y) and is_finite(vector.z)
