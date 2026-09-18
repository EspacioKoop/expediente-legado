## Gate visual reproducible para la tipografía de terminal (#298).
##
## Genera una matriz comparable del rol terminal frente a IBM Plex Mono:
## 2 fuentes x 2 contrastes x 2 escalas = 8 capturas. Cada captura contiene
## muestras a 10/12/14/16 px, un RichTextLabel de diagnóstico y un LineEdit.
##
## Uso:
##   xvfb-run -a godot4 --path godot \
##     --script res://pruebas/capturar_kubasta_298.gd -- /tmp/kubasta-298
##
## Cuando Kubasta.ttf ya esté materializada, añadir `--exigir-kubasta` hace que
## el gate falle si el rol terminal no resuelve realmente a ese recurso.
extends SceneTree

const TAM := Vector2i(1200, 800)
const TAMANOS := [10, 12, 14, 16]
const ESCALAS := [1.0, 1.25]
const CONTRASTES := [
	{
		"id": "oscuro",
		"fondo": Color("101318"),
		"texto": Color("f2f4f7"),
		"borde": Color("5f86b3"),
	},
	{
		"id": "claro",
		"fondo": Color("f2f2ed"),
		"texto": Color("111111"),
		"borde": Color("444444"),
	},
]
const MUESTRA := "áéíóúüñ¿¡ ÁÉÍÓÚÜÑ 0123456789 []{}:/\\-_+*=#"
const REGISTRO := "SIGA-98 // diagnóstico\nFOLIO 13-B  ESTADO: REVISIÓN\n> verificar_hash --modo seguro"
const ENTRADA := "verificar_hash --folio 13-B"

var _viewport: SubViewport
var _salida := ""
var _fallos := 0
var _exigir_kubasta := false
var _casos: Array[Dictionary] = []


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var argumentos := OS.get_cmdline_user_args()
	_salida = (
		String(argumentos[0])
		if not argumentos.is_empty() and not String(argumentos[0]).begins_with("--")
		else ProjectSettings.globalize_path("user://capturas-kubasta-298")
	)
	_exigir_kubasta = argumentos.has("--exigir-kubasta")
	var error_dir := DirAccess.make_dir_recursive_absolute(_salida)
	if error_dir != OK:
		_fallar("no se puede crear %s: %s" % [_salida, error_dir])
		quit(1)
		return

	_preparar_viewport()
	var kubasta_materializada := ResourceLoader.exists(EstiloSiga.RUTA_FUENTE_TERMINAL)
	var terminal := EstiloSiga.fuente_terminal()
	var fallback := EstiloSiga.fuente_mono()
	if _exigir_kubasta and (
		not kubasta_materializada or terminal.resource_path != EstiloSiga.RUTA_FUENTE_TERMINAL
	):
		_fallar("se exigió Kubasta pero fuente_terminal() no resuelve al TTF materializado")
		_guardar_manifest(kubasta_materializada, terminal, fallback)
		quit(1)
		return

	var fuentes := [
		{"id": "terminal", "fuente": terminal},
		{"id": "ibm-plex-mono", "fuente": fallback},
	]
	for ficha_fuente in fuentes:
		for contraste in CONTRASTES:
			for escala in ESCALAS:
				var caso := await _capturar_caso(
					String(ficha_fuente["id"]),
					ficha_fuente["fuente"] as Font,
					contraste as Dictionary,
					float(escala),
				)
				_casos.append(caso)

	_guardar_manifest(kubasta_materializada, terminal, fallback)
	print(
		"Gate visual #298: %d capturas, %d fallos, Kubasta=%s -> %s"
		% [_casos.size(), _fallos, kubasta_materializada, _salida]
	)
	quit(1 if _fallos else 0)


func _preparar_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "CapturaKubasta298"
	_viewport.size = TAM
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.transparent_bg = false
	_viewport.gui_disable_input = true
	root.add_child(_viewport)


func _capturar_caso(
	id_fuente: String,
	fuente: Font,
	contraste: Dictionary,
	escala: float,
) -> Dictionary:
	var superficie := _crear_superficie(fuente, contraste, escala)
	_viewport.add_child(superficie)
	for _i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw

	var layout_ok := _validar_layout(superficie, fuente)
	var escala_id := "1x" if is_equal_approx(escala, 1.0) else "1_25x"
	var nombre := "%s-%s-%s.png" % [id_fuente, String(contraste["id"]), escala_id]
	var ruta := _salida.path_join(nombre)
	var imagen := _viewport.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		_fallar("viewport vacío para %s" % nombre)
		layout_ok = false
	else:
		var error_png := imagen.save_png(ruta)
		if error_png != OK:
			_fallar("no se pudo guardar %s: %s" % [ruta, error_png])
			layout_ok = false

	superficie.queue_free()
	await process_frame
	return {
		"archivo": nombre,
		"fuente": id_fuente,
		"resource_path": fuente.resource_path,
		"contraste": String(contraste["id"]),
		"escala": escala,
		"layout_ok": layout_ok,
	}


