## Consumidor onirico del contrato literario (#1182).
##
## Esta capa NO selecciona escenas ni consulta expedientes. Recibe un espacio
## onirico ya construido y, solo si existe un evento de insight literario
## valido, aplica una modulacion visual declarada por el catalogo. Sin insight,
## devuelve una copia profunda equivalente al espacio recibido.
class_name SuenoLiteratura
extends RefCounted

const CONSUMIDOR := "sueno_literario"


static func motivos(registro: Dictionary, ruta_catalogo: String = LiteraturaCatalogo.RUTA) -> Array:
	var resultado := []
	for bruto in LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_INSIGHT):
		if typeof(bruto) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = bruto
		var obra := LiteraturaCatalogo.obra(String(evento.get("obra_id", "")), ruta_catalogo)
		if obra.is_empty():
			continue

		var lectura = obra.get("lectura", {})
		var metadatos = evento.get("metadatos", {})
		if typeof(lectura) != TYPE_DICTIONARY or typeof(metadatos) != TYPE_DICTIONARY:
			continue
		var insight_id := String(metadatos.get("insight_id", "")).strip_edges()
		if insight_id.is_empty() or insight_id != String(lectura.get("insight_id", "")):
			continue

		var sueno = obra.get("sueno", {})
		if typeof(sueno) != TYPE_DICTIONARY:
			continue
		if String(sueno.get("consumidor", "")) != CONSUMIDOR:
			continue
		var declarados = sueno.get("motivos", [])
		if typeof(declarados) != TYPE_ARRAY:
			continue
		var presentacion = sueno.get("presentacion", {})
		if typeof(presentacion) != TYPE_DICTIONARY:
			presentacion = {}

		for valor in declarados:
			var motivo := String(valor).strip_edges()
			if motivo.is_empty():
				continue
			(
				resultado
				. append(
					{
						"id": "%s:%s" % [String(obra.get("id", "")), motivo],
						"obra_id": String(obra.get("id", "")),
						"insight_id": insight_id,
						"motivo": motivo,
						"presentacion": presentacion.duplicate(true),
					}
				)
			)

	resultado.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("id", "")) < String(b.get("id", ""))
	)
	return resultado


static func aplicar(
	espacio: Dictionary,
	registro: Dictionary,
	indice_escena: int = 0,
	ruta_catalogo: String = LiteraturaCatalogo.RUTA
) -> Dictionary:
	var resultado := espacio.duplicate(true)
	var disponibles := motivos(registro, ruta_catalogo)
	if disponibles.is_empty():
		return resultado

	var indice := absi(indice_escena) % disponibles.size()
	var elegido: Dictionary = disponibles[indice]
	var presentacion = elegido.get("presentacion", {})
	if typeof(presentacion) != TYPE_DICTIONARY:
		presentacion = {}

	var factor := _vector3(presentacion.get("deformacion_textura", []))
	var actual: Vector3 = resultado.get("deformacion_textura", Vector3.ONE)
	resultado["deformacion_textura"] = Vector3(
		actual.x * factor.x,
		actual.y * factor.y,
		actual.z * factor.z,
	)
	resultado["contraste_textura"] = clampf(
		(
			float(resultado.get("contraste_textura", 1.0))
			+ float(presentacion.get("contraste_delta", 0.0))
		),
		0.5,
		2.0,
	)
	resultado["ambiente_energia"] = clampf(
		(
			float(resultado.get("ambiente_energia", 0.32))
			+ float(presentacion.get("ambiente_energia_delta", 0.0))
		),
		0.05,
		1.5,
	)
	# Metadato de procedencia para pruebas/capas visuales futuras. No contiene
	# texto de expedientes, pistas ni interpretaciones narrativas.
	resultado["motivo_literario"] = {
		"obra_id": String(elegido.get("obra_id", "")),
		"insight_id": String(elegido.get("insight_id", "")),
		"motivo": String(elegido.get("motivo", "")),
	}
	return resultado


static func _vector3(valor: Variant) -> Vector3:
	if typeof(valor) != TYPE_ARRAY:
		return Vector3.ONE
	var datos: Array = valor
	if datos.size() != 3:
		return Vector3.ONE
	return Vector3(float(datos[0]), float(datos[1]), float(datos[2]))
