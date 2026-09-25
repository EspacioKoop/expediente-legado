extends Node

var fallos := 0


func _ready() -> void:
	var catalogo := ReconstruccionDocumental3D.catalogo()
	comprobar("catálogo", not catalogo.is_empty())
	var disponibles := ReconstruccionDocumental3D.para_registros(
		"caso@1", ["factura1@1", "actaContraloria1@1"]
	)
	comprobar("filtra por lectura", disponibles.size() == 2)
	if not disponibles.is_empty():
		var planos := ReconstruccionDocumental3D.planos_de(disponibles[0], true)
		comprobar("produce planos", planos.size() >= 2)
		for plano in planos:
			comprobar("reducción de movimiento", plano["camara"] == Vector3(-1.8, 1.55, 2.9))
	get_tree().quit(fallos)


func comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		print("OK: ", nombre)
	else:
		fallos += 1
		push_error("FALLO: " + nombre)