func _crear_superficie(fuente: Font, contraste: Dictionary, escala: float) -> Control:
	var superficie := Control.new()
	superficie.name = "CasoKubasta298"
	superficie.size = Vector2(TAM)

	var fondo := ColorRect.new()
	fondo.color = Color("2b2f36")
	fondo.position = Vector2.ZERO
	fondo.size = Vector2(TAM)
	superficie.add_child(fondo)

	var panel := PanelContainer.new()
	panel.name = "PanelTerminal"
	panel.position = Vector2(40, 40)
	panel.size = Vector2(880, 560)
	panel.scale = Vector2.ONE * escala
	var caja := StyleBoxFlat.new()
	caja.bg_color = contraste["fondo"]
	caja.border_color = contraste["borde"]
	caja.set_border_width_all(2)
	caja.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", caja)
	superficie.add_child(panel)

	var margen := MarginContainer.new()
	margen.name = "Margen"
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 18)
	panel.add_child(margen)

	var columna := VBoxContainer.new()
	columna.name = "Columna"
	columna.add_theme_constant_override("separation", 8)
	margen.add_child(columna)

	var cabecera := Label.new()
	cabecera.name = "Cabecera"
	cabecera.text = "SIGA-98 // FOLIO 13-B // DIAGNÓSTICO"
	cabecera.add_theme_font_override("font", fuente)
	cabecera.add_theme_font_size_override("font_size", 16)
	cabecera.add_theme_color_override("font_color", contraste["texto"])
	columna.add_child(cabecera)

	for tamano in TAMANOS:
		var muestra := Label.new()
		muestra.name = "Muestra%d" % int(tamano)
		muestra.text = "%d px  %s" % [int(tamano), MUESTRA]
		muestra.add_theme_font_override("font", fuente)
		muestra.add_theme_font_size_override("font_size", int(tamano))
		muestra.add_theme_color_override("font_color", contraste["texto"])
		columna.add_child(muestra)

	var separador := HSeparator.new()
	columna.add_child(separador)

	var registro := RichTextLabel.new()
	registro.name = "Registro"
	registro.bbcode_enabled = false
	registro.fit_content = false
	registro.scroll_active = false
	registro.custom_minimum_size = Vector2(0, 116)
	registro.add_theme_font_override("normal_font", fuente)
	registro.add_theme_font_size_override("normal_font_size", 14)
	registro.add_theme_color_override("default_color", contraste["texto"])
	registro.text = REGISTRO
	columna.add_child(registro)

	var linea := LineEdit.new()
	linea.name = "Entrada"
	linea.text = ENTRADA
	linea.add_theme_font_override("font", fuente)
	linea.add_theme_font_size_override("font_size", 16)
	linea.add_theme_color_override("font_color", contraste["texto"])
	linea.add_theme_stylebox_override("normal", _caja_linea(contraste))
	columna.add_child(linea)

	var pie := Label.new()
	pie.name = "Pie"
	pie.text = "Escala %.2f · revisión humana: legibilidad, ritmo, clipping y blur" % escala
	pie.add_theme_font_override("font", fuente)
	pie.add_theme_font_size_override("font_size", 12)
	pie.add_theme_color_override("font_color", contraste["texto"])
	columna.add_child(pie)
	return superficie


func _caja_linea(contraste: Dictionary) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = contraste["fondo"]
	caja.border_color = contraste["borde"]
	caja.set_border_width_all(1)
	caja.content_margin_left = 6
	caja.content_margin_right = 6
	caja.content_margin_top = 4
	caja.content_margin_bottom = 4
	return caja


func _validar_layout(superficie: Control, fuente: Font) -> bool:
	var panel := superficie.get_node("PanelTerminal") as PanelContainer
	var columna := panel.get_node("Margen/Columna") as VBoxContainer
	var ok := true
	for tamano in TAMANOS:
		var muestra := columna.get_node("Muestra%d" % int(tamano)) as Label
		if muestra.get_minimum_size().x > muestra.size.x + 0.5:
			_fallar("clipping horizontal en muestra %d px" % int(tamano))
			ok = false
	var registro := columna.get_node("Registro") as RichTextLabel
	if registro.get_content_height() > registro.size.y + 0.5:
		_fallar("clipping vertical en RichTextLabel de diagnóstico")
		ok = false
	var linea := columna.get_node("Entrada") as LineEdit
	var ancho_texto := fuente.get_string_size(
		ENTRADA, HORIZONTAL_ALIGNMENT_LEFT, -1, 16
	).x
	if ancho_texto > linea.size.x - 16.0:
		_fallar("clipping horizontal en LineEdit de diagnóstico")
		ok = false
	return ok


func _guardar_manifest(
	kubasta_materializada: bool,
	terminal: Font,
	fallback: Font,
) -> void:
	var datos := {
		"issue": 298,
		"kubasta_materializada": kubasta_materializada,
		"modo_estricto": _exigir_kubasta,
		"terminal_resource_path": terminal.resource_path,
		"fallback_resource_path": fallback.resource_path,
		"tamanos_px": TAMANOS,
		"escalas": ESCALAS,
		"contrastes": ["oscuro", "claro"],
		"casos": _casos,
	}
	var ruta := _salida.path_join("manifest.json")
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		_fallar("no se pudo escribir %s" % ruta)
		return
	archivo.store_string(JSON.stringify(datos, "\t") + "\n")
	archivo.close()

	var readme := FileAccess.open(_salida.path_join("README.md"), FileAccess.WRITE)
	if readme == null:
		_fallar("no se pudo escribir README del gate")
		return
	readme.store_string(
		"# Gate visual Kubasta #298\n\n"
		+ "Comparar terminal vs IBM Plex Mono en claro/oscuro, 1x/1.25x y 10/12/14/16 px.\n"
		+ "La revisión humana debe comprobar legibilidad de español/símbolos, clipping, blur y ritmo.\n"
		+ ("Kubasta está materializada en esta ejecución.\n" if kubasta_materializada else "Kubasta aún no está materializada: la columna terminal usa el fallback.\n")
	)
	readme.close()


func _fallar(mensaje: String) -> void:
	_fallos += 1
	push_error("Gate visual #298: %s" % mensaje)
