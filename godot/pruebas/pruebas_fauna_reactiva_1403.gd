extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_catalogo_reactivo()
	_probar_reacciones()
	await _probar_gestos_y_reduccion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_catalogo_reactivo() -> void:
	for especie in ["paloma", "gorrion", "perro", "cuervo", "polilla", "ciervo"]:
		var ficha := FaunaAmbiental.ficha(especie)
		_comprobar(
			not String(ficha.get("reaccion", "")).is_empty(),
			"#1403: " + especie + " declara reacción",
		)
		_comprobar(
			float(ficha.get("distancia_alerta", 0.0)) > 0.0,
			"#1403: " + especie + " declara radio de alerta",
		)


func _probar_reacciones() -> void:
	var paloma := _animal("paloma")
	var cerca := paloma.origen() + Vector3(0, 0, 0.5)
	var reaccion_cerca := paloma.respuesta_proximidad(cerca, paloma.origen())
	var reaccion_repetida := paloma.respuesta_proximidad(cerca, paloma.origen())
	_comprobar(float(reaccion_cerca["peso"]) > 0.0, "#1403: paloma detecta proximidad")
	_comprobar(
		(reaccion_cerca["desplazamiento"] as Vector3).length() > 0.0,
		"#1403: paloma se aparta",
	)
	_comprobar(
		(reaccion_cerca["desplazamiento"] as Vector3).z < 0.0,
		"#1403: paloma se aparta en dirección opuesta al observador",
	)
	_comprobar(reaccion_cerca == reaccion_repetida, "#1403: reacción pura es determinista")

	var lejos := paloma.origen() + Vector3(20, 0, 0)
	var reaccion_lejos := paloma.respuesta_proximidad(lejos, paloma.origen())
	_comprobar(float(reaccion_lejos["peso"]) == 0.0, "#1403: fuera del radio no hay reacción")
	_comprobar(
		(reaccion_lejos["desplazamiento"] as Vector3).is_zero_approx(),
		"#1403: fuera del radio no altera trayectoria",
	)

	var perro := _animal("perro")
	var reaccion_perro := perro.respuesta_proximidad(
		perro.origen() + Vector3(0.4, 0, 0.4), perro.origen()
	)
	_comprobar(bool(reaccion_perro["mirar"]), "#1403: perro observa al jugador")
	_comprobar(
		float(reaccion_perro["factor_movimiento"]) < 1.0,
		"#1403: perro reduce deambular al observar",
	)
	_comprobar(
		(reaccion_perro["desplazamiento"] as Vector3).is_zero_approx(),
		"#1403: perro no se teletransporta al observar",
	)

	var polilla := _animal("polilla")
	var reaccion_polilla := polilla.respuesta_proximidad(
		polilla.origen() + Vector3(0.3, 0, 0.3), polilla.origen()
	)
	_comprobar(
		(reaccion_polilla["desplazamiento"] as Vector3).y > 0.0,
		"#1403: polilla gana altura al acercarse el observador",
	)

	var ciervo := _animal("ciervo")
	var reaccion_ciervo := ciervo.respuesta_proximidad(
		ciervo.origen() + Vector3(0.5, 0, 0.5), ciervo.origen()
	)
	_comprobar(bool(reaccion_ciervo["mirar"]), "#1403: ciervo fija la mirada")
	_comprobar(
		float(reaccion_ciervo["factor_movimiento"]) < 0.25,
		"#1403: ciervo casi se inmoviliza al vigilar",
	)

	paloma.queue_free()
	perro.queue_free()
	polilla.queue_free()
	ciervo.queue_free()


func _probar_gestos_y_reduccion() -> void:
	var cuervo := _animal("cuervo")
	var ala := cuervo.get_node_or_null("Visual/AlaI") as Node3D
	_comprobar(ala != null, "#1403: cuervo expone ala animable")
	var giro_antes := ala.rotation if ala != null else Vector3.ZERO
	cuervo.animar_pieza(cuervo.id_fauna(), 2.35, 1.0, AnimacionAmbiental.LOD_CERCA)
	var giro_despues := ala.rotation if ala != null else Vector3.ZERO
	_comprobar(giro_despues != giro_antes, "#1403: cuervo bate alas con el animador compartido")

	var dato := _dato_especie("cuervo")
	var quieto := AnimalAmbiental3D.new()
	root.add_child(quieto)
	quieto.configurar(dato, null, true)
	var ala_quieta := quieto.get_node_or_null("Visual/AlaI") as Node3D
	var giro_quieto := ala_quieta.rotation if ala_quieta != null else Vector3.ZERO
	var posicion_quieta := quieto.position
	quieto.animar_pieza(quieto.id_fauna(), 2.35, 1.0, AnimacionAmbiental.LOD_CERCA)
	_comprobar(quieto.position == posicion_quieta, "#1403: reducción de movimiento congela posición")
	_comprobar(
		ala_quieta == null or ala_quieta.rotation == giro_quieto,
		"#1403: reducción de movimiento congela microgestos",
	)

	var metodos: Array = cuervo.get_script().get_script_method_list()
	var tiene_process := false
	for metodo in metodos:
		if String((metodo as Dictionary).get("name", "")) == "_process":
			tiene_process = true
	_comprobar(not tiene_process, "#1403: cada animal sigue sin _process propio")
	_comprobar(
		cuervo.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"#1403: reacción no introduce colisión",
	)
	_comprobar(
		cuervo.find_children("*", "Area3D", true, false).is_empty(),
		"#1403: reacción no introduce triggers",
	)

	cuervo.queue_free()
	quieto.queue_free()
	await process_frame


func _animal(especie: String) -> AnimalAmbiental3D:
	var animal := AnimalAmbiental3D.new()
	root.add_child(animal)
	animal.configurar(_dato_especie(especie), null, false)
	return animal


func _dato_especie(especie: String) -> Dictionary:
	var espacio := {
		"entrada": Vector3(0, 0, 4),
		"salidas": [{"pos": Vector3(0, 1.1, -12)}],
	}
	var planes: Array = FaunaAmbiental.plan("trayecto", {}, 4, 12345)
	planes.append_array(FaunaAmbiental.plan("sueño", espacio, 4, 12345, "crucero"))
	for dato in planes:
		if String((dato as Dictionary).get("especie", "")) == especie:
			return (dato as Dictionary).duplicate(true)
	return {}


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO FaunaReactiva: " + nombre)
