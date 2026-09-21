extends CharacterBody3D
class_name NPCMentorLiterario

@onready var area_dialogo = $AreaDialogo
@export var autor_asociado: String = "cervantes"
@export var dialogos: Array = []

var jugador_en_rango: bool = false
var dialogo_actual: int = 0


func _ready() -> void:
	_cargar_dialogos()
	area_dialogo.area_entered.connect(_on_jugador_entra)
	area_dialogo.area_exited.connect(_on_jugador_sale)


func _cargar_dialogos() -> void:
	dialogos = [
		{"texto": "Bienvenido a la tertulia. ¿Buscas sabiduría en las páginas?", "requisito": {}},
		{
			"texto": "He leído tu camino. La Sombra y la Anima bailan en ti.",
			"requisito": {"arquetipos": ["sombra", "anima"]},
		},
		{
			"texto":
			"Cervantes me susurró: 'El que lee mucho y anda mucho, ve mucho y sabe mucho'.",
			"requisito": {"autor": "cervantes"},
		},
		{
			"texto":
			"¿Conoces el secreto de la Metamorfosis? Kafka lo guardó para los que transforman su momentum.",
			"requisito": {"obra": "metamorfosis", "arquetipo": "sombra"},
		},
		{
			"texto": "El Self se revela en la no-linealidad. Cortázar lo sabía.",
			"requisito": {"obra": "rayuela", "arquetipo": "self"},
		},
		{
			"texto": "Tu momentum es fuerte. ¿Has probado a citar a Homero en medio del combate?",
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
			print("Tertulia: %s" % dialogo.get("texto", ""))
			_aplicar_recompensa_dialogo(requisito)
			dialogo_actual = indice
			break


func _arquetipo_desbloqueado(id: String):
	var arquetipo = GestorArquetipos.obtener_arquetipo(id)
	if arquetipo == null or not bool(arquetipo.desbloqueado):
		return null
	return arquetipo


func _cumple_requisitos(req: Dictionary) -> bool:
	if req.is_empty():
		return true
	if req.has("arquetipos"):
		for id in req.get("arquetipos", []):
			if _arquetipo_desbloqueado(String(id)) == null:
				return false
	if req.has("autor") and req.get("autor") not in GestorLiteratura.autores_conocidos:
		return false
	if req.has("obra") and req.get("obra") not in GestorLiteratura.obras_conocidas:
		return false
	if req.has("arquetipo"):
		if _arquetipo_desbloqueado(String(req.get("arquetipo", ""))) == null:
			return false
	if req.has("momentum") and GestorMomentum.momentum_actual < req.get("momentum", 0):
		return false
	return true


func _aplicar_recompensa_dialogo(req: Dictionary) -> void:
	if req.get("autor") == "cervantes":
		GestorArquetipos.ganar_insight(25)
	if req.get("obra") == "metamorfosis":
		var sombra = _arquetipo_desbloqueado("sombra")
		if sombra != null:
			sombra.efecto_combate["bonus_crit"] = (
				float(sombra.efecto_combate.get("bonus_crit", 0.0)) + 0.05
			)
	if req.get("obra") == "rayuela" and _arquetipo_desbloqueado("self") != null:
		GestorArquetipos.ganar_insight(20)
	if req.get("momentum") == 50:
		GestorMomentum.momentum_actual = min(
			GestorMomentum.momentum_max,
			GestorMomentum.momentum_actual + 20,
		)
