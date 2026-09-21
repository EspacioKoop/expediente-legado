class_name NPCMentorLiterario
extends CharacterBody3D

@export var autor_asociado: String = "cervantes"
@export var dialogos: Array = []

var jugador_en_rango: bool = false
var dialogo_actual: int = 0

@onready var area_dialogo: Area3D = $AreaDialogo


func _ready() -> void:
	_cargar_dialogos()
	area_dialogo.area_entered.connect(_on_jugador_entra)
	area_dialogo.area_exited.connect(_on_jugador_sale)


func _cargar_dialogos() -> void:
	dialogos = [
		{
			"texto": "Bienvenido a la tertulia. ¿Buscas sabiduría en las páginas?",
			"requisito": {},
		},
		{
			"texto": "He leído tu camino. La Sombra y la Anima bailan en ti.",
			"requisito": {"arquetipos": ["sombra", "anima"]},
		},
		{
			"texto": "Cervantes recuerda que leer y andar ensanchan la mirada.",
			"requisito": {"autor": "cervantes"},
		},
		{
			"texto": "¿Conoces el secreto de la Metamorfosis?",
			"requisito": {"obra": "metamorfosis", "arquetipo": "sombra"},
		},
		{
			"texto": "El Self se revela en la no-linealidad.",
			"requisito": {"obra": "rayuela", "arquetipo": "self"},
		},
		{
			"texto": "Tu momentum es fuerte. Prueba una cita en combate.",
			"requisito": {"momentum": 50, "obra": "odisea"},
		},
	]


func _on_jugador_entra(area: Area3D) -> void:
	if area.is_in_group("jugador"):
		jugador_en_rango = true
		_mostrar_dialogo_disponible()


func _on_jugador_sale(area: Area3D) -> void:
	if area.is_in_group("jugador"):
		jugador_en_rango = false


func _mostrar_dialogo_disponible() -> void:
	for indice in range(dialogos.size()):
		var dialogo: Dictionary = dialogos[indice]
		var requisito: Dictionary = dialogo.get("requisito", {})
		if _cumple_requisitos(requisito):
			print("Tertulia: %s" % String(dialogo.get("texto", "")))
			_aplicar_recompensa_dialogo(requisito)
			dialogo_actual = indice
			return


func _cumple_requisitos(requisitos: Dictionary) -> bool:
	if requisitos.is_empty():
		return true
	var literatura := _gestor("GestorLiteratura")
	var arquetipos := _gestor("GestorArquetipos")
	var momentum := _gestor("GestorMomentum")
	if literatura == null or arquetipos == null or momentum == null:
		return false

	var cumple := true
	for arquetipo_id in requisitos.get("arquetipos", []):
		if not _arquetipo_desbloqueado(arquetipos, String(arquetipo_id)):
			cumple = false
			break
	if cumple and requisitos.has("autor"):
		var autores: Array = literatura.get("autores_conocidos")
		cumple = String(requisitos["autor"]) in autores
	if cumple and requisitos.has("obra"):
		var obras: Array = literatura.get("obras_conocidas")
		cumple = String(requisitos["obra"]) in obras
	if cumple and requisitos.has("arquetipo"):
		cumple = _arquetipo_desbloqueado(arquetipos, String(requisitos["arquetipo"]))
	if cumple and requisitos.has("momentum"):
		cumple = (float(momentum.get("momentum_actual")) >= float(requisitos["momentum"]))
	return cumple


func _aplicar_recompensa_dialogo(requisitos: Dictionary) -> void:
	var arquetipos := _gestor("GestorArquetipos")
	var momentum := _gestor("GestorMomentum")
	if arquetipos == null or momentum == null:
		return
	if requisitos.get("autor", "") == "cervantes":
		arquetipos.call("ganar_insight", 25)
	if (
		requisitos.get("obra", "") == "metamorfosis"
		and _arquetipo_desbloqueado(arquetipos, "sombra")
	):
		_sumar_bonus_sombra(arquetipos, 0.05)
	if requisitos.get("obra", "") == "rayuela" and _arquetipo_desbloqueado(arquetipos, "self"):
		arquetipos.call("ganar_insight", 20)
	if int(requisitos.get("momentum", 0)) == 50:
		momentum.call("agregar_momentum", 20.0)


func _arquetipo_desbloqueado(arquetipos: Node, arquetipo_id: String) -> bool:
	var arquetipo = arquetipos.call("obtener_arquetipo", arquetipo_id)
	return arquetipo != null and bool(arquetipo.get("desbloqueado"))


func _sumar_bonus_sombra(arquetipos: Node, cantidad: float) -> void:
	var sombra = arquetipos.call("obtener_arquetipo", "sombra")
	if sombra == null:
		return
	var efectos = sombra.get("efecto_combate")
	if typeof(efectos) != TYPE_DICTIONARY:
		return
	efectos["bonus_crit"] = float(efectos.get("bonus_crit", 0.0)) + cantidad
	sombra.set("efecto_combate", efectos)


func _gestor(nombre: String) -> Node:
	return get_node_or_null("/root/" + nombre)
