extends SceneTree

var fallos := 0
var pasadas := 0


func _init() -> void:
	comprobar("interior sin clave conserva techo", PoliticaTecho.debe_tener({}), true)
	comprobar("interior explícito conserva techo", PoliticaTecho.debe_tener({"techo": true}), true)
	comprobar(
		"exterior explícito no tiene techo", PoliticaTecho.debe_tener({"techo": false}), false
	)

	var original := {"suelo": Vector2(9, 34), "color_techo": Color(0.1, 0.1, 0.13)}
	var exterior := PoliticaTecho.marcar_exterior(original)
	comprobar("marcar exterior desactiva techo", exterior["techo"], false)
	comprobar("marcar exterior conserva el tamaño", exterior["suelo"], original["suelo"])
	comprobar("marcar exterior no muta el original", original.has("techo"), false)

	var interior := Node3D.new()
	get_root().add_child(interior)
	Espacio3D.construir(interior, {"suelo": Vector2(2, 2)})
	comprobar("interior rectangular crea seis cuerpos", _cuerpos(interior), 6)

	var exterior_raiz := Node3D.new()
	get_root().add_child(exterior_raiz)
	Espacio3D.construir(exterior_raiz, {"suelo": Vector2(2, 2), "techo": false})
	comprobar("exterior rectangular omite solo el techo", _cuerpos(exterior_raiz), 5)

	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])


func _cuerpos(raiz: Node3D) -> int:
	var total := 0
	for hijo in raiz.get_children():
		if hijo is StaticBody3D:
			total += 1
	return total
