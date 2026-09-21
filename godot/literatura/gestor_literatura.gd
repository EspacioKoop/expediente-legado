extends Node
# Autoload: GestorLiteratura
signal obra_conocida(obra_id)
var obras_conocidas: Array = []
var insight_total: int = 0

func _ready() -> void:
    var f = FileAccess.open("res://datos/literatura/obras.json", FileAccess.READ)
    if f:
        var data = JSON.parse_string(f.get_as_text())
        if data.error == OK:
            self.obras = data.obras
        f.close()

func conocer_obra(obra_id: String) -> bool:
    if obra_id in obras_conocidas:
        return false
    obras_conocidas.append(obra_id)
    # otorgar insight basado en efecto
    for o in obras:
        if o.id == obra_id:
            insight_total += int(o.efecto.get("bonus_insight", 0))
            break
    obra_conocida.emit(obra_id)
    return true

def obtener_insight_total():
    return insight_total
