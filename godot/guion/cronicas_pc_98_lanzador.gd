extends SceneTree


func _initialize() -> void:
	call_deferred("abrir")


func abrir() -> void:
	var programa := CronicasPc98.new()
	get_root().add_child(programa)
	programa.cerrar_solicitado.connect(quit)
