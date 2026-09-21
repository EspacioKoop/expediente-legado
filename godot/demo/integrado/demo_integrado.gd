extends Node3D

func _ready() -> void:
    print("Demo Integrado iniciado")
    print("Insight inicial:", GestorArquetipos.insight_total)
    print("Arquetipos desbloqueados:")
    for id in ["sombra", "anima", "persona", "self"]:
        arq = GestorArquetipos.obtener_arquetipo(id)
        if arq:
            print(f"  {id}: {arq.desbloqueado}")
    # Simulate reading a book by calling conocer_obra directly
    GestorLiteratura.conocer_obra("odisea")
    print("Despues de leer Odisea:")
    print("  Insight:", GestorArquetipos.insight_total)
    print("  Arquetipo sombra desbloqueado?", GestorArquetipos.obtener_arquetipo("sombra")?.desbloqueado)
    # Simulate some hits to build momentum
    GestorMomentum.registrar_golpe(es_critico=True)
    GestorMomentum.registrar_golpe()
    GestorMomentum.registrar_golpe()
    print("Momentum tras 3 golpes:", GestorMomentum.momentum_actual)
    # Try to unlock a combo if possible
    # Not needed for demo
