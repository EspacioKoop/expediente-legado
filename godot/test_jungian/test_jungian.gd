extends Node3D


func _ready() -> void:
	var arquetipos := get_node_or_null("/root/GestorArquetipos")
	var momentum := get_node_or_null("/root/GestorMomentum")
	var combos := get_node_or_null("/root/GestorCombos")
	if arquetipos != null:
		arquetipos.call("reiniciar")
		arquetipos.call("ganar_insight", 350)
	if momentum != null:
		momentum.call("reiniciar")
	if combos != null:
		combos.call("reiniciar")

	var combate := JuicioCombate3D.new()
	combate.name = "ArenaJungianaPrueba"
	combate.configurar(
		{"id": "rival-jungiano-prueba", "nombre": "Rival de prueba"},
		0,
		false
	)
	add_child(combate)
