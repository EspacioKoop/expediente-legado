extends Node
# Autoload: GestorLiteratura
signal obra_conocida(obra_id)
var obras_conocidas: Array = []
var insight_total: int = 0
var momentum_bonus: float = 0.0  # acumulativo temporal

func _ready() -> void:
    var f = FileAccess.open("res://datos/literatura/obras.json", FileAccess.READ)
    if f:
        var data = JSON.parse_string(f.get_as_text())
        if data.error == OK:
            self.obras = data.obras
        f.close()

func conocer_obra(obra_id: String) -> bool:
    if obra_id in obras_conocidas:
        return False
    obras_conocidas.append(obra_id)
    # otorgar insight basado en efecto
    var efecto = _obtener_efecto_obra(obra_id)
    if efecto.has("bonus_insight"):
        self.insight_total += int(efecto.bonus_insight)
    if efecto.has("bonus_momentum"):
        self.momentum_bonus += float(efecto.momentum_bonus)
        # aplicar momentum bonus inmediatamente al gestor de momentum
        GestorMomentum.momentum_actual = min(GestorMomentum.momentum_max, GestorMomentum.momentum_actual + efecto.bonus_momentum)
    obra_conocida.emit(obra_id)
    return True

func obtener_insight_total():
    return self.insight_total

func obtener_momentum_bonus():
    return self.momentum_bonus

func _obtener_efecto_obra(obra_id: String) -> Dictionary:
    var file = FileAccess.open("res://datos/literatura/obras.json", FileAccess.READ)
    if file:
        var data = JSON.parse_string(file.get_as_text())
        if data.error == OK:
            for o in data.obras:
                if o.id == obra_id:
                    file.close()
                    return o.efecto
        file.close()
    return {}
