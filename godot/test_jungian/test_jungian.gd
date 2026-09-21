extends Node3D


func _ready() -> void:
	GestorArquetipos.reiniciar()
	GestorMomentum.reiniciar()
	GestorCombos.reiniciar()
	GestorArquetipos.ganar_insight(350)

	var combate := JuicioCombate3D.new()
	combate.name = "ArenaJungianaPrueba"
	combate.configurar(
		{"id": "rival-jungiano-prueba", "nombre": "Rival de prueba"},
		0,
		false
	)
	add_child(combate)
