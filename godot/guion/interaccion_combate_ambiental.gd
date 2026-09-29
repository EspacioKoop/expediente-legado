## Interacciones ambientales explícitas durante combate autorizado (#1772).
##
## Esta política no detecta nodos ni abre combate. Recibe una declaración
## authored del prop y devuelve una intención acotada para que el host la
## presente. Fuera de combate no hace nada y la interacción normal queda intacta.
class_name InteraccionCombateAmbiental
extends RefCounted

const EMPUJAR := "empujar"
const VOLCAR := "volcar"
const ACTIVAR := "activar"
const VERBOS: Array[String] = [EMPUJAR, VOLCAR, ACTIVAR]

const DESPLAZAMIENTO_EMPUJAR_DEFECTO := 0.85
const DESPLAZAMIENTO_EMPUJAR_MAX := 2.0
const OBSTACULO_VOLCAR_DEFECTO := 1.75
const OBSTACULO_VOLCAR_MAX := 4.0


static func declaracion(
	id: String,
	verbos: Array,
	efecto_id: String = "",
	desplazamiento: float = DESPLAZAMIENTO_EMPUJAR_DEFECTO,
	obstaculo_segundos: float = OBSTACULO_VOLCAR_DEFECTO,
) -> Dictionary:
	var permitidos: Array[String] = []
	for valor in verbos:
		var verbo := String(valor).strip_edges().to_lower()
		if VERBOS.has(verbo) and not permitidos.has(verbo):
			permitidos.append(verbo)
	return {
		"id": id.strip_edges(),
		"verbos_combate": permitidos,
		"efecto_id": efecto_id.strip_edges(),
		"desplazamiento": clampf(desplazamiento, 0.1, DESPLAZAMIENTO_EMPUJAR_MAX),
		"obstaculo_segundos": clampf(obstaculo_segundos, 0.5, OBSTACULO_VOLCAR_MAX),
	}


static func estado_inicial() -> Dictionary:
	return {
		"volcado": false,
		"activado": false,
	}


static func disponible(declarado: Dictionary, verbo: String, combate_permitido: bool) -> bool:
	if not combate_permitido:
		return false
	var canonico := verbo.strip_edges().to_lower()
	if not VERBOS.has(canonico):
		return false
	if String(declarado.get("id", "")).is_empty():
		return false
	var verbos: Variant = declarado.get("verbos_combate", [])
	return verbos is Array and (verbos as Array).has(canonico)


## Devuelve una copia del estado y una intención pequeña. Un fallo nunca muta
## el diccionario recibido. El host decide cómo traducir la intención a nodos.
static func aplicar(
	declarado: Dictionary,
	estado: Dictionary,
	verbo: String,
	combate_permitido: bool,
) -> Dictionary:
	var copia := estado.duplicate(true)
	var canonico := verbo.strip_edges().to_lower()
	if not disponible(declarado, canonico, combate_permitido):
		return _resultado(false, copia, canonico, "no_disponible", {})

	match canonico:
		EMPUJAR:
			return _empujar(declarado, copia)
		VOLCAR:
			return _volcar(declarado, copia)
		ACTIVAR:
			return _activar(declarado, copia)
		_:
			return _resultado(false, copia, canonico, "verbo_desconocido", {})


static func _empujar(declarado: Dictionary, estado: Dictionary) -> Dictionary:
	var metros := clampf(
		float(declarado.get("desplazamiento", DESPLAZAMIENTO_EMPUJAR_DEFECTO)),
		0.1,
		DESPLAZAMIENTO_EMPUJAR_MAX,
	)
	return _resultado(
		true,
		estado,
		EMPUJAR,
		"",
		{
			"tipo": "desplazar",
			"metros": metros,
			"interrumpe": true,
		},
	)


static func _volcar(declarado: Dictionary, estado: Dictionary) -> Dictionary:
	if bool(estado.get("volcado", false)):
		return _resultado(false, estado, VOLCAR, "ya_volcado", {})
	estado["volcado"] = true
	var segundos := clampf(
		float(declarado.get("obstaculo_segundos", OBSTACULO_VOLCAR_DEFECTO)),
		0.5,
		OBSTACULO_VOLCAR_MAX,
	)
	return _resultado(
		true,
		estado,
		VOLCAR,
		"",
		{
			"tipo": "obstaculo_temporal",
			"segundos": segundos,
			"solido_temporal": true,
		},
	)


static func _activar(declarado: Dictionary, estado: Dictionary) -> Dictionary:
	if bool(estado.get("activado", false)):
		return _resultado(false, estado, ACTIVAR, "ya_activado", {})
	var efecto_id := String(declarado.get("efecto_id", "")).strip_edges()
	if efecto_id.is_empty():
		return _resultado(false, estado, ACTIVAR, "sin_efecto_declarado", {})
	estado["activado"] = true
	return _resultado(
		true,
		estado,
		ACTIVAR,
		"",
		{
			"tipo": "activar_efecto",
			"efecto_id": efecto_id,
		},
	)


static func _resultado(
	ok: bool,
	estado: Dictionary,
	verbo: String,
	motivo: String,
	intencion: Dictionary,
) -> Dictionary:
	return {
		"ok": ok,
		"estado": estado,
		"verbo": verbo,
		"motivo": motivo,
		"intencion": intencion,
	}
