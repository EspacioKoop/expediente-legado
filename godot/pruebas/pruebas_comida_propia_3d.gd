extends SceneTree

const ComidaPropia := preload("res://guion/comida_propia_interactiva_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar() -> void:
	var comida := ComidaPropia.new()
	root.add_child(comida)
	comida.configurar(15)

	_comprobar(comida.texto_accion() == "Comer algo (15)", "el prompt enseña el coste")
	_comprobar(comida.disponible(), "empieza disponible")
	_comprobar(comida.get_node_or_null("PlatoCena") != null, "tiene plato visible")
	_comprobar(comida.get_node_or_null("ComidaCena") != null, "tiene comida visible")
	_comprobar(
		comida.find_children("*", "CollisionShape3D", true, false).size() == 1,
		"expone un volumen de interacción"
	)

	comida.consumir()
	_comprobar(not comida.disponible(), "consumir bloquea el segundo cobro")
	_comprobar(comida.texto_accion() == "Ya has comido", "consumir deja feedback local")
	var visual := comida.get_node("ComidaCena") as Node3D
	_comprobar(not visual.visible, "la comida desaparece del plato al consumirla")
	comida.queue_free()

	var saciado := ComidaPropia.new()
	root.add_child(saciado)
	saciado.configurar(15)
	saciado.marcar_saciado()
	_comprobar(not saciado.disponible(), "sin hambre no ofrece otra compra")
	_comprobar(saciado.texto_accion() == "No tienes hambre", "el objeto explica por qué no se come")
	saciado.queue_free()

	var pobre := ComidaPropia.new()
	root.add_child(pobre)
	pobre.configurar(15)
	pobre.marcar_sin_dinero()
	_comprobar(pobre.disponible(), "sin dinero no consume la cena")
	_comprobar(
		pobre.texto_accion() == "No te alcanza para comer (15)",
		"la falta de saldo se explica en el objeto"
	)
	pobre.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO ComidaPropia3D: " + nombre)
