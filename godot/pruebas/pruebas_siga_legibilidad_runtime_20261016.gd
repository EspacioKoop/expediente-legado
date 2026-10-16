## Prueba de humo headless de legibilidad runtime SIGA-98 (#20261016).
##
## Inspecciona escenas y componentes SIGA-98 montados en un viewport de 1920x1080.
## Analiza fuente efectiva, recorte/overflow y escalado de Labels/RichTextLabels.
## Emite un diagnóstico reproducible en consola sin asumir confirmación visual.
extends SceneTree

const UMBRAL_FUENTE_MINIMA := 12
const ANCHO_VIEWPORT := 1920
const ALTO_VIEWPORT := 1080

var _pasadas := 0
var _fallos := 0
var _hallazgos := []


func _initialize() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_configurar_viewport()
	_probar_diagnostico_sintetico()
	await _probar_escenas_siga_reales()
	_imprimir_resumen()
	quit(1 if _fallos > 0 else 0)


func _configurar_viewport() -> void:
	var vp := root.get_viewport()
	if vp != null:
		vp.size = Vector2i(ANCHO_VIEWPORT, ALTO_VIEWPORT)


func _probar_diagnostico_sintetico() -> void:
	var contenedor := Control.new()
	contenedor.size = Vector2(1920, 1080)
	root.add_child(contenedor)

	var label_pequeno := Label.new()
	label_pequeno.name = "LabelPequeno"
	label_pequeno.text = "Texto diminuto de prueba"
	label_pequeno.add_theme_font_size_override("font_size", 8)
	contenedor.add_child(label_pequeno)

	var label_deformado := Label.new()
	label_deformado.name = "LabelDeformado"
	label_deformado.text = "Texto escalado asimétrico"
	label_deformado.scale = Vector2(1.0, 0.4)
	contenedor.add_child(label_deformado)

	var label_recortado := Label.new()
	label_recortado.name = "LabelRecortado"
	label_recortado.text = "Texto largo que se recorta deliberadamente sin autowrap"
	label_recortado.clip_text = true
	label_recortado.size = Vector2(40, 20)
	contenedor.add_child(label_recortado)

	var resultados := []
	_inspeccionar_nodo(contenedor, "PruebaSintetica", resultados)

	var tipos := []
	for r in resultados:
		tipos.append(r["tipo"])

	_comprobar(tipos.has("fuente_pequena"), "detecta fuente efectiva menor al umbral")
	_comprobar(tipos.has("escalado_desproporcionado"), "detecta escalado no uniforme/reducido")
	_comprobar(tipos.has("recorte_potencial"), "detecta recorte de texto activo")

	contenedor.queue_free()


func _probar_escenas_siga_reales() -> void:
	var rutas_componentes := [
		"res://guion/escritorio_siga_visual.gd",
		"res://guion/correo_siga.gd",
		"res://guion/software_siga.gd",
		"res://guion/terminal_siga_app.gd",
		"res://guion/bloc_notas_siga.gd",
		"res://guion/explorador_siga.gd",
		"res://guion/calculadora_siga.gd",
		"res://guion/preferencias_siga.gd",
		"res://guion/bingo_siga_panel.gd",
		"res://guion/navegador_siga.gd",
		"res://guion/evaluacion_desempeno_siga.gd",
		"res://guion/reconstruccion_documental_siga.gd",
		"res://guion/catalogo_anomalias_siga.gd",
		"res://guion/papeleria_siga98.gd"
	]

	var total_inspeccionados := 0
	for ruta in rutas_componentes:
		if not ResourceLoader.exists(ruta):
			continue
		var script_res = load(ruta)
		if script_res == null or not script_res.can_instantiate():
			continue
		var inst = script_res.new()
		if not (inst is Node):
			if inst is RefCounted:
				inst = null
			continue
		var nodo := inst as Node
		root.add_child(nodo)
		await process_frame

		var resultados_escena := []
		_inspeccionar_nodo(nodo, ruta.get_file(), resultados_escena)
		total_inspeccionados += 1
		_hallazgos.append_array(resultados_escena)

		nodo.queue_free()
		await process_frame

	_comprobar(
		total_inspeccionados > 0, "monto e inspecciono al menos una escena/app SIGA real en 1080p"
	)


