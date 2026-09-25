## Regresión headless del filtro de pantalla de época (#1270).
##
## En headless no hay RenderingDevice, así que el efecto no pinta: lo que se
## prueba es el contrato que decide QUÉ se pinta —preferencia, preajuste,
## compositor montado en los mundos reales, reducción de movimiento— y que el
## shader compila. Cómo se ve lo dicen las capturas en GPU real.
extends SceneTree

const RUTA_PRUEBA := "user://prueba-filtro-pantalla-1270.json"
const CLAVES_EFECTO := [
	"lineas",
	"sangrado",
	"franjas",
	"vineta",
	"grano",
	"temblor",
	"desfase_color",
	"lineas_pantalla",
]

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	_probar_shaders()
	_probar_preajustes()
	_probar_preferencias()
	_probar_aplicar()
	_probar_menu()
	_probar_integraciones_3d()
	await _probar_mundos_reales()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_shaders() -> void:
	var fichero: RDShaderFile = load(EfectoPantalla98.SHADER)
	_comprobar(fichero != null, "el filtro se importa como shader de cómputo")
	if fichero != null:
		var error := fichero.get_spirv().compile_error_compute
		_comprobar(error.is_empty(), "el filtro compila: %s" % error)


func _probar_preajustes() -> void:
	_comprobar(FiltroPantalla.ids()[0] == FiltroPantalla.NINGUNO, "«ninguno» va primero")
	_comprobar(FiltroPantalla.ids().size() == 4, "ninguno, monitor, televisor y vhs")
	for id in FiltroPantalla.ids():
		if id == FiltroPantalla.NINGUNO:
			continue
		var ajuste: Dictionary = FiltroPantalla.PREAJUSTES[id]
		for clave in CLAVES_EFECTO:
			_comprobar(ajuste.has(clave), "%s declara %s" % [id, clave])
	_comprobar(FiltroPantalla.valido("vhs") == "vhs", "un preajuste válido se conserva")
	_comprobar(FiltroPantalla.valido("plasma") == "ninguno", "uno inventado vuelve a ninguno")
	_comprobar(FiltroPantalla.valido(3) == "ninguno", "un tipo raro vuelve a ninguno")
	_comprobar(FiltroPantalla.valido(null) == "ninguno", "la ausencia es ninguno")


func _probar_preferencias() -> void:
	_comprobar(
		PreferenciasSiga.nuevas()["filtro_pantalla"] == "ninguno",
		"por defecto el juego se ve sin filtro"
	)
	# Preferencias v2 guardadas antes de #1270, sin la clave.
	var antiguas := PreferenciasSiga.nuevas()
	antiguas.erase("filtro_pantalla")
	PreferenciasSiga.guardar(antiguas, RUTA_PRUEBA)
	_comprobar(
		PreferenciasSiga.cargar(RUTA_PRUEBA)["filtro_pantalla"] == "ninguno",
		"unas preferencias antiguas cargan sin filtro"
	)
	var con_filtro := PreferenciasSiga.nuevas()
	con_filtro["filtro_pantalla"] = "televisor"
	PreferenciasSiga.guardar(con_filtro, RUTA_PRUEBA)
	_comprobar(
		PreferenciasSiga.cargar(RUTA_PRUEBA)["filtro_pantalla"] == "televisor",
		"el filtro elegido persiste"
	)
	con_filtro["filtro_pantalla"] = "plasma"
	PreferenciasSiga.guardar(con_filtro, RUTA_PRUEBA)
	_comprobar(
		PreferenciasSiga.cargar(RUTA_PRUEBA)["filtro_pantalla"] == "ninguno",
		"uno desconocido en disco se descarta"
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_PRUEBA))


