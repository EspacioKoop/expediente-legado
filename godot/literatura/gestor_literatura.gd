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
        return false
    obras_conocidas.append(obra_id)
    # otorgar insight basado en efecto
    var efecto = _obtener_efecto_obra(obra_id)
    if efecto.has("bonus_insight"):
        insight_total += int(efecto.bonus_insight)
    if efecto.has("bonus_momentum"):
        momentum_bonus += float(efecto.momentum_bonus)
        # aplicar momentum bonus inmediatamente al gestor de momentum
        GestorMomentum.momentum_actual = min(GestorMomentum.momentum_max, GestorMomentum.momentum_actual + efecto.bonus_monmentum)
    obra_conocida.emit(obra_id)
    return true

func obtener_insight_total():
    return insight_total

func obtener_momentum_bonus():
    return momentum_bonus

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

func _aplicar_efecto_especial(obra_id: String, efecto: String) -> void:
    match efecto:
        "revelacion":
            # desbloquea dialogos internos en el arquetipo Persona
            if GestorArquetipos.obtener_arquetipo("persona")?.desbloqueado:
                GestorArquetipos.ganar_insight(20)
                # Activar bonus temporal de evasion para Persona
                GestorArquetipos.obtener_arquetipo("persona").efecto_combate.evasion_temporal = 0.3
        "transformacion":
            # efecto visual de metamorfosis temporal - afecta a Sombra
            if GestorArquetipos.obtener_arquetipo("sombra")?.desbloqueado:
                GestorArquetipos.obtener_arquetipo("sombra").efecto_combate.bonus_crit += 0.1
        "no_linealidad":
            # permite leer obras en cualquier orden - afecta a Self
            if GestorArquetipos.obtener_arquetipo("self")?.desbloqueado:
                GestorArquetipos.ganar_insight(15)
        "ciclos_temporales":
            # Cien años de soledad - momentum bonus ciclico
            GestorMomentum.momentum_actual = min(GestorMomentum.momentum_max, GestorMomentum.momentum_actual + 15)
        "corriente_conciencia":
            # Ulises - maximo insight pero drena momentum
            GestorArquetipos.ganar_insight(30)
            GestorMomentum.momentum_actual = max(0, GestorMomentum.momentum_actual - 20)

func _aplicar_cita_especial(obra_id: String, efecto: String) -> void:
    match efecto:
        "revelacion":
            # reveal enemy weakness - aplica debuff a enemigos cercanos
            print("Revelacion: debilidad enemiga expuesta - Anima cura aliados")
            if GestorArquetipos.obtener_arquetipo("anima")?.desbloqueado:
                # Trigger anima healing effect
                pass
        "transformacion":
            # temporary form change - Sombra desatada
            print("Transformacion: forma alternativa activada - Sombra desatada")
            if GestorArquetipos.obtener_arquetipo("sombra")?.desbloqueado:
                GestorMomentum.ejecutar_finisher("super")
        "no_linealidad":
            # shuffle combo requirements - Persona adapta
            print("No linealidad: combos desordenados temporalmente - Persona adapta")
        "ciclos_temporales":
            print("Ciclos temporales: momentum regenera rapido")
            GestorMomentum.decay_rate = 2.0
        "corriente_conciencia":
            print("Corriente de conciencia: insight instantaneo")
            GestorArquetipos.ganar_insight(50)

