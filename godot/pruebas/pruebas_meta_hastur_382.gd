extends SceneTree

const MetaHasturDatos = preload("res://guion/red/meta_hastur_datos.gd")
const RUTA_FIXTURE := "res://datos/meta_hastur_fixtures.json"

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_snapshots()
	_probar_gate_produccion()
	_probar_contribuciones_idempotentes()
	_probar_contribucion_sin_puntos_cliente()
	print("meta_hastur_382: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(0 if fallos == 0 else 1)


func _probar_snapshots() -> void:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_FIXTURE))
	_comprobar("fixture JSON valido", datos is Dictionary, true)
	if not datos is Dictionary:
		return
	var snapshots: Dictionary = datos.get("snapshots", {})
	for nombre in ["cero", "primer_umbral", "completo"]:
		var resultado := MetaHasturDatos.validar_snapshot(snapshots.get(nombre, {}))
		_comprobar("snapshot %s valido" % nombre, resultado["ok"], true)
	_comprobar("fixture 0%", snapshots["cero"]["community_progress"], 0)
	_comprobar("fixture umbral", snapshots["primer_umbral"]["community_progress"], 25)
	_comprobar("fixture 100%", snapshots["completo"]["community_progress"], 100)


func _probar_gate_produccion() -> void:
	_comprobar(
		"produccion sigue apagada antes de 1.0",
		MetaHasturDatos.produccion_habilitada({"global_hastur_event": true}, true),
		false
	)
	_comprobar(
		"config falsa tampoco activa",
		MetaHasturDatos.produccion_habilitada({"global_hastur_event": false}, true),
		false
	)


func _probar_contribuciones_idempotentes() -> void:
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA_FIXTURE))
	var snapshot: Dictionary = datos["snapshots"]["cero"]
	var contribucion := _contribucion("c-001", "help_resonance")
	var resultado := MetaHasturDatos.simular_agregado_fixture(
		snapshot, [contribucion, contribucion.duplicate(true)]
	)
	_comprobar("agregado fixture valido", resultado["ok"], true)
	_comprobar("una aceptada", resultado["accepted"], 1)
	_comprobar("duplicado ignorado", resultado["duplicates"], 1)
	_comprobar("peso sale de reglas, no del cliente", resultado["snapshot"]["community_progress"], 1)
	_comprobar("fase resistencia tras progreso", resultado["snapshot"]["phase"], "resistencia")


func _probar_contribucion_sin_puntos_cliente() -> void:
	var contribucion := _contribucion("c-002", "coop_combat")
	var valida := MetaHasturDatos.validar_contribucion(contribucion)
	_comprobar("contribucion cerrada valida", valida["ok"], true)

	var manipulada: Dictionary = contribucion.duplicate(true)
	manipulada["progress"] = 100000
	var rechazada := MetaHasturDatos.validar_contribucion(manipulada)
	_comprobar("cliente no envia progreso", rechazada["ok"], false)
	_comprobar("razon campo inesperado", rechazada["reason"], "unexpected_progress")


func _contribucion(contribution_id: String, tipo: String) -> Dictionary:
	return {
		"contract_version": MetaHasturDatos.CONTRACT_VERSION,
		"rules_version": MetaHasturDatos.RULES_VERSION,
		"season_id": "pre1-fixture",
		"contribution_id": contribution_id,
		"actor_public_id": "anon-01",
		"type": tipo,
		"source_event_id": "source-%s" % contribution_id,
		"occurred_at": 2000000010,
	}


func _comprobar(nombre: String, actual: Variant, esperado: Variant) -> void:
	if actual == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado=%s actual=%s" % [nombre, str(esperado), str(actual)])
