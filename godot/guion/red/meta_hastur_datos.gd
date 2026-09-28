class_name MetaHasturDatos
extends RefCounted

## Contrato pre-1.0 para #382.
##
## Este módulo no conoce Partida ni activa producción. Valida snapshots de
## presentación y contribuciones cerradas. La suma de progreso solo existe aquí
## como simulador de fixtures/staging; el agregado real deberá ser autoritativo
## del servidor cuando el feature gate de producción se habilite después de 1.0.

const CONTRACT_VERSION := 1
const RULES_VERSION := 1
const PRODUCCION_HABILITADA := false

const FASES := ["latente", "resistencia", "umbral", "confrontacion", "derrota"]
const TIPOS_CONTRIBUCION := [
	"personal_climax",
	"coop_combat",
	"dream_objective",
	"help_resonance",
	"special_event",
]
const PESOS_FIXTURE := {
	"personal_climax": 10,
	"coop_combat": 4,
	"dream_objective": 3,
	"help_resonance": 1,
	"special_event": 8,
}
const CAMPOS_CONTRIBUCION := [
	"contract_version",
	"rules_version",
	"season_id",
	"contribution_id",
	"actor_public_id",
	"type",
	"source_event_id",
	"occurred_at",
]
const MAX_ID := 96
const MAX_THRESHOLDS := 16


static func produccion_habilitada(config: Dictionary, version_1_0: bool) -> bool:
	return (
		PRODUCCION_HABILITADA
		and version_1_0
		and bool(config.get("global_hastur_event", false))
	)


static func validar_snapshot(datos: Variant) -> Dictionary:
	if typeof(datos) != TYPE_DICTIONARY:
		return _invalido("snapshot_not_dictionary")

	for campo in [
		"contract_version",
		"rules_version",
		"season_id",
		"phase",
		"community_progress",
		"thresholds",
		"contributors_approx",
		"updated_at",
	]:
		if not datos.has(campo):
			return _invalido("missing_%s" % campo)

	if int(datos["contract_version"]) != CONTRACT_VERSION:
		return _invalido("unsupported_contract_version")
	if int(datos["rules_version"]) != RULES_VERSION:
		return _invalido("unsupported_rules_version")

	var season_id := String(datos["season_id"])
	if not _id_valido(season_id):
		return _invalido("invalid_season_id")

	var phase := String(datos["phase"])
	if not FASES.has(phase):
		return _invalido("invalid_phase")

	if typeof(datos["community_progress"]) != TYPE_INT:
		return _invalido("invalid_progress_type")
	var progress := int(datos["community_progress"])
	if progress < 0:
		return _invalido("invalid_progress")

	var thresholds_result := _validar_thresholds(datos["thresholds"])
	if not thresholds_result["ok"]:
		return thresholds_result
	var thresholds: Array = thresholds_result["thresholds"]
	if progress > int(thresholds[-1]):
		return _invalido("progress_over_max")

	if typeof(datos["contributors_approx"]) != TYPE_INT:
		return _invalido("invalid_contributors_type")
	var contributors_approx := int(datos["contributors_approx"])
	if contributors_approx < 0:
		return _invalido("invalid_contributors")

	if typeof(datos["updated_at"]) != TYPE_INT:
		return _invalido("invalid_updated_at_type")
	var updated_at := int(datos["updated_at"])
	if updated_at <= 0:
		return _invalido("invalid_updated_at")

	if phase == "derrota" and progress < int(thresholds[-1]):
		return _invalido("defeat_before_final_threshold")

	return {
		"ok": true,
		"reason": "",
		"snapshot":
		{
			"contract_version": CONTRACT_VERSION,
			"rules_version": RULES_VERSION,
			"season_id": season_id,
			"phase": phase,
			"community_progress": progress,
			"thresholds": thresholds,
			"contributors_approx": contributors_approx,
			"updated_at": updated_at,
		},
	}