func _inspeccionar_nodo(nodo: Node, nombre_escena: String, acumulador: Array) -> void:
	if nodo == null:
		return

	if nodo is Label:
		_evaluar_label(nodo as Label, nombre_escena, acumulador)
	elif nodo is RichTextLabel:
		_evaluar_rich_text_label(nodo as RichTextLabel, nombre_escena, acumulador)

	for hijo in nodo.get_children():
		_inspeccionar_nodo(hijo, nombre_escena, acumulador)


func _evaluar_label(label: Label, escena: String, acumulador: Array) -> void:
	if label.text.strip_edges().is_empty():
		return

	var font_size := label.get_theme_font_size("font_size")
	var esc_global := label.get_global_transform().get_scale()
	var fuente_efectiva := float(font_size) * esc_global.y

	if fuente_efectiva < UMBRAL_FUENTE_MINIMA:
		acumulador.append(
			{
				"escena": escena,
				"nodo": label.get_path(),
				"tipo": "fuente_pequena",
				"detalles":
				(
					"Fuente efectiva %.1fpx < %dpx (declarada: %dpx)"
					% [fuente_efectiva, UMBRAL_FUENTE_MINIMA, font_size]
				)
			}
		)

	if absf(esc_global.x - esc_global.y) > 0.05 or esc_global.y < 0.8:
		acumulador.append(
			{
				"escena": escena,
				"nodo": label.get_path(),
				"tipo": "escalado_desproporcionado",
				"detalles": "Escalado no uniforme o comprimido: " + str(esc_global)
			}
		)

	if label.clip_text:
		acumulador.append(
			{
				"escena": escena,
				"nodo": label.get_path(),
				"tipo": "recorte_potencial",
				"detalles": "Label tiene clip_text activo; verificar truncado de texto"
			}
		)
	elif (
		label.autowrap_mode == TextServer.AUTOWRAP_OFF
		and label.size.x > 0
		and label.get_combined_minimum_size().x > label.size.x + 2.0
	):
		acumulador.append(
			{
				"escena": escena,
				"nodo": label.get_path(),
				"tipo": "recorte_potencial",
				"detalles":
				(
					"Ancho mínimo requerimiento (%.1fpx) supera tamaño asignado (%.1fpx)"
					% [label.get_combined_minimum_size().x, label.size.x]
				)
			}
		)


func _evaluar_rich_text_label(rtl: RichTextLabel, escena: String, acumulador: Array) -> void:
	var text_content := rtl.get_parsed_text().strip_edges()
	if text_content.is_empty():
		return

	var font_size := rtl.get_theme_font_size("font_size")
	var esc_global := rtl.get_global_transform().get_scale()
	var fuente_efectiva := float(font_size) * esc_global.y

	if fuente_efectiva < UMBRAL_FUENTE_MINIMA:
		acumulador.append(
			{
				"escena": escena,
				"nodo": rtl.get_path(),
				"tipo": "fuente_pequena",
				"detalles":
				(
					"RichTextLabel fuente efectiva %.1fpx < %dpx (declarada: %dpx)"
					% [fuente_efectiva, UMBRAL_FUENTE_MINIMA, font_size]
				)
			}
		)

	if absf(esc_global.x - esc_global.y) > 0.05 or esc_global.y < 0.8:
		acumulador.append(
			{
				"escena": escena,
				"nodo": rtl.get_path(),
				"tipo": "escalado_desproporcionado",
				"detalles": "Escalado de RichTextLabel desproporcionado: " + str(esc_global)
			}
		)

	if (
		not rtl.scroll_active
		and not rtl.fit_content
		and rtl.size.y > 0
		and rtl.get_content_height() > int(rtl.size.y) + 2
	):
		acumulador.append(
			{
				"escena": escena,
				"nodo": rtl.get_path(),
				"tipo": "recorte_potencial",
				"detalles":
				(
					"Contenido vertical (%dpx) excede la caja sin desplazamiento (%dpx)"
					% [rtl.get_content_height(), int(rtl.size.y)]
				)
			}
		)


func _imprimir_resumen() -> void:
	print("\n--- DIAGNÓSTICO RUNTIME DE LEGIBILIDAD SIGA-98 (1920x1080) ---")
	print("AVISO: Diagnóstico automático emitido. La legibilidad visual requiere captura/playtest.")
	print("Total de hallazgos registrados: %d" % _hallazgos.size())
	for h in _hallazgos:
		print("[%s] [%s] %s -> %s" % [h["escena"], h["tipo"], h["nodo"], h["detalles"]])
	print("----------------------------------------------------------------\n")
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO legibilidad runtime: " + descripcion)
