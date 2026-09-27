extends SceneTree

const Senaletica := preload("res://guion/senaletica_oficina_98.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)

	var conjunto := Senaletica.montar(mundo)
	var repetido := Senaletica.montar(mundo)

	_comprobar(conjunto == repetido, "montaje idempotente")
	_comprobar(conjunto.get_child_count() == 3, "hay tres láminas")

	for nombre in ["SalidaEmergencia", "Extintor", "Calendario"]:
		var lamina := conjunto.get_node_or_null(nombre) as MeshInstance3D
		_comprobar(lamina != null, "existe " + nombre)
		if lamina == null:
			continue
		_comprobar(lamina.mesh is QuadMesh, nombre + " usa un plano fijo")
		_comprobar(
			lamina.material_override is StandardMaterial3D, nombre + " tiene material propio"
		)

	_comprobar(
		conjunto.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"no añade colisiones"
	)
	_comprobar(conjunto.find_children("*", "Sprite3D", true, false).is_empty(), "no usa billboards")

	var salida := conjunto.get_node("SalidaEmergencia") as MeshInstance3D
	_comprobar(is_equal_approx(salida.rotation_degrees.y, 90.0), "salida sigue la pared lateral")
	var extintor := conjunto.get_node("Extintor") as MeshInstance3D
	_comprobar(is_equal_approx(extintor.rotation_degrees.y, 180.0), "extintor mira al interior")
	var calendario := conjunto.get_node("Calendario") as MeshInstance3D
	_comprobar(is_zero_approx(calendario.rotation_degrees.y), "calendario queda fijo al fondo")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	mundo.queue_free()
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SenaleticaOficina98: " + nombre)
