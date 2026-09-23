## Consumidor explícito de conflicto para la vertical literaria (#1175/#1183).
##
## Leer una obra solo produce conocimiento/insight. Este módulo transforma un
## insight en un modificador de combate únicamente cuando el jugador ejecuta un
## ritual de cita con coste y contexto de encuentro explícitos.
class_name LiteraturaConflicto
extends RefCounted

const CONSUMIDOR := "conflicto_literario"
const COSTO_CITA_MOMENTUM := 30.0


static func ejecutar_cita(
	registro: Dictionary,
	obra_id: String,
	fuente: String,
	encuentro_id: String,
	jornada: int = 0,
	momentum_actual: float = 0.0,
	ruta_catalogo: String = LiteraturaCatalogo.RUTA
) -> Dictionary:
	var resultado := {
		"obra_id": obra_id.strip_edges(),
		"aplicado": false,
		"ritual_nuevo": false,
		"motivo": "",
		"costo_momentum": COSTO_CITA_MOMENTUM,
		"momentum_restante": maxf(0.0, momentum_actual),
		"modificador": {},
	}

	var id_obra := obra_id.strip_edges()
	var origen := fuente.strip_edges()
	var encuentro := encuentro_id.strip_edges()
	if id_obra.is_empty() or origen.is_empty() or encuentro.is_empty():
		resultado["motivo"] = "contexto_invalido"
		return resultado

	var obra := LiteraturaCatalogo.obra(id_obra, ruta_catalogo)
	if obra.is_empty():
		resultado["motivo"] = "obra_desconocida"
		return resultado

	if not _tiene_insight(registro, id_obra):
		resultado["motivo"] = "insight_requerido"
		return resultado

	var efecto: Dictionary = obra.get("efecto_juego", {})
	var consumidores = efecto.get("consumidores", [])
	if typeof(consumidores) != TYPE_ARRAY or not consumidores.has(CONSUMIDOR):
		resultado["motivo"] = "consumidor_no_compatible"
		return resultado

	var efecto_id := String(efecto.get("id", "")).strip_edges()
	var modificador := _modificador_para_efecto(efecto_id)
	if modificador.is_empty():
		resultado["motivo"] = "efecto_no_soportado"
		return resultado

	var evento_id := "ritual:cita:%s:%s:%s" % [encuentro, id_obra, efecto_id]
	if _ritual_registrado(registro, evento_id):
		resultado["motivo"] = "ya_ejecutado"
		return resultado

	if momentum_actual < COSTO_CITA_MOMENTUM:
		resultado["motivo"] = "momentum_insuficiente"
		return resultado

	var evento := (
		LiteraturaEventos
		. crear_evento(
			evento_id,
			LiteraturaEventos.CANAL_RITUAL,
			id_obra,
			origen,
			encuentro,
			jornada,
			["cita", CONSUMIDOR, efecto_id],
			{
				"efecto_id": efecto_id,
				"costo_momentum": COSTO_CITA_MOMENTUM,
				"modificador": modificador.duplicate(true),
			},
		)
	)
	if not LiteraturaEventos.registrar(registro, evento):
		resultado["motivo"] = "ritual_no_registrado"
		return resultado

	resultado["aplicado"] = true
	resultado["ritual_nuevo"] = true
	resultado["motivo"] = "ritual_ejecutado"
	resultado["momentum_restante"] = maxf(0.0, momentum_actual - COSTO_CITA_MOMENTUM)
	resultado["modificador"] = modificador.duplicate(true)
	return resultado


static func _tiene_insight(registro: Dictionary, obra_id: String) -> bool:
	for evento_bruto in LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_INSIGHT):
		if typeof(evento_bruto) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = evento_bruto
		if String(evento.get("obra_id", "")) == obra_id:
			return true
	return false


static func _ritual_registrado(registro: Dictionary, evento_id: String) -> bool:
	for evento_bruto in LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_RITUAL):
		if typeof(evento_bruto) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = evento_bruto
		if String(evento.get("id", "")) == evento_id:
			return true
	return false


static func _modificador_para_efecto(efecto_id: String) -> Dictionary:
	match efecto_id:
		"palabra_serenidad":
			return {
				"tipo": "resistencia_estado",
				"estado": "miedo",
				"delta": 0.25,
				"duracion": "encuentro_actual",
			}
		_:
			return {}