func _probar_aplicar() -> void:
	var entorno := WorldEnvironment.new()
	root.add_child(entorno)

	FiltroPantalla.aplicar(entorno, {"filtro_pantalla": "ninguno"})
	_comprobar(entorno.compositor == null, "sin filtro no hay compositor")
	_comprobar(entorno.is_in_group(FiltroPantalla.GRUPO), "pero el entorno queda localizable")

	FiltroPantalla.aplicar(entorno, {"filtro_pantalla": "vhs"})
	var efecto := _efecto_de(entorno)
	_comprobar(efecto != null, "con filtro hay un EfectoPantalla98")
	if efecto != null:
		_comprobar(
			efecto.effect_callback_type == CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT,
			"corre sobre el 3D ya compuesto, antes del lienzo 2D"
		)
		_comprobar(is_equal_approx(efecto.temblor, 1.0), "el vhs tiembla")
		_comprobar(not efecto.congelado, "sin reducción de movimiento, el tiempo corre")
		var parametros := efecto.parametros(Vector2i(1920, 1080))
		_comprobar(parametros.size() * 4 == 48, "48 bytes de push constants, múltiplo de 16")
		_comprobar(is_equal_approx(parametros[0], 1920.0), "el tamaño va primero")

	FiltroPantalla.aplicar(entorno, {"filtro_pantalla": "vhs", "reduccion_movimiento": true})
	efecto = _efecto_de(entorno)
	_comprobar(efecto != null and efecto.congelado, "con reducción de movimiento se congela")
	if efecto != null:
		_comprobar(
			is_zero_approx(efecto.parametros(Vector2i(8, 8))[2]),
			"congelado, el tiempo que llega al shader es cero"
		)

	# El menú cambia el filtro de todos los mundos montados a la vez.
	var otro := WorldEnvironment.new()
	root.add_child(otro)
	FiltroPantalla.aplicar(otro, {"filtro_pantalla": "monitor"})
	FiltroPantalla.refrescar(self, {"filtro_pantalla": "ninguno"})
	_comprobar(
		entorno.compositor == null and otro.compositor == null, "refrescar quita el filtro a todos"
	)
	entorno.free()
	otro.free()


func _probar_menu() -> void:
	var menu: Node = load("res://guion/menu_global.gd").new()
	menu.set("_preferencias", {"filtro_pantalla": "televisor"})
	menu.set("_textos_filtro", menu.call("_cargar_json", menu.RUTA_TEXTOS_FILTRO))
	var caja := VBoxContainer.new()
	menu.call("_montar_filtro_pantalla", caja)
	var selector: OptionButton = menu.get("_filtro")
	_comprobar(selector != null, "el menú de opciones tiene selector de filtro")
	if selector != null:
		_comprobar(selector.item_count == 4, "con los cuatro preajustes")
		_comprobar(
			selector.get_item_metadata(selector.selected) == "televisor",
			"marcando el que está guardado"
		)
		for i in selector.item_count:
			var id := String(selector.get_item_metadata(i))
			_comprobar(selector.get_item_text(i) != id, "%s tiene nombre legible" % id)
			_comprobar(not selector.get_item_tooltip(i).is_empty(), "%s explica qué es" % id)
	caja.free()
	menu.free()


func _probar_integraciones_3d() -> void:
	var rutas := [
		"res://guion/careo_app.gd",
		"res://guion/juicio_combate_arena_3d.gd",
	]
	for ruta in rutas:
		var fichero := FileAccess.open(ruta, FileAccess.READ)
		_comprobar(fichero != null, "%s se puede inspeccionar" % ruta)
		if fichero == null:
			continue
		var fuente := fichero.get_as_text()
		_comprobar(
			fuente.contains("FiltroPantalla.aplicar("),
			"%s aplica el filtro al WorldEnvironment" % ruta
		)


func _probar_mundos_reales() -> void:
	# El plató de cinemáticas es otro mundo 3D y también lleva el filtro.
	var reproductor: Node = load("res://escenas/cinematica.tscn").instantiate()
	root.add_child(reproductor)
	await process_frame
	var platos := reproductor.find_children("*", "WorldEnvironment", true, false)
	_comprobar(
		platos.size() == 1 and platos[0].is_in_group(FiltroPantalla.GRUPO),
		"el plató de cinemáticas monta su entorno por FiltroPantalla"
	)
	reproductor.free()

	var dia: Node = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame
	var del_dia := get_nodes_in_group(FiltroPantalla.GRUPO).filter(
		func(n): return dia.is_ancestor_of(n)
	)
	_comprobar(not del_dia.is_empty(), "el mundo del día monta su entorno por FiltroPantalla")
	# El día se queda montado hasta `quit`: liberarlo aquí corta corrutinas del
	# onboarding a medias y ensucia la salida con errores que no son de esto.


func _efecto_de(entorno: WorldEnvironment) -> EfectoPantalla98:
	if entorno.compositor == null or entorno.compositor.compositor_effects.is_empty():
		return null
	return entorno.compositor.compositor_effects[0] as EfectoPantalla98


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
