extends Node

signal combo_ejecutado(nombre_combo: String, efectos: Dictionary)
signal finisher_ejecutado(nombre: String, efectos: Dictionary, es_super: bool)

const MAX_BUFFER := 6
const TIEMPO_BUFFER := 2.0

var combos_disponibles: Dictionary = {
	"golpe_sombra":
	{
		"nombre": "Golpe de la Sombra",
		"requisitos": {"momentum_min": 30.0, "arquetipo": "sombra"},
		"secuencia": ["ataque_ligero", "ataque_ligero", "ataque_pesado"],
		"efectos": {"dano_multiplier": 2.0, "aplicar_sombra": true, "area": 2.0},
	},
	"abrazo_anima":
	{
		"nombre": "Abrazo del Anima",
		"requisitos": {"momentum_min": 40.0, "arquetipo": "anima"},
		"secuencia": ["ataque_pesado", "esquivar", "ataque_ligero"],
		"efectos": {"curacion": 2, "resistencia_temporal": 0.2},
	},
	"danza_persona":
	{
		"nombre": "Danza de la Persona",
		"requisitos": {"momentum_min": 35.0, "arquetipo": "persona"},
		"secuencia": ["esquivar", "ataque_ligero", "esquivar", "ataque_pesado"],
		"efectos": {"evasion_temporal": 0.5, "duracion": 1.0, "contragolpe": true},
	},
	"despertar_self":
	{
		"nombre": "Despertar del Self",
		"requisitos": {"momentum_min": 100.0, "arquetipo": "self"},
		"secuencia": ["ataque_pesado", "ataque_pesado", "ataque_pesado", "ataque_pesado"],
		"efectos": {"dano": 4, "area": 5.0, "stun": 1.0},
	},
}

var finishers: Dictionary = {
	"sombra_desatada":
	{
		"nombre": "Desatamiento de la Sombra",
		"arquetipo": "sombra",
		"costo_momentum": 75.0,
		"es_super": false,
		"efectos": {"dano": 3, "miedo": 1.0},
	},
	"furia_self":
	{
		"nombre": "Conjunción del Self",
		"arquetipo": "self",
		"costo_momentum": 100.0,
		"es_super": true,
		"efectos": {"dano": 5, "curacion_total": true, "invulnerabilidad": 1.0},
	},
}

var buffer_entradas: Array = []


func _process(_delta: float) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	buffer_entradas = buffer_entradas.filter(
		func(entrada): return ahora - float(entrada.get("tiempo", 0.0)) < TIEMPO_BUFFER
	)


func registrar_entrada(accion: String) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	buffer_entradas.append({"accion": accion, "tiempo": ahora})
	if buffer_entradas.size() > MAX_BUFFER:
		buffer_entradas.pop_front()
	_verificar_combos()


func ejecutar_finisher(finisher_id: String) -> bool:
	if not finishers.has(finisher_id):
		return false
	var finisher: Dictionary = finishers[finisher_id]
	if not _arquetipo_desbloqueado(String(finisher.get("arquetipo", ""))):
		return false
	var momentum = get_node_or_null("/root/GestorMomentum")
	if momentum == null:
		return false
	var es_super := bool(finisher.get("es_super", false))
	if not momentum.ejecutar_finisher("super" if es_super else "normal"):
		return false
	finisher_ejecutado.emit(
		String(finisher.get("nombre", finisher_id)),
		finisher.get("efectos", {}).duplicate(true),
		es_super
	)
	return true


func finisher_disponible_actual() -> String:
	var momentum = get_node_or_null("/root/GestorMomentum")
	if momentum == null:
		return ""
	for finisher_id in ["furia_self", "sombra_desatada"]:
		var finisher: Dictionary = finishers[finisher_id]
		if (
			momentum.momentum_actual >= float(finisher.get("costo_momentum", 0.0))
			and _arquetipo_desbloqueado(String(finisher.get("arquetipo", "")))
		):
			return finisher_id
	return ""


func reiniciar() -> void:
	buffer_entradas.clear()


func _verificar_combos() -> void:
	var secuencia_actual := buffer_entradas.map(func(entrada): return entrada.get("accion", ""))
	for combo_id in combos_disponibles:
		var combo: Dictionary = combos_disponibles[combo_id]
		if (
			_coincide_secuencia(secuencia_actual, combo.get("secuencia", []))
			and _cumple_requisitos(combo.get("requisitos", {}))
		):
			combo_ejecutado.emit(
				String(combo.get("nombre", combo_id)), combo.get("efectos", {}).duplicate(true)
			)
			buffer_entradas.clear()
			return


func _coincide_secuencia(buffer: Array, objetivo: Array) -> bool:
	if buffer.size() < objetivo.size():
		return false
	for i in objetivo.size():
		if buffer[buffer.size() - objetivo.size() + i] != objetivo[i]:
			return false
	return true


func _cumple_requisitos(requisitos: Dictionary) -> bool:
	var momentum = get_node_or_null("/root/GestorMomentum")
	if momentum == null:
		return false
	if (
		requisitos.has("momentum_min")
		and momentum.momentum_actual < float(requisitos["momentum_min"])
	):
		return false
	if requisitos.has("arquetipo"):
		return _arquetipo_desbloqueado(String(requisitos["arquetipo"]))
	return true


func _arquetipo_desbloqueado(arquetipo_id: String) -> bool:
	if arquetipo_id.is_empty():
		return true
	var gestor = get_node_or_null("/root/GestorArquetipos")
	if gestor == null:
		return false
	var arquetipo = gestor.obtener_arquetipo(arquetipo_id)
	return arquetipo != null and arquetipo.desbloqueado
