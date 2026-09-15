extends SceneTree

## Smoke test del shell de escritorio (#534): cubre el ciclo de vida de ventana
## exigido por los criterios de aceptación (abrir → foco → minimizar →
## restaurar → cerrar) y el contrato de modal con foco atrapado.

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	await _probar_ciclo_de_ventana()
	await _probar_modal_bloquea_y_atrapa_foco()
	await _probar_escala_ui()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_ciclo_de_ventana() -> void:
	var escritorio := await _crear_escritorio()

	escritorio.registrar_aplicacion("a", "Ventana A", func() -> Control: return Label.new())
	escritorio.registrar_aplicacion("b", "Ventana B", func() -> Control: return Label.new())

	escritorio.abrir_aplicacion("a")
	escritorio.abrir_aplicacion("b")
	_comprobar(escritorio._ventanas.size(), 2, "abrir crea una ventana por aplicación")

	escritorio.enfocar("a")
	var panel_a: Control = escritorio._ventanas["a"]["panel"]
	var panel_b: Control = escritorio._ventanas["b"]["panel"]
	_comprobar(panel_a.z_index > panel_b.z_index, "enfocar sube la ventana al frente")

	escritorio.minimizar("a")
	_comprobar(not panel_a.visible, "minimizar oculta el panel")
	_comprobar(bool(escritorio._ventanas["a"]["minimizada"]), "minimizar marca el estado")

	escritorio.restaurar("a")
	_comprobar(panel_a.visible, "restaurar vuelve a mostrar el panel")
	_comprobar(not bool(escritorio._ventanas["a"]["minimizada"]), "restaurar limpia el estado")
	_comprobar(panel_a.z_index > panel_b.z_index, "restaurar también enfoca")

	escritorio.cerrar("a")
	_comprobar(not escritorio._ventanas.has("a"), "cerrar retira la ventana de la tabla")
	_comprobar(escritorio._ventanas.has("b"), "cerrar una ventana no afecta a las demás")

	escritorio.queue_free()


func _probar_modal_bloquea_y_atrapa_foco() -> void:
	var escritorio := await _crear_escritorio()

	escritorio.registrar_aplicacion("fondo", "Fondo", func() -> Control: return Label.new())
	escritorio.abrir_aplicacion("fondo")

	var primero := Button.new()
	var segundo := Button.new()
	var columna := VBoxContainer.new()
	columna.add_child(primero)
	columna.add_child(segundo)

	escritorio.abrir_modal("aviso", "Aviso", columna)
	_comprobar(escritorio._ventanas.has("aviso"), "abrir_modal crea la ventana")
	_comprobar(
		(
			not escritorio._ventanas["aviso"].has("tarea")
			or not (escritorio._ventanas["aviso"]["tarea"] as Node).is_inside_tree()
		),
		"la modal no aparece en la barra de tareas",
	)

	escritorio.abrir_aplicacion("fondo")
	_comprobar(
		(
			escritorio._ventanas["fondo"]["panel"].z_index
			< escritorio._ventanas["aviso"]["panel"].z_index
		),
		"con una modal abierta no se puede enfocar otra ventana por delante",
	)

	## El orden incluye el botón de cerrar de la propia modal, así que el
	## ciclo completo son tres controles: primero, segundo y ese botón.
	primero.grab_focus()
	escritorio._ciclar_foco_modal(false)
	_comprobar(
		root.gui_get_focus_owner() == segundo,
		"Tab dentro de la modal avanza al siguiente control",
	)
	escritorio._ciclar_foco_modal(false)
	escritorio._ciclar_foco_modal(false)
	_comprobar(
		root.gui_get_focus_owner() == primero,
		"Tab tras recorrer toda la modal vuelve al primero (foco atrapado)",
	)

	escritorio.cerrar("aviso")
	_comprobar(escritorio._modal_id, "", "cerrar la modal libera el bloqueo")
	_comprobar(
		not is_instance_valid(escritorio._bloqueador_modal), "cerrar la modal retira el bloqueador"
	)

	escritorio.queue_free()


func _probar_escala_ui() -> void:
	var base := await _crear_escritorio()
	base.registrar_aplicacion("a", "A", func() -> Control: return Label.new())
	base.abrir_aplicacion("a")
	var tamano_base: Vector2 = base._ventanas["a"]["panel"].size
	var fuente_base: int = base.theme.default_font_size
	base.queue_free()

	var grande := await _crear_escritorio(1.5)
	grande.registrar_aplicacion("a", "A", func() -> Control: return Label.new())
	grande.abrir_aplicacion("a")
	var tamano_grande: Vector2 = grande._ventanas["a"]["panel"].size
	_comprobar(
		grande.theme.default_font_size > fuente_base,
		"escala_ui > 1 agranda la tipografía del tema",
	)
	_comprobar(
		tamano_grande.x >= tamano_base.x and tamano_grande.y >= tamano_base.y,
		"escala_ui > 1 agranda también la ventana por defecto",
	)
	grande.queue_free()

	var fuera_de_rango := await _crear_escritorio(9.0)
	_comprobar(
		fuera_de_rango._escala_ui,
		EscritorioSiga.ESCALA_UI_MAX,
		"configurar_escala_ui satura al máximo admitido",
	)
	fuera_de_rango.queue_free()


## `add_child` no marca el nodo dentro del árbol hasta el siguiente
## fotograma en un guion `--script`; sin eso `_ready()` nunca construye la
## interfaz y `get_viewport()` devuelve null.
func _crear_escritorio(escala_ui: float = 1.0) -> EscritorioSiga:
	var escritorio := EscritorioSiga.new()
	escritorio.configurar_escala_ui(escala_ui)
	root.add_child(escritorio)
	await process_frame
	return escritorio


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Escritorio modal: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
