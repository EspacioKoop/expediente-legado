## Contrato puro del teatro onírico (#2489).
##
## Recibe contexto narrativo ya existente y devuelve una variante de puesta en
## escena. No escribe en el contexto, Partida ni Jornada y siempre declara una
## salida segura para que la capa visual pueda montarla sin inventar progreso.
class_name TeatroSuenioContrato
extends RefCounted

const VARIANTES := [
	{
		"id": "repeticion",
		"puesta": "La escena vivida se repite con posiciones y silencios desplazados.",
		"intervencion_lucida": "cambiar_bloqueo",
	},
	{
		"id": "juicio",
		"puesta": "La platea vacía observa mientras los papeles del expediente hacen de reparto.",
		"intervencion_lucida": "apagar_foco",
	},
	{
		"id": "doble",
		"puesta": "Un doble del protagonista representa una decisión ya tomada con otra intención.",
		"intervencion_lucida": "cambiar_marca",
	},
]


static func seleccionar(contexto: Dictionary, raiz: int) -> Dictionary:
	var copia_contexto := contexto.duplicate(true)
	var huella := _huella_contexto(copia_contexto)
	var semilla := Azar.derivar_texto(raiz, "sueno", huella, [2474])
	var indice := int(semilla % VARIANTES.size())
	var variante: Dictionary = VARIANTES[indice].duplicate(true)
	variante["salida_segura"] = true
	variante["muta_canon"] = false
	variante["contexto_observado"] = copia_contexto
	return variante


static func aplicar_intervencion(variante: Dictionary, intervencion: String) -> Dictionary:
	var salida := variante.duplicate(true)
	if String(salida.get("intervencion_lucida", "")) != intervencion:
		return salida
	salida["presentacion_alterada"] = true
	salida["intervencion_aplicada"] = intervencion
	salida["muta_canon"] = false
	salida["salida_segura"] = true
	return salida


static func _huella_contexto(contexto: Dictionary) -> String:
	var claves: Array = contexto.keys()
	claves.sort()
	var partes := []
	for clave_var in claves:
		var clave := String(clave_var)
		partes.append("%s=%s" % [clave, _normalizar_valor(contexto[clave_var])])
	return "|".join(partes)


static func _normalizar_valor(valor: Variant) -> String:
	match typeof(valor):
		TYPE_ARRAY:
			var partes := []
			for item in valor:
				partes.append(_normalizar_valor(item))
			return "[" + ",".join(partes) + "]"
		TYPE_DICTIONARY:
			return _huella_contexto(valor as Dictionary)
		_:
			return str(valor)
