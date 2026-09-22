extends SceneTree

const PuzzleScript := preload("res://guion/sueno_aquiles_alineacion.gd")
const ReflectorScript := preload("res://guion/aquiles_reflector.gd")
const ControllerScript := preload("res://guion/dia_aquiles_sueno_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_reflector_deliberado()
	_probar_resolucion_diegetica()
	_probar_contrato_no_combate()
	_probar_orientacion_recorrido()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_reflector_deliberado() -> void:
	var reflector := ReflectorScript.new()
	root.add_child(reflector)
	reflector.configurar()
	_comprobar(reflector.texto_accion() == "Usar reflector de bronce", "prompt del reflector")
	_comprobar(not reflector.esta_alineado(), "el reflector empieza desalineado")
	_comprobar(is_equal_approx(reflector.angulo_actual(), 0.0), "ángulo inicial cero")

	_comprobar(reflector.interactuar(root), "primer giro aceptado")
	_comprobar(not reflector.esta_alineado(), "-15 grados no revelan el talón")
	_comprobar(reflector.interactuar(root), "segundo giro aceptado")
	_comprobar(not reflector.esta_alineado(), "-30 grados siguen sin alinear")
	_comprobar(reflector.interactuar(root), "tercer giro aceptado")
	_comprobar(reflector.esta_alineado(), "45 grados alinean el reflejo")
	_comprobar(
		is_equal_approx(reflector.angulo_actual(), ReflectorScript.ANGULO_OBJETIVO),
		"el ángulo final coincide con el objetivo",
	)
	_comprobar(reflector.interactuar(root), "el reflector puede seguir girando")
	_comprobar(not reflector.esta_alineado(), "salir del ángulo pierde la alineación")
	reflector.queue_free()


func _probar_resolucion_diegetica() -> void:
	var sueno := PuzzleScript.new()
	sueno.reduccion_movimiento = true
	root.add_child(sueno)
	sueno.preparar()

	var reflector := sueno.reflector()
	var sello := sueno.sello()
	var talon := sueno.get_node("FiguraAquiles/VulnerabilidadTalon") as MeshInstance3D
	_comprobar(reflector != null, "la escena monta el reflector")
	_comprobar(sello != null, "la escena monta el sello")
	_comprobar(talon != null, "la escena conserva el talón")
	_comprobar(not talon.visible, "el talón empieza oculto")
	_comprobar(not sello.esta_habilitado(), "el sello empieza bloqueado")
	_comprobar(not sello.interactuar(root), "el sello no funciona antes de revelar")
	_comprobar(not sueno.esta_resuelta(), "no hay resolución pasiva")

	reflector.interactuar(root)
	reflector.interactuar(root)
	_comprobar(not talon.visible, "dos giros todavía no revelan")
	_comprobar(not sello.esta_habilitado(), "dos giros no habilitan el sello")
	reflector.interactuar(root)
	_comprobar(talon.visible, "la alineación revela el talón")
	var disco := reflector.get_node("DiscoReflector") as Node3D
	var haz := disco.get_node("HazReflejado") as SpotLight3D
	var figura := sueno.get_node("FiguraAquiles") as Node3D
	# Esta prueba corre desde SceneTree._initialize(), antes del primer frame.
	# Componer transforms locales evita depender de global_transform fuera del árbol
	# y verifica la misma geometría en el espacio local común del sueño.
	var haz_en_sueno := reflector.transform * disco.transform * haz.transform
	var talon_en_sueno := figura.transform * talon.transform
	var direccion_haz := (haz_en_sueno.basis * Vector3.FORWARD).normalized()
	var hacia_talon := (talon_en_sueno.origin - haz_en_sueno.origin).normalized()
	_comprobar(
		direccion_haz.dot(hacia_talon) > 0.99,
		"el haz visible apunta geométricamente al talón al quedar alineado",
	)
	_comprobar(sello.esta_habilitado(), "revelar habilita el sello")

	_comprobar(sello.interactuar(root), "el sello acepta la interacción revelada")
	_comprobar(sueno.esta_resuelta(), "sellar resuelve el sueño")
	_comprobar(not sello.esta_habilitado(), "el sello se bloquea tras resolver")
	_comprobar(
		not (sueno.get_node("ImpactoAdministrativo1") as MeshInstance3D).visible,
		"los impactos administrativos desaparecen al resolver",
	)
	sueno.queue_free()


func _probar_contrato_no_combate() -> void:
	_comprobar(not SuenoAquiles.resolver(true, "atacar")["resuelta"], "atacar no resuelve")
	_comprobar(not SuenoAquiles.resolver(true, "golpear")["resuelta"], "golpear no resuelve")
	_comprobar(SuenoAquiles.resolver(true, "sellar")["resuelta"], "sellar sí resuelve")
	var reducido := SuenoAquiles.plan_transformacion(true)
	_comprobar(not reducido["flash"], "reducción de movimiento no usa flash")
	_comprobar(not reducido["sacudida_camara"], "reducción de movimiento no sacude cámara")


func _probar_orientacion_recorrido() -> void:
	var controller := ControllerScript.new()
	var encuentro := Node3D.new()

	var frontal := {
		"entrada": Vector3(0.0, 0.0, 4.0),
		"salidas": [{"pos": Vector3(0.0, 0.0, -4.0)}],
	}
	controller._orientar_segun_recorrido(encuentro, frontal)
	var frente := (-encuentro.transform.basis.z).normalized()
	_comprobar(
		frente.dot(Vector3(0.0, 0.0, -1.0)) > 0.999,
		"Aquiles orienta -Z hacia una salida frontal",
	)
	_comprobar(
		encuentro.transform.basis.z.normalized().dot(Vector3(0.0, 0.0, 1.0)) > 0.999,
		"el lado +Z de los interactuables queda hacia la entrada frontal",
	)

	var lateral := {
		"entrada": Vector3(-4.0, 0.0, 0.0),
		"salidas": [{"pos": Vector3(4.0, 0.0, 0.0)}],
	}
	controller._orientar_segun_recorrido(encuentro, lateral)
	frente = (-encuentro.transform.basis.z).normalized()
	_comprobar(
		frente.dot(Vector3.RIGHT) > 0.999,
		"Aquiles se adapta también a recorridos laterales",
	)

	var rotacion_previa := encuentro.rotation
	(
		controller
		. _orientar_segun_recorrido(
			encuentro,
			{"entrada": Vector3.ZERO, "salidas": []},
		)
	)
	_comprobar(
		encuentro.rotation.distance_to(rotacion_previa) < 0.0001,
		"sin salida conserva la orientación existente",
	)
	encuentro.free()
	controller.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Aquiles alineación: " + nombre)
