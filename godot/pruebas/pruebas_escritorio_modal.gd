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
	await _probar_foco_visible_en_piel_real()
	await _probar_escala_ui()
	await _probar_capacidades_declaradas_de_app_sintetica()
	await _probar_redimensionado_con_agarre()
	await _probar_varias_instancias()
	await _probar_sin_varias_instancias_reenfoca()
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


## La piel real del OS98 añade el contrato que el shell visible necesita:
## ninguna operación debe dejar el foco de teclado en un Control oculto.
func _probar_foco_visible_en_piel_real() -> void:
	var escritorio := await _crear_escritorio_visual()
	var contenido := Button.new()
	contenido.text = "Acción"
	escritorio.registrar_aplicacion("foco", "Foco", func() -> Control: return contenido)

	escritorio.abrir_aplicacion("foco")
	_comprobar(
		root.gui_get_focus_owner() == contenido,
		"abrir una ventana enfoca su primer control interactivo",
	)

	escritorio.minimizar("foco")
	_comprobar(
		root.gui_get_focus_owner() == escritorio._boton_menu_visual,
		"minimizar no deja el foco dentro de una ventana oculta",
	)

	escritorio.restaurar("foco")
	escritorio._boton_menu_visual.emit_signal("pressed")
	var entrada_programa := escritorio._programas_menu.get_child(0) as Control
	_comprobar(
		root.gui_get_focus_owner() == entrada_programa,
		"abrir el menú lleva el foco al primer programa",
	)
	escritorio._boton_menu_visual.emit_signal("pressed")
	_comprobar(
		root.gui_get_focus_owner() == escritorio._boton_menu_visual,
		"cerrar el menú devuelve el foco al botón del sistema",
	)

	# Si una modal se abre mientras el menú tenía el foco, el shell base guarda
	# ese Control como foco previo. Al cerrar, la piel real debe detectar que ya
	# está oculto y recuperar un objetivo visible.
	escritorio._boton_menu_visual.emit_signal("pressed")
	var aviso := Label.new()
	aviso.text = "Aviso"
	escritorio.abrir_modal("aviso-foco", "Aviso", aviso)
	var foco_modal := root.gui_get_focus_owner()
	_comprobar(
		is_instance_valid(foco_modal) and foco_modal.is_visible_in_tree(),
		"una modal sin controles propios conserva un foco visible en su marco",
	)
	escritorio.cerrar("aviso-foco")
	await process_frame
	var foco_recuperado := root.gui_get_focus_owner()
	_comprobar(
		is_instance_valid(foco_recuperado) and foco_recuperado.is_visible_in_tree(),
		"cerrar la modal no restaura el foco a una entrada de menú oculta",
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


## App sintética (#535): cero dominio propio, solo el contrato. Comprueba que
## el shell respeta lo que declara `describir_capacidades()` sin conocerla.
func _probar_capacidades_declaradas_de_app_sintetica() -> void:
	var escritorio := await _crear_escritorio()
	var fixture := AppSinteticaPrueba.new("sintetica-tamanos")
	fixture.app.registrar_en(escritorio)

	escritorio.abrir_aplicacion("sintetica-tamanos")
	var panel: Control = escritorio._ventanas["sintetica-tamanos"]["panel"]
	_comprobar(
		(
			panel.size.x >= AppSinteticaPrueba.TAMANO_MINIMO.x
			and panel.size.y >= AppSinteticaPrueba.TAMANO_MINIMO.y
		),
		"abrir respeta el tamaño mínimo declarado por la app sintética"
	)
	_comprobar(
		(
			panel.size.x <= AppSinteticaPrueba.TAMANO_PREFERIDO.x
			and panel.size.y <= AppSinteticaPrueba.TAMANO_PREFERIDO.y
		),
		"abrir no excede el tamaño preferido declarado por la app sintética"
	)

	escritorio.queue_free()


func _probar_redimensionado_con_agarre() -> void:
	var escritorio := await _crear_escritorio()
	var fixture := AppSinteticaPrueba.new("sintetica-agarre")
	fixture.app.registrar_en(escritorio)
	escritorio.abrir_aplicacion("sintetica-agarre")

	var panel: Control = escritorio._ventanas["sintetica-agarre"]["panel"]
	var minimo_esc: Vector2 = escritorio._ventanas["sintetica-agarre"]["tamano_minimo"]

	# Encoger de más: el agarre no puede bajar del mínimo declarado.
	panel.size = minimo_esc - Vector2(500, 500)
	escritorio._limitar_ventana(panel, minimo_esc)
	_comprobar(
		panel.size.x >= minimo_esc.x and panel.size.y >= minimo_esc.y,
		"el agarre no reduce la ventana por debajo de su tamaño mínimo"
	)

	# Agrandar de más: no puede superar el área disponible del escritorio.
	# Se limita aparte con un mínimo de (1, 1): el mínimo declarado por la app
	# (260×180) es mayor que el área de la ventana de pruebas sin cabecera
	# real (64×64), y el mínimo SIEMPRE gana sobre el área (ver
	# `_limitar_ventana`), así que comprobar el tope de área exige aislarlo
	# del mínimo real de la app.
	panel.size = escritorio._area_ventanas.size + Vector2(400, 400)
	escritorio._limitar_ventana(panel, Vector2(1, 1))
	_comprobar(
		(
			panel.size.x <= escritorio._area_ventanas.size.x
			and panel.size.y <= escritorio._area_ventanas.size.y
		),
		"el agarre no agranda la ventana más allá del área del escritorio"
	)

	escritorio.queue_free()


## `multiples_instancias = true` abre una segunda ventana independiente sin
## tocar la primera, y cada una se minimiza/restaura/cierra por su cuenta.
func _probar_varias_instancias() -> void:
	var escritorio := await _crear_escritorio()
	var fixture := AppSinteticaPrueba.new("sintetica-instancias")
	fixture.app.registrar_en(escritorio)

	escritorio.abrir_aplicacion("sintetica-instancias")
	escritorio.abrir_aplicacion("sintetica-instancias")
	_comprobar(
		(
			escritorio._ventanas.has("sintetica-instancias")
			and escritorio._ventanas.has("sintetica-instancias#2")
		),
		"multiples_instancias abre una segunda ventana independiente"
	)

	escritorio.minimizar("sintetica-instancias#2")
	_comprobar(
		(
			not escritorio._ventanas["sintetica-instancias#2"]["panel"].visible
			and escritorio._ventanas["sintetica-instancias"]["panel"].visible
		),
		"minimizar una instancia no afecta a la otra"
	)

	escritorio.cerrar("sintetica-instancias#2")
	_comprobar(
		(
			not escritorio._ventanas.has("sintetica-instancias#2")
			and escritorio._ventanas.has("sintetica-instancias")
		),
		"cerrar una instancia no afecta a la otra"
	)

	escritorio.queue_free()


## Sin `multiples_instancias`, una segunda apertura sigue reenfocando la
## misma ventana en vez de abrir otra (comportamiento de siempre).
func _probar_sin_varias_instancias_reenfoca() -> void:
	var escritorio := await _crear_escritorio()
	escritorio.registrar_aplicacion("unica", "Única", func() -> Control: return Label.new())

	escritorio.abrir_aplicacion("unica")
	escritorio.abrir_aplicacion("unica")
	_comprobar(escritorio._ventanas.size(), 1, "sin multiples_instancias solo hay una ventana")
	_comprobar(
		not escritorio._ventanas.has("unica#2"), "sin multiples_instancias no se crean instancias"
	)

	escritorio.queue_free()


## `add_child` no marca el nodo dentro del árbol hasta el siguiente
## fotograma en un guion `--script`; sin eso `_ready()` nunca construye la
## interfaz y `get_viewport()` devuelve null.
func _crear_escritorio(escala_ui: float = 1.0) -> EscritorioSiga:
	var escritorio := EscritorioSiga.new()
	escritorio.configurar_escala_ui(escala_ui)
	root.add_child(escritorio)
	await process_frame
	return escritorio


func _crear_escritorio_visual() -> EscritorioSigaVisual:
	var escritorio := EscritorioSigaVisual.new()
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
