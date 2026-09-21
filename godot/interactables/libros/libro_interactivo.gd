extends Area3D

@onready var label = $InteractionLabel
@export var obra_id: String = "odisea"  # default

func _ready() -> void:
    label.visible = False

func _on_area_entered(area: Area3D) -> None:
    if area.is_in_group("jugador"):
        label.visible = True

func _on_area_exited(area: Area3D) -> None:
    if area.is_in_group("jugador"):
        label.visible = False

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> None:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        self._interactuar()
    if event is InputEventKey and event.pressed and event.scancode == KEY_E:
        self._interactuar()

func _interactuar(self) -> None:
    var gestor = GestorLiteratura
    if gestor.conocer_obra(self.obra_id):
        label.text = f"Has descubierto: {self.obra_id}"
        # otorgar insight adicional basado en efecto de obra
        var efecto = self._obtener_efecto_obra(self.obra_id)
        if efecto.has("bonus_insight"):
            GestorArquetipos.ganar_insight(int(efecto.bonus_insight))
        # reproducir sonido, particulas, etc.
        print(f"Interactuado con obra {self.obra_id}")
    else:
        label.text = "Ya conoces esta obra"
    yield(get_tree().create_timer(2.0), "timeout")
    label.text = "E para leer"

func _obtener_efecto_obra(self, obra_id: String) -> Dictionary:
    # carga datos desde JSON (simple version)
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
