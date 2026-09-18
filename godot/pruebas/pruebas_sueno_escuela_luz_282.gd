extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)

	var base := Sueno.espacio("crucero", 0, {"frases": ["EXPEDIENTE CONOCIDO"]})
	var espacio := SuenoEscuela.adaptar_espacio(base, {"variante_aulas": 0})
	var presentacion := SuenoEscuela3D.montar(mundo, espacio)
	_comprobar(presentacion != null, "monta la presentación escolar")
	if presentacion == null:
		_terminar()
		return

	var luces := presentacion.find_children("LuzFluorescente*", "OmniLight3D", true, false)
	_comprobar(luces.size() == 4, "mantiene cuatro puntos de luz baratos")

	var entrada := presentacion.get_node_or_null("LuzFluorescente06") as OmniLight3D
	_comprobar(entrada != null, "el fluorescente de entrada emite luz real")
	if entrada != null:
		_comprobar(is_equal_approx(entrada.position.z, 10.0), "la luz queda junto a la entrada")
		_comprobar(entrada.light_energy >= 0.62, "la entrada conserva energía legible")
		_comprobar(entrada.omni_range >= 8.0, "la entrada alcanza props cercanos")

	_comprobar(
		presentacion.get_node_or_null("Fluorescente06") is MeshInstance3D,
		"la luminaria visible sigue existiendo",
	)
	_comprobar(
		presentacion.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"la corrección visual no añade colisiones",
	)
	_terminar()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SuenoEscuelaLuz282: " + nombre)


func _terminar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)
