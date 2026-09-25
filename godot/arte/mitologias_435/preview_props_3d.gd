extends Node3D


func _ready() -> void:
	var piezas := [
		["TablillaUruk", Mitologias435Props.tablilla_uruk(), Vector3(-9.0, 0.8, 0.0)],
		["Archivador", Mitologias435Props.archivador_onirico(), Vector3(-6.0, 0.0, 0.0)],
		["Aquiles", Mitologias435Props.panoplia_aquiles(), Vector3(-2.8, 0.0, 0.0)],
		["Hidra", Mitologias435Props.busto_hidra(), Vector3(0.2, 0.0, 0.0)],
		["Ryu", Mitologias435Props.compuerta_ryu(), Vector3(3.5, 0.0, 0.0)],
		["Duat", Mitologias435Props.balanza_duat(), Vector3(7.0, 0.0, 0.0)],
		["Legajo", Mitologias435Props.legajo_siga(), Vector3(10.2, 0.0, 0.0)],
	]
	for entrada in piezas:
		var pieza := entrada[1] as Node3D
		pieza.name = String(entrada[0])
		pieza.position = entrada[2]
		add_child(pieza)
