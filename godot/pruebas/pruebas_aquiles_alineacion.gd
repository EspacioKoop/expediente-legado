extends SceneTree

const PuzzleScript := preload("res://guion/sueno_aquiles_alineacion.gd")
const ReflectorScript := preload("res://guion/aquiles_reflector.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_reflector_deliberado()
	_probar_resolucion_diegética()
	_probar_contrato_no_combate()
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
	_comprobar(not reflector.esta_alineado(), "15 grados no revelan el talón")
	_comprobar(reflector.interactuar(root), "segundo giro aceptado")
	_comprobar(not reflector.esta_alineado(), "30 grados siguen sin alinear")
	_comprobar(reflector.interactuar(root), "tercer giro aceptado")
	_comprobar(reflector.esta_alineado(), "45 grados alinean el reflejo")
	_comprobar(
		is_equal_approx(reflector.angulo_actual(), ReflectorScript.ANGULO_OBJETIVO),
		"el ángulo final coincide con el objetivo",
	)
	_comprobar(reflector.interactuar(root), "el reflector puede seguir girando")
	_comprobar(not reflector.esta_alineado(), "salir del ángulo pierde la alineación")
	reflector.queue_free()


func _probar_resolucion_diegética() -> void:
	var sueno := PuzzleScript.new()
	sueno.reduccion_movimiento = true
	root.add_child(sueno)

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


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Aquiles alineación: " + nombre)
