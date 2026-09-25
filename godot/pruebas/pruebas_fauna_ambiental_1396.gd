extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_catalogo()
	_probar_reproducibilidad()
	await _probar_montaje_sin_fisica()
	_probar_movimiento()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_catalogo() -> void:
	var calle := FaunaAmbiental.plan("trayecto", {}, 4, 12345)
	var especies_calle := _especies(calle)
	_comprobar(calle.size() == 6, "#1396: la calle monta seis presencias acotadas")
	for especie in ["paloma", "gorrion", "perro"]:
		_comprobar(especies_calle.has(especie), "#1396: calle contiene " + especie)

	var espacio := {
		"entrada": Vector3(0, 0, 4),
		"salidas": [{"pos": Vector3(0, 1.1, -12)}],
	}
	var sueno := FaunaAmbiental.plan("sueño", espacio, 4, 12345, "crucero")
	var especies_sueno := _especies(sueno)
	_comprobar(sueno.size() == 6, "#1396: el sueño monta seis presencias acotadas")
	for especie in ["cuervo", "polilla", "ciervo"]:
		_comprobar(especies_sueno.has(especie), "#1396: sueño contiene " + especie)
	_comprobar(not especies_calle.has("gato"), "#1396: no duplica el gato sistémico")


func _probar_reproducibilidad() -> void:
	var a := FaunaAmbiental.plan("trayecto", {}, 7, 777)
	var b := FaunaAmbiental.plan("trayecto", {}, 7, 777)
	_comprobar(a == b, "#1396: misma raíz y día producen el mismo reparto")
	var c := FaunaAmbiental.plan("trayecto", {}, 8, 777)
	_comprobar(a != c, "#1396: otro día puede variar la presentación")


func _probar_montaje_sin_fisica() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var animador := AnimadorAmbiental3D.new()
	root.add_child(animador)
	var capa := FaunaAmbiental3D.new()
	mundo.add_child(capa)
	var animales := capa.montar("trayecto", {}, 2, 19, "", animador)
	await process_frame
	_comprobar(animales.size() == 6, "#1396: se montan las seis piezas de calle")
	_comprobar(
		mundo.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"#1396: la fauna no añade colisiones",
	)
	_comprobar(
		mundo.find_children("*", "Area3D", true, false).is_empty(),
		"#1396: la fauna no añade triggers",
	)
	_comprobar(
		int(animador.estado()["piezas"]) == animales.size(),
		"#1396: todas las piezas comparten el animador ambiental",
	)
	mundo.queue_free()
	animador.queue_free()
	await process_frame


func _probar_movimiento() -> void:
	var dato := FaunaAmbiental.plan("trayecto", {}, 3, 991)[0]
	var animal := AnimalAmbiental3D.new()
	root.add_child(animal)
	animal.configurar(dato, null, false)
	var a := animal.desplazamiento_en(12.5)
	var b := animal.desplazamiento_en(12.5)
	_comprobar(a == b, "#1396: el movimiento es función del tiempo acumulado")
	var origen := animal.position
	animal.animar_pieza(animal.id_fauna(), 12.5, 1.0, AnimacionAmbiental.LOD_CERCA)
	_comprobar(animal.position != origen, "#1396: una pieza activa cambia de pose espacial")

	var quieto := AnimalAmbiental3D.new()
	root.add_child(quieto)
	quieto.configurar(dato, null, true)
	var origen_quieto := quieto.position
	quieto.animar_pieza(quieto.id_fauna(), 12.5, 1.0, AnimacionAmbiental.LOD_CERCA)
	_comprobar(
		quieto.position == origen_quieto,
		"#1396: reducción de movimiento conserva presencia sin desplazamiento",
	)
	animal.queue_free()
	quieto.queue_free()


func _especies(plan: Array) -> Array[String]:
	var resultado: Array[String] = []
	for dato in plan:
		var especie := String((dato as Dictionary).get("especie", ""))
		if not resultado.has(especie):
			resultado.append(especie)
	return resultado


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO FaunaAmbiental: " + nombre)
