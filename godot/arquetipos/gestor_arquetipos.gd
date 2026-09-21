extends Node

# Autoload: GestorArquetipos
signal arquetipo_desbloqueado(arquetipo_id)
var arquetipos: Dictionary = {}
var insight_total: int = 0

func _ready() -> void:
    # Cargar desde datos JSON
    var file = FileAccess.open("res://datos/jungian_mitologia.json", FileAccess.READ)
    if file:
        var data = JSON.parse_string(file.get_as_text())
        if data.error == OK:
            for a in data.arquetipos:
                var script = load("res://arquetipos/%s.gd" % a.id)
                if script:
                    var inst = script.new()
                    arquetipos[a.id] = inst
        file.close()

func ganar_insight(cantidad: int) -> void:
    insight_total += cantidad
    _verificar_desbloqueos()

func _verificar_desbloqueos() -> void:
    for id, arq in arquetipos:
        if not arq.desbloqueado and insight_total >= arq.puntos_insight_requeridos:
            arq.desbloquear()
            arquetipo_desbloqueado.emit(id)

func obtener_arquetipo(id: String):
    return arquetipos.get(id)

func obtener_efectos_activos() -> Array:
    var efectos = []
    for arq in arquetipos.values():
        if arq.desbloqueado:
            efectos.append(arq.obtener_efecto())
    return efectos
