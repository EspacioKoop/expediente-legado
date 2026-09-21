extends SceneTree

## Gate de #1055: la capa de paleta reconoce la fixture GB clásica (0x00),
## rechaza la CGB-only (0xC0) y fuerza el shader a normal al salir del modo GB.
## Uso: ... -- <dmg_only_smoke.gb> <cgb_only_smoke.gbc>


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.size() != 2:
		_fallar("se esperaban las rutas DMG-only y CGB-only")
		return

	var dmg := FileAccess.get_file_as_bytes(String(argumentos[0]))
	var cgb := FileAccess.get_file_as_bytes(String(argumentos[1]))
	if dmg.size() <= 0x143 or cgb.size() <= 0x143:
		_fallar("fixtures de paleta truncadas")
		return

	var app := EmuladorPortatilApp.new()
	if not bool(app.call("_es_rom_gb_clasica", dmg)):
		app.free()
		_fallar("la fixture 0x00 no habilita las paletas GB")
		return
	if bool(app.call("_es_rom_gb_clasica", cgb)):
		app.free()
		_fallar("la fixture CGB-only habilitó recoloreado externo")
		return

	var vista := TextureRect.new()
	app.set("_vista", vista)
	app.call("_preparar_filtro_lcd")
	app.set("_rom_gb_clasica_actual", true)
	app.call("_aplicar_paleta", "ambar")
	var material = app.get("_lcd_material")
	if not (material is ShaderMaterial):
		app.free()
		_fallar("no se creó ShaderMaterial para la pantalla")
		return
	if not bool(material.get_shader_parameter("paleta_gb_activa")):
		app.free()
		_fallar("la paleta propia no se activó para GB clásico")
		return

	app.set("_rom_gb_clasica_actual", false)
	app.call("_aplicar_paleta", "ambar")
	if bool(material.get_shader_parameter("paleta_gb_activa")):
		app.free()
		_fallar("el shader mantuvo la paleta al pasar a CGB")
		return

	app.free()
	print("Paletas GB smoke: OK · 0x00 opt-in · CGB forzado a normal")
	quit(0)


func _fallar(mensaje: String) -> void:
	push_error("Paletas GB smoke #1055: %s" % mensaje)
	quit(1)
