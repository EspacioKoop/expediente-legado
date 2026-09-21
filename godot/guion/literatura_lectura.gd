## Primer productor del contrato literario (#1175/#1176).
##
## Abrir o hojear un documento no basta. Solo al alcanzar el umbral declarado
## por la obra se registran conocimiento e insight. La posesión queda intacta.
class_name LiteraturaLectura
extends RefCounted


static func registrar_interaccion(
	registro: Dictionary,
	obra_id: String,
	fuente_documento: String,
	jornada: int = 0,
	progreso_normalizado: float = 0.0,
	ruta_catalogo: String = LiteraturaCatalogo.RUTA
) -> Dictionary:
	var resultado := {
		"obra_id": obra_id.strip_edges(),
		"completa": false,
		"conocimiento_nuevo": false,
		"insight_nuevo": false,
		"motivo": "",
	}
	var fuente := fuente_documento.strip_edges()
	if fuente.is_empty():
		resultado["motivo"] = "fuente_vacia"
		return resultado

	var obra := LiteraturaCatalogo.obra(obra_id, ruta_catalogo)
	if obra.is_empty():
		resultado["motivo"] = "obra_desconocida"
		return resultado

	var lectura: Dictionary = obra["lectura"]
	var umbral := float(lectura["umbral_conocimiento"])
	var progreso := clampf(progreso_normalizado, 0.0, 1.0)
	if progreso < umbral:
		resultado["motivo"] = "lectura_incompleta"
		return resultado

	resultado["completa"] = true
	var id := String(obra["id"])
	var etiquetas: Array = obra.get("generos", []).duplicate()

	var conocimiento := (
		LiteraturaEventos
		. crear_evento(
			"conocimiento:obra:%s" % id,
			LiteraturaEventos.CANAL_CONOCIMIENTO,
			id,
			fuente,
			String(obra.get("fuente_documental", "")),
			jornada,
			etiquetas,
			{
				"titulo": String(obra.get("titulo", "")),
				"autor": String(obra.get("autor", "")),
				"epoca": String(obra.get("epoca", "")),
			}
		)
	)
	resultado["conocimiento_nuevo"] = LiteraturaEventos.registrar(registro, conocimiento)

	var efecto: Dictionary = obra.get("efecto_juego", {})
	var insight := (
		LiteraturaEventos
		. crear_evento(
			"insight:obra:%s:%s" % [id, String(lectura["insight_id"])],
			LiteraturaEventos.CANAL_INSIGHT,
			id,
			fuente,
			String(obra.get("fuente_documental", "")),
			jornada,
			[String(lectura["insight_id"])],
			{
				"insight_id": String(lectura["insight_id"]),
				"efecto_declarado": efecto.duplicate(true),
			}
		)
	)
	resultado["insight_nuevo"] = LiteraturaEventos.registrar(registro, insight)

	if bool(resultado["conocimiento_nuevo"]) or bool(resultado["insight_nuevo"]):
		resultado["motivo"] = "lectura_significativa"
	else:
		resultado["motivo"] = "ya_registrada"
	return resultado
