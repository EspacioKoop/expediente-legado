extends SceneTree

var pasadas := 0
var fallos := 0


func _init() -> void:
	var pantalla := CanvasLayer.new()
	root.add_child(pantalla)
	var estado := {}
	var guardados := []
	var guardar := func(destino: String) -> bool:
		guardados.append(destino)
		return true

	var acceso := Entrada49Panel.montar(pantalla, estado, guardar)
	comprobar("monta acceso", acceso != null and acceso.name == "Entrada49Acceso", true)
	acceso.emit_signal("pressed")
	var panel := pantalla.get_node_or_null("Entrada49Panel")
	comprobar("abre panel", panel != null, true)
	if panel == null:
		terminar()
		return

	var investigar := _boton(panel, "Investigar")
	comprobar("ofrece investigar", investigar != null, true)
	if investigar != null:
		investigar.emit_signal("pressed")
	comprobar("persiste resultado", estado.has(Entrada49Panel.CLAVE_ESTADO), true)
	var resolucion: Dictionary = estado.get(Entrada49Panel.CLAVE_ESTADO, {})
	comprobar("persiste decision", resolucion.get("decision"), "investigar")
	comprobar("persiste eco", not Dictionary(resolucion.get("eco_onirico", {})).is_empty(), true)
	comprobar("solicita guardado", guardados, [""])

	var base_sueno := {
		"entrada": Vector3.ZERO,
		"carteles": [],
		"luces": [],
		"figuras": [],
	}
	var deformado := Entrada49Sueno.aplicar(base_sueno, estado, 0)
	comprobar("primera sala recibe eco", deformado.has("entrada49_eco"), true)
	comprobar(
		"eco no afirma metafisica",
		deformado.get("entrada49_eco", {}).get("afirmacion_metafisica"),
		false
	)
	var segunda := Entrada49Sueno.aplicar(base_sueno, estado, 1)
	comprobar("segunda sala queda limpia", segunda.has("entrada49_eco"), false)
	comprobar(
		"companero puede reaccionar",
		not Entrada49Dialogo.resolver("becario", estado).is_empty(),
		true
	)
	comprobar(
		"actor sin reaccion no inventa dialogo",
		Entrada49Dialogo.resolver("telefono", estado),
		""
	)

	terminar()


func _boton(raiz: Node, texto: String) -> Button:
	for nodo in raiz.find_children("*", "Button", true, false):
		if nodo is Button and nodo.text == texto:
			return nodo
	return null


func terminar() -> void:
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