static func validar_contribucion(datos: Variant) -> Dictionary:
	if typeof(datos) != TYPE_DICTIONARY:
		return _invalido("contribution_not_dictionary")
	for campo in CAMPOS_CONTRIBUCION:
		if not datos.has(campo):
			return _invalido("missing_%s" % campo)
	for clave in datos.keys():
		if not CAMPOS_CONTRIBUCION.has(String(clave)):
			return _invalido("unexpected_%s" % String(clave))

	if int(datos["contract_version"]) != CONTRACT_VERSION:
		return _invalido("unsupported_contract_version")
	if int(datos["rules_version"]) != RULES_VERSION:
		return _invalido("unsupported_rules_version")

	for campo in ["season_id", "contribution_id", "actor_public_id", "source_event_id"]:
		if not _id_valido(String(datos[campo])):
			return _invalido("invalid_%s" % campo)

	var tipo := String(datos["type"])
	if not TIPOS_CONTRIBUCION.has(tipo):
		return _invalido("invalid_type")

	if typeof(datos["occurred_at"]) != TYPE_INT or int(datos["occurred_at"]) <= 0:
		return _invalido("invalid_occurred_at")

	return {
		"ok": true,
		"reason": "",
		"contribution":
		{
			"contract_version": CONTRACT_VERSION,
			"rules_version": RULES_VERSION,
			"season_id": String(datos["season_id"]),
			"contribution_id": String(datos["contribution_id"]),
			"actor_public_id": String(datos["actor_public_id"]),
			"type": tipo,
			"source_event_id": String(datos["source_event_id"]),
			"occurred_at": int(datos["occurred_at"]),
		},
	}


static func simular_agregado_fixture(snapshot: Dictionary, contribuciones: Array) -> Dictionary:
	var base_result := validar_snapshot(snapshot)
	if not base_result["ok"]:
		return base_result

	var normalizado: Dictionary = base_result["snapshot"].duplicate(true)
	var vistos := {}
	var aceptadas := 0
	var duplicadas := 0
	var rechazadas := 0

	for candidata in contribuciones:
		var validacion := validar_contribucion(candidata)
		if not validacion["ok"]:
			rechazadas += 1
			continue
		var contribucion: Dictionary = validacion["contribution"]
		if contribucion["season_id"] != normalizado["season_id"]:
			rechazadas += 1
			continue
		var contribution_id := String(contribucion["contribution_id"])
		if vistos.has(contribution_id):
			duplicadas += 1
			continue
		vistos[contribution_id] = true
		aceptadas += 1
		normalizado["community_progress"] += int(PESOS_FIXTURE[contribucion["type"]])

	var maximo := int(normalizado["thresholds"][-1])
	normalizado["community_progress"] = min(int(normalizado["community_progress"]), maximo)
	normalizado["phase"] = _fase_fixture(
		int(normalizado["community_progress"]), normalizado["thresholds"]
	)
	return {
		"ok": true,
		"reason": "",
		"snapshot": normalizado,
		"accepted": aceptadas,
		"duplicates": duplicadas,
		"rejected": rechazadas,
	}


static func _fase_fixture(progress: int, thresholds: Array) -> String:
	var maximo := int(thresholds[-1])
	if progress >= maximo:
		return "derrota"
	if progress >= int(thresholds[-2]):
		return "confrontacion"
	if progress >= int(thresholds[0]):
		return "umbral"
	if progress > 0:
		return "resistencia"
	return "latente"


static func _validar_thresholds(valor: Variant) -> Dictionary:
	if typeof(valor) != TYPE_ARRAY:
		return _invalido("thresholds_not_array")
	var thresholds: Array = valor
	if thresholds.size() < 2 or thresholds.size() > MAX_THRESHOLDS:
		return _invalido("invalid_threshold_count")
	var anterior := 0
	var normalizados: Array[int] = []
	for item in thresholds:
		if typeof(item) != TYPE_INT:
			return _invalido("invalid_threshold_type")
		var actual := int(item)
		if actual <= anterior:
			return _invalido("thresholds_not_increasing")
		normalizados.append(actual)
		anterior = actual
	return {"ok": true, "reason": "", "thresholds": normalizados}


static func _id_valido(valor: String) -> bool:
	if valor.is_empty() or valor.length() > MAX_ID:
		return false
	for i in range(valor.length()):
		var codigo := valor.unicode_at(i)
		var numero := codigo >= 48 and codigo <= 57
		var mayuscula := codigo >= 65 and codigo <= 90
		var minuscula := codigo >= 97 and codigo <= 122
		if not numero and not mayuscula and not minuscula and codigo not in [45, 46, 58, 95]:
			return false
	return true


static func _invalido(razon: String) -> Dictionary:
	return {
		"ok": false,
		"reason": razon,
		"snapshot": {},
		"contribution": {},
		"thresholds": [],
	}
