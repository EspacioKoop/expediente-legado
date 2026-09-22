extends Node

# Autoload: GestorCombos
signal combo_ejecutado(nombre_combo, efectos)
signal finisher_ejecutado(nombre, efectos, es_super)

const MAX_BUFFER: int = 6
const TIEMPO_BUFFER: float = 2.0

var combos_disponibles: Dictionary = {
	"golpe_sombra":
	{
		"nombre": "Golpe de la Sombra",
		"requisitos": {"momentum_min": 30, "arquetipo": "sombra"},
		"secuencia": ["ataque_ligero", "ataque_ligero", "ataque_pesado"],
		"efectos": {"daño_multiplier": 2.0, "aplicar_sombra": true, "area": 2.0},
	},
	"abrazo_anima":
	{
		"nombre": "Abrazo del Anima",
		"requisitos": {"momentum_min": 40, "arquetipo": "anima"},
		"secuencia": ["ataque_pesado", "esquivar", "ataque_ligero"],
		"efectos": {"curacion_area": 30, "buff_aliados": {"resistencia": 0.2, "duracion": 10}},
	},
	"danza_persona":
	{
		"nombre": "Danza de la Persona",
		"requisitos": {"momentum_min": 35, "arquetipo": "persona"},
		"secuencia": ["esquivar", "ataque_ligero", "esquivar", "ataque_pesado"],
		"efectos": {"evasion_temporal": 0.5, "duracion": 5, "contragolpe": true},
	},
	"despertar_self":
	{
		"nombre": "Despertar del Self",
		"requisitos": {"momentum_min": 100, "arquetipo": "self"},
		"secuencia": ["ataque_pesado", "ataque_pesado", "ataque_pesado", "ataque_pesado"],
		"efectos":
		{
			"daño_masivo": 500,
			"area": 5.0,
			"stun": 3.0,
			"buff_permanente": {"stats": 0.1},
		},
	},
}

var finishers: Dictionary = {
	"sombra_desatada":
	{
		"nombre": "Desatamiento de la Sombra",
		"costo_momentum": 75,
		"es_super": false,
		"efectos":
		{
			"daño_verdadero": 200,
			"miedo_enemigos": 4.0,
			"buff_jugador": {"crit": 0.3, "duracion": 15},
		},
	},
	"furia_divina":
	{
		"nombre": "Furia del Dios",
		"costo_momentum": 100,
		"es_super": true,
		"efectos":
		{
			"daño_divino": 500,
			"area": 8.0,
			"curacion_total": true,
			"invulnerabilidad": 5.0,
			"buff_permanente": {"todo": 0.15},
		},
	},
}

var buffer_entradas: Array = []


func _ready() -> void:
	pass


func reiniciar() -> void:
	buffer_entradas.clear()


func finisher_disponible_actual() -> String:
	var momentum := _gestor("GestorMomentum")
	if momentum == null:
		return ""
	var disponible := ""
	var mayor_costo := -1.0
	for finisher_id in finishers:
		var finisher: Dictionary = finishers[finisher_id]
		var costo := float(finisher.get("costo_momentum", 0.0))
		if costo <= float(momentum.momentum_actual) and costo > mayor_costo:
			disponible = String(finisher_id)
			mayor_costo = costo
	return disponible


func _process(_delta: float) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	var recientes: Array = []
	for entrada in buffer_entradas:
		if ahora - float(entrada.get("tiempo", 0.0)) < TIEMPO_BUFFER:
			recientes.append(entrada)
	buffer_entradas = recientes


func registrar_entrada(accion: String) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	buffer_entradas.append({"accion": accion, "tiempo": ahora})
	if buffer_entradas.size() > MAX_BUFFER:
		buffer_entradas.pop_front()
	_verificar_combos()


func _verificar_combos() -> void:
	var secuencia_actual: Array = []
	for entrada in buffer_entradas:
		secuencia_actual.append(String(entrada.get("accion", "")))

	for combo_id in combos_disponibles:
		var combo: Dictionary = combos_disponibles[combo_id]
		if _coincide_secuencia(secuencia_actual, combo.get("secuencia", [])):
			if _cumple_requisitos(combo.get("requisitos", {})):
				var efectos: Dictionary = combo.get("efectos", {}).duplicate(true)
				if efectos.has("daño_multiplier") and not efectos.has("dano_multiplier"):
					efectos["dano_multiplier"] = efectos["daño_multiplier"]
				combo_ejecutado.emit(combo.get("nombre", combo_id), efectos)
				buffer_entradas.clear()
				return


func _coincide_secuencia(buffer: Array, objetivo: Array) -> bool:
	if buffer.size() < objetivo.size():
		return false
	for indice in range(objetivo.size()):
		if buffer[buffer.size() - objetivo.size() + indice] != objetivo[indice]:
			return false
	return true


func _cumple_requisitos(req: Dictionary) -> bool:
	var momentum := _gestor("GestorMomentum")
	var arquetipos := _gestor("GestorArquetipos")
	if momentum == null or arquetipos == null:
		return false

	if (
		req.has("momentum_min")
		and float(momentum.get("momentum_actual")) < float(req.get("momentum_min", 0))
	):
		return false
	if req.has("arquetipo"):
		var arquetipo = arquetipos.call("obtener_arquetipo", String(req.get("arquetipo", "")))
		if arquetipo == null or not bool(arquetipo.desbloqueado):
			return false
	return true


func ejecutar_finisher(nombre: String) -> bool:
	if not finishers.has(nombre):
		return false

	var finisher: Dictionary = finishers[nombre]
	var momentum := _gestor("GestorMomentum")
	if momentum == null:
		return false
	if float(momentum.get("momentum_actual")) >= float(finisher.get("costo_momentum", 0)):
		var tipo := "super" if bool(finisher.get("es_super", false)) else "normal"
		var efectos: Dictionary = finisher.get("efectos", {}).duplicate(true)
		if not efectos.has("dano"):
			if efectos.has("daño_divino"):
				efectos["dano"] = efectos["daño_divino"]
			elif efectos.has("daño_verdadero"):
				efectos["dano"] = efectos["daño_verdadero"]
		if not bool(momentum.call("ejecutar_finisher", tipo)):
			return false
		(
			finisher_ejecutado
			. emit(
				finisher.get("nombre", nombre),
				efectos,
				finisher.get("es_super", false),
			)
		)
		return true
	return false

func _gestor(nombre: String) -> Node:
	var padre := get_parent()
	if padre == null:
		return null
	return padre.get_node_or_null(nombre)
