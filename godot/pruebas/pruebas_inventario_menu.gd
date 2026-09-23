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

	var estado_combo := Partida.nueva()
	estado_combo["jornada"]["fase"] = "casa"
	var inventario_combo: Dictionary = estado_combo["inventario"]
	_comprobar(
		Inventario.recoger(
			inventario_combo, PropsUtilizablesCC0.objeto_inventario("palanca_kkryy")
		),
		"prepara la palanca real para combinar"
	)
	_comprobar(
		Inventario.recoger(inventario_combo, RecompensaOnirica.objeto()),
		"prepara la recompensa onírica real para combinar"
	)
	panel.abrir(estado_combo)
	var arrastre = panel._datos_arrastre_inventario(Vector2.INF)
	_comprobar(arrastre is Dictionary, "el árbol expone datos de arrastre del objeto enfocado")
	_comprobar(
		String(arrastre.get("tipo", "")) == InventarioMenuApp.TIPO_ARRASTRE_OBJETO,
		"el payload de arrastre usa un tipo estable"
	)
	_comprobar(
		String(arrastre.get("objeto_id", "")) == "palanca_kkryy",
		"el arrastre conserva el ID real del inventario"
	)
	_comprobar(
		panel._puede_soltar_en_slot(Vector2.ZERO, arrastre, "a"),
		"la ranura A acepta un objeto real arrastrado"
	)
	panel._soltar_en_slot(Vector2.ZERO, arrastre, "a")
	var slot_a := panel.find_child("CombinacionSlotA", true, false) as Button
	_comprobar(
		slot_a != null and "Palanca" in slot_a.text,
		"soltar el objeto actualiza visualmente la ranura A"
	)
	_comprobar(
		not panel._puede_soltar_en_slot(
			Vector2.ZERO, {"tipo": "otro", "objeto_id": "palanca_kkryy"}, "b"
		),
		"las ranuras rechazan payloads ajenos al inventario"
	)
	_comprobar(
		panel.find_child("CombinacionSlotA", true, false) is Button,
		"la superficie monta la ranura A"
	)
	_comprobar(
		panel.find_child("CombinacionSlotB", true, false) is Button,
		"la superficie monta la ranura B"
	)
	_comprobar(
		panel.find_child("CombinacionEjecutar", true, false) is Button,
		"la superficie monta una acción de combinar con foco"
	)
	_comprobar(
		panel.seleccionar_para_combinar(RecompensaOnirica.ID, "b"),
		"el flujo de teclado/mando sigue pudiendo asignar el segundo objeto"
	)
	var combinado := panel.combinar_slots()
	_comprobar(
		String(combinado.get("estado", "")) == CombinacionObjetos.ESTADO_EXITO,
		"la UI delega una combinación válida al dominio"
	)
	_comprobar(
		Inventario.contiene(inventario_combo, "palanca_kkryy"),
		"el resultado conserva el ID integrado de la palanca"
	)
	_comprobar(
		not Inventario.contiene(inventario_combo, RecompensaOnirica.ID),
		"la receta consume la cuña onírica"
	)
	var palanca_combinada := _buscar(inventario_combo, "palanca_kkryy")
	_comprobar(
		(
			String(palanca_combinada.get("receta_combinacion", ""))
			== CombinacionesObjetosCatalogo.RECETA_PALANCA_CUNA
		),
		"el resultado persistente conserva la huella de la receta"
	)

	var antes_fallo := inventario_combo.duplicate(true)
	panel.abrir(estado_combo)
	_comprobar(
		panel.seleccionar_para_combinar("palanca_kkryy", "a"),
		"prepara un fallo controlado sin segundo ingrediente"
	)
	var fallido := panel.combinar_slots()
	_comprobar(
		String(fallido.get("estado", "")) == CombinacionObjetos.ESTADO_FALLO,
		"la UI informa del fallo sin inventar resultado"
	)
	_comprobar(inventario_combo == antes_fallo, "un fallo desde la UI no consume objetos")
	panel.queue_free()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _buscar(inventario: Dictionary, objeto_id: String) -> Dictionary:
	for objeto in Inventario.visibles(inventario, true):
		if objeto is Dictionary and String(objeto.get("id", "")) == objeto_id:
			return objeto
	return {}


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO InventarioMenu: " + nombre)
