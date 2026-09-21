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
        {"texto": "He leído tu camino. La Sombra y la Anima bailan en ti.", "requisito": {"arquetipos": ["sombra", "anima"]}},
        {"texto": "Cervantes me susurró: 'El que lee mucho y anda mucho, ve mucho y sabe mucho'.", "requisito": {"autor": "cervantes"}},
        {"texto": "¿Conoces el secreto de la Metamorfosis? Kafka lo guardó para los que transforman su momentum.", "requisito": {"obra": "metamorfosis", "arquetipo": "sombra"}},
        {"texto": "El Self se revela en la no-linealidad. Cortázar lo sabía.", "requisito": {"obra": "rayuela", "arquetipo": "self"}},
        {"texto": "Tu momentum es fuerte. ¿Has probado a citar a Homero en medio del combate?", "requisito": {"momentum": 50, "obra": "odisea"}},
    ]

func _on_jugador_entra(area: Area3D) -> void:
    if area.is_in_group("jugador"):
        jugador_en_rango = True
        _mostrar_dialogo_disponible()

func _on_jugador_sale(area: Area3D) -> void:
    if area.is_in_group("jugador"):
        jugador_en_rango = False

func _mostrar_dialogo_disponible() -> void:
    for i, d in enumerate(dialogos):
        if _cumple_requisitos(d.requisito):
            print(f"Tertulia: {d.texto}")
            _aplicar_recompensa_dialogo(d.requisito)
            dialogo_actual = i
            break

func _cumple_requisitos(req: Dictionary) -> bool:
    if not req:
        return True
    if req.has("arquetipos"):
        for a in req.arquetipos:
            if not GestorArquetipos.obtener_arquetipo(a)?.desbloqueado:
                return False
    if req.has("autor"):
        if req.autor not in GestorLiteratura.autores_conocidos:
            return False
    if req.has("obra"):
        if req.obra not in GestorLiteratura.obras_conocidas:
            return False
    if req.has("arquetipo"):
        if not GestorArquetipos.obtener_arquetipo(req.arquetipo)?.desbloqueado:
            return False
    if req.has("momentum"):
        if GestorMomentum.momentum_actual < req.momentum:
            return False
    return True

func _aplicar_recompensa_dialogo(req: Dictionary) -> void:
    if req.has("autor") and req.autor == "cervantes":
        GestorArquetipos.ganar_insight(25)
    if req.has("obra") and req.obra == "metamorfosis":
        # bonus crit para sombra
        if GestorArquetipos.obtener_arquetipo("sombra")?.desbloqueado:
            GestorArquetipos.obtener_arquetipo("sombra").efecto_combate.bonus_crit += 0.05
    if req.has("obra") and req.obra == "rayuela":
        if GestorArquetipos.obtener_arquetipo("self")?.desbloqueado:
            GestorArquetipos.ganar_insight(20)
    if req.has("momentum") and req.momentum == 50:
        GestorMomentum.momentum_actual = min(GestorMomentum.momentum_max, GestorMomentum.momentum_actual + 20)
