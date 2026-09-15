extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var estado := Partida.nueva()
	var inventario: Dictionary = estado["inventario"]
	_comprobar(
		(
			Inventario
			. recoger(
				inventario,
				{
					"id": "sello_oficina",
					"nombre": "Sello de oficina",
					"descripcion": "Un sello administrativo.",
					"origen": "archivo",
					"usos": ["archivo"],
				}
			)
		),
		"prepara un objeto llevado"
	)
	_comprobar(
		(
			Inventario
			. recoger(
				inventario,
				{
					"id": "llave_casa",
					"nombre": "Llave de casa",
					"origen": "casa",
					"usos": ["casa"],
				}
			)
		),
		"prepara un objeto doméstico"
	)
	_comprobar(
		Inventario.guardar_en_casa(inventario, "llave_casa"),
		"guarda un objeto para diferenciar las dos ubicaciones"
	)

	estado["jornada"]["fase"] = "archivo"
	var fuera := InventarioMenuApp.modelo(estado)
	_comprobar(not fuera["en_casa"], "archivo se presenta como contexto fuera de casa")
	_comprobar(fuera[Inventario.CARRIED].size() == 1, "fuera muestra lo llevado")
	_comprobar(
		fuera[Inventario.HOME_STORAGE].is_empty(),
		"fuera no filtra al jugador lo que dejó guardado en casa"
	)

	estado["jornada"]["fase"] = "casa"
	var casa := InventarioMenuApp.modelo(estado)
	_comprobar(casa["en_casa"], "la fase casa habilita la vista doméstica")
	_comprobar(casa[Inventario.CARRIED].size() == 1, "en casa conserva lo llevado")
	_comprobar(casa[Inventario.HOME_STORAGE].size() == 1, "en casa muestra lo guardado")
	casa[Inventario.CARRIED][0]["id"] = "mutado_desde_ui"
	_comprobar(
		String(estado["inventario"][Inventario.CARRIED][0]["id"]) == "sello_oficina",
		"el modelo de UI es una copia y no muta la partida"
	)

	var panel := InventarioMenuApp.new()
	root.add_child(panel)
	panel.abrir(estado)
	_comprobar(panel.visible, "abrir hace visible la superficie")
	var arbol := panel.find_child("InventarioLista", true, false) as Tree
	var detalle := panel.find_child("InventarioDetalle", true, false) as RichTextLabel
	_comprobar(arbol != null, "la superficie monta una lista navegable")
	_comprobar(detalle != null, "la superficie monta detalle del objeto")
	if arbol != null and arbol.get_root() != null:
		_comprobar(
			arbol.get_root().get_child_count() == 2,
			"en casa la UI separa carried y home_storage en dos secciones"
		)
	if detalle != null:
		_comprobar(
			"Sello de oficina" in detalle.text,
			"al abrir selecciona un objeto y muestra sus metadatos"
		)

	estado["jornada"]["fase"] = "sueño"
	panel.abrir(estado)
	if arbol != null and arbol.get_root() != null:
		_comprobar(
			arbol.get_root().get_child_count() == 1,
			"en sueño la UI vuelve a enseñar solo lo que llevas"
		)
	panel.queue_free()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO InventarioMenu: " + nombre)
