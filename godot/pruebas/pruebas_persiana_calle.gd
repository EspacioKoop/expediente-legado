extends SceneTree

const Persiana := preload("res://guion/persiana_calle_interactiva_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_persiana()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_persiana() -> void:
	var persiana := Persiana.new()
	root.add_child(persiana)
	persiana.configurar()

	_comprobar(not persiana.esta_abierta(), "empieza cerrada")
	_comprobar(persiana.texto_accion() == "Abrir persiana", "anuncia abrir")
	_comprobar(
		persiana.get_node_or_null("HojaPersianaCalle") != null,
		"la hoja visible forma parte del objeto"
	)
	_comprobar(
		persiana.find_children("*", "CollisionShape3D", true, false).size() == 1,
		"expone un volumen de interacción"
	)
	_comprobar(
		persiana.find_children("*", "MeshInstance3D", true, false).size() >= 20,
		"la persiana tiene guías y lamas reconocibles"
	)

	var posicion_cerrada := persiana.posicion_hoja()
	_comprobar(persiana.interactuar(root), "acepta la interacción semántica")
	_comprobar(persiana.esta_abierta(), "abre tras interactuar")
	_comprobar(persiana.texto_accion() == "Cerrar persiana", "actualiza el verbo")
	_comprobar(
		persiana.posicion_hoja().y > posicion_cerrada.y,
		"la hoja sube de forma visible"
	)

	_comprobar(persiana.interactuar(root), "acepta cerrar")
	_comprobar(not persiana.esta_abierta(), "vuelve a cerrada")
	_comprobar(persiana.texto_accion() == "Abrir persiana", "restaura el prompt")
	_comprobar(
		persiana.posicion_hoja().is_equal_approx(posicion_cerrada),
		"restaura la posición física"
	)
	persiana.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PersianaCalle: " + nombre)
