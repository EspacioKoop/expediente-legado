extends SceneTree

## Regresión de #787: el gato onírico conserva identidad visual aunque su
## decorado padre cambie de escala, rotación o posición.

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	mundo.position = Vector3(4.0, 1.0, -3.0)
	mundo.rotation = Vector3(0.18, 0.42, -0.11)
	mundo.scale = Vector3(2.4, 0.7, 1.6)

	var gato := Gato.new()
	mundo.add_child(gato)
	gato.empezar(Vector3(1.25, 0.0, -0.8), [Vector3(1.25, 0.0, -0.8)])
	var posicion_global := gato.global_position

	gato.anclar_presentacion_global()
	_comprobar(gato.top_level, "el gato queda fuera de la herencia de transformaciones")
	_comprobar(
		gato.global_position.is_equal_approx(posicion_global),
		"anclar conserva la posición global visible",
	)
	_comprobar(
		gato.global_basis.get_scale().is_equal_approx(Vector3.ONE),
		"la raíz recupera escala global normal",
	)
	_comprobar(
		gato.global_rotation.is_equal_approx(Vector3.ZERO),
		"la raíz recupera orientación global neutral",
	)

	mundo.position = Vector3(-8.0, 5.0, 12.0)
	mundo.rotation = Vector3(0.7, -1.1, 0.35)
	mundo.scale = Vector3(0.3, 4.0, 2.8)

	_comprobar(
		gato.global_position.is_equal_approx(posicion_global),
		"deformar el padre no desplaza al gato",
	)
	_comprobar(
		gato.global_basis.get_scale().is_equal_approx(Vector3.ONE),
		"deformar el padre no escala al gato",
	)

	gato.presentar_estado("durmiendo")
	_comprobar(
		String(gato.estado.get("estado", "")) == "durmiendo",
		"la conducta presentacional sigue funcionando",
	)
	_comprobar(
		gato.global_basis.get_scale().is_equal_approx(Vector3.ONE),
		"una pose de conducta no rompe la escala raíz estable",
	)

	gato.free()
	mundo.free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(actual: bool, nombre: String) -> void:
	if actual:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO ancla onírica gato #787: %s" % nombre)
