## Dressing reactivo para las salas compuestas del sueño (#400).
##
## No modifica Sueno/SuenoFormas: lee la forma que ya se eligió y coloca tres
## objetos familiares únicamente sobre celdas transitables. Uno queda delante de
## la entrada y los otros se reparten lejos entre sí, evitando también la salida.
class_name SuenoUtileria
extends RefCounted

const PRESCRIPCIONES := [
	{
		"modelo": "chairDesk",
		"tam": Vector3(0.62, 0.95, 0.62),
		"color": Color(0.30, 0.31, 0.38),
		"nombre": "silla demasiado alta",
		"escala": Vector3(1.15, 2.35, 0.72),
		"reaccion": Vector3(0.72, 1.35, 1.85),
		"giro": Vector3(0.0, 18.0, -7.0),
		"giro_reaccion": Vector3(0.0, 112.0, 8.0),
	},
	{
		"modelo": "computerScreen",
		"tam": Vector3(0.50, 0.45, 0.40),
		"color": Color(0.48, 0.55, 0.52),
		"nombre": "monitor estirado",
		"escala": Vector3(2.30, 0.72, 1.08),
		"reaccion": Vector3(0.88, 1.95, 1.30),
		"giro": Vector3(-6.0, -24.0, -10.0),
		"giro_reaccion": Vector3(9.0, 42.0, 13.0),
	},
	{
		"modelo": "bookcaseClosed",
		"tam": Vector3(1.0, 1.8, 0.6),
		"color": Color(0.34, 0.31, 0.38),
		"nombre": "archivador torcido",
		"escala": Vector3(0.58, 1.55, 1.42),
		"reaccion": Vector3(1.42, 0.72, 0.74),
		"giro": Vector3(0.0, 14.0, 6.0),
		"giro_reaccion": Vector3(0.0, -76.0, -9.0),
	},
]


static func montar(mundo: Node3D, id: String, dia: int, raiz_azar: int) -> Array:
	var forma := SuenoFormas.de(id)
	var bloques: Array = forma["bloques"]
	var entrada: Vector2i = forma["entrada"]
	var salida := Planta.mas_lejana(bloques, entrada)
	var primera := Planta.a_la_vista(bloques, entrada, 3)
	var celdas := [primera]
	celdas.append_array(Planta.repartidas(bloques, 2, [entrada, primera, salida]))

	# Mismo día + misma semilla = misma distribución. Cambiar de noche rota qué
	# objeto se encuentra primero sin introducir un sorteo imposible de reproducir.
	var semilla := Azar.derivar_texto(raiz_azar, "sueno", "utileria:%s" % id, [dia])
	var desplazamiento := posmod(semilla, PRESCRIPCIONES.size())
	var creadas := []
	for i in range(3):
		var datos: Dictionary = PRESCRIPCIONES[(i + desplazamiento) % PRESCRIPCIONES.size()]
		var anomalia := AnomaliaSueno3D.new()
		anomalia.name = "AnomaliaSueno%d" % (i + 1)
		var tam: Vector3 = datos["tam"]
		var escala: Vector3 = datos["escala"]
		anomalia.position = (
			Planta.centro_en_metros(bloques, celdas[i])
			+ Vector3(0.0, tam.y * absf(escala.y) * 0.5, 0.0)
		)
		mundo.add_child(anomalia)
		anomalia.configurar(
			datos["modelo"],
			tam,
			datos["color"],
			datos["nombre"],
			escala,
			datos["reaccion"],
			datos["giro"],
			datos["giro_reaccion"],
		)
		creadas.append(anomalia)
	return creadas
