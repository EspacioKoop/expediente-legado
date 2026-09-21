extends Control

@onready var selector = $Panel/VBoxContainer/ObraSelector
@onready var citar_btn = $Panel/VBoxContainer/CitarButton
@onready var close_btn = $Panel/VBoxContainer/CloseButton

func _ready() -> void:
    _poblar_selector()
    citar_btn.pressed.connect(_on_citar_pressed)
    close_btn.pressed.connect(hide)
    visible = False

func _poblar_selector() -> void:
    selector.clear()
    var gestor = GestorLiteratura
    for obra_id in gestor.obras_conocidas:
        # encontrar titulo
        var file = FileAccess.open("res://datos/literatura/obras.json", FileAccess.READ)
        if file:
            var data = JSON.parse_string(file.get_as_text())
            if data.error == OK:
                for o in data.obras:
                    if o.id == obra_id:
                        selector.add_item(o.titulo)
                        selector.set_item_metadata(selector.get_item_count() - 1, obra_id)
            file.close()

func _on_citar_pressed() -> void:
    var idx = selector.get_selected_id()
    if idx >= 0:
        var obra_id = selector.get_item_metadata(idx)
        _ejecutar_cita(obra_id)
    hide()

func _ejecutar_cita(obra_id: String) -> void:
    var efecto = _obtener_efecto_obra(obra_id)
    var momentum_cost = 30
    if GestorMomentum.momentum_actual >= momentum_cost:
        GestorMomentum.momentum_actual -= momentum_cost
        # aplicar efecto de la cita
        if efecto.has("efecto_especial"):
            _aplicar_cita_especial(obra_id, efecto.efecto_especial)
        else:
            # bonus generico
            GestorMomentum.momentum_actual = min(GestorMomentum.momentum_max, GestorMomentum.momentum_actual + 10)
        print(f"Citado {obra_id}, momentum restante: {GestorMomentum.momentum_actual}")

func _aplicar_cita_especial(obra_id: String, efecto: String) -> void:
    match efecto:
        "revelacion":
            # reveal enemy weakness
            print("Revelacion: debilidad enemiga expuesta")
        "transformacion":
            # temporary form change
            print("Transformacion: forma alternativa activada")
        "no_linealidad":
            # shuffle combo requirements
            print("No linealidad: combos desordenados temporalmente")

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

func show_ritual() -> void:
    _poblar_selector()
    visible = True
