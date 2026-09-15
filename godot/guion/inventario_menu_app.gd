## Superficie de inventario del menú global (#97).
##
## Es deliberadamente de consulta: muestra el inventario persistente sin crear
## una segunda fuente de verdad ni añadir acciones de guardar/vender. En casa
## enseña carried + home_storage; fuera de casa solo carried.
class_name InventarioMenuApp
extends PanelContainer

signal volver

const RUTA_TEXTOS := "res://datos/inventario_presentacion.json"

var _textos: Dictionary = {}
var _arbol: Tree
var _detalle: RichTextLabel
var _ayuda: Label
var _volver_boton: Button
var _modelo_actual: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloSiga.tema()
	custom_minimum_size = Vector2(760, 500)
	_textos = _cargar_textos()
	_montar()
	visible = false


static func etiqueta() -> String:
	var textos := _cargar_textos()
	return String(textos.get("titulo", "Inventario"))


## Modelo puro de presentación. Duplica los objetos para que una UI nunca pueda
## mutar el guardado por accidente.
static func modelo(estado_partida: Dictionary) -> Dictionary:
	var bruto = estado_partida.get("inventario", {})
	var inventario := bruto.duplicate(true) if bruto is Dictionary else Inventario.nuevo()
	Inventario.completar(inventario)
	var jornada = estado_partida.get("jornada", {})
	var en_casa := jornada is Dictionary and String(jornada.get("fase", "")) == "casa"
	return {
		"en_casa": en_casa,
		Inventario.CARRIED: inventario[Inventario.CARRIED].duplicate(true),
		Inventario.HOME_STORAGE: (
			inventario[Inventario.HOME_STORAGE].duplicate(true) if en_casa else []
		),
	}


func abrir(estado_partida: Dictionary) -> void:
	_modelo_actual = modelo(estado_partida)
	_refrescar()
	visible = true
	var primero := _primer_objeto_seleccionable()
	if primero != null:
		primero.select(0)
		_arbol.grab_focus()
		_mostrar_detalle_seleccionado()
	else:
		_volver_boton.grab_focus()


func cerrar() -> void:
	visible = false
	volver.emit()


func _montar() -> void:
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	margen.add_child(caja)

	var titulo := Label.new()
	titulo.text = String(_textos.get("titulo", "Inventario"))
	caja.add_child(titulo)

	_ayuda = Label.new()
	_ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_ayuda)

	var cuerpo := HSplitContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.custom_minimum_size.y = 350
	caja.add_child(cuerpo)

	_arbol = Tree.new()
	_arbol.name = "InventarioLista"
	_arbol.hide_root = true
	_arbol.custom_minimum_size.x = 330
	_arbol.item_selected.connect(_mostrar_detalle_seleccionado)
	cuerpo.add_child(_arbol)

	_detalle = RichTextLabel.new()
	_detalle.name = "InventarioDetalle"
	_detalle.bbcode_enabled = false
	_detalle.fit_content = false
	_detalle.scroll_active = true
	_detalle.custom_minimum_size.x = 330
	cuerpo.add_child(_detalle)

	_volver_boton = Button.new()
	_volver_boton.name = "InventarioVolver"
	_volver_boton.text = String(_textos.get("volver", "Volver"))
	_volver_boton.pressed.connect(cerrar)
	caja.add_child(_volver_boton)


func _refrescar() -> void:
	_arbol.clear()
	_detalle.text = ""
	var en_casa := bool(_modelo_actual.get("en_casa", false))
	_ayuda.text = String(
		_textos.get("ayuda_casa" if en_casa else "ayuda_fuera", "")
	)
	var raiz := _arbol.create_item()
	_llenar_seccion(
		raiz,
		String(_textos.get("carried", "Llevas encima")),
		_modelo_actual.get(Inventario.CARRIED, [])
	)
	if en_casa:
		_llenar_seccion(
			raiz,
			String(_textos.get("home_storage", "Guardado en casa")),
			_modelo_actual.get(Inventario.HOME_STORAGE, [])
		)


func _llenar_seccion(raiz: TreeItem, titulo: String, objetos) -> void:
	var seccion := _arbol.create_item(raiz)
	seccion.set_text(0, titulo)
	seccion.set_selectable(0, false)
	if not objetos is Array or objetos.is_empty():
		var vacio := _arbol.create_item(seccion)
		vacio.set_text(0, String(_textos.get("vacio", "Vacío")))
		vacio.set_selectable(0, false)
		return
	for objeto in objetos:
		if not objeto is Dictionary:
			continue
		var fila := _arbol.create_item(seccion)
		fila.set_text(0, _nombre_objeto(objeto))
		fila.set_metadata(0, objeto.duplicate(true))


func _primer_objeto_seleccionable() -> TreeItem:
	var raiz := _arbol.get_root()
	if raiz == null:
		return null
	var seccion := raiz.get_first_child()
	while seccion != null:
		var fila := seccion.get_first_child()
		while fila != null:
			if fila.is_selectable(0):
				return fila
			fila = fila.get_next()
		seccion = seccion.get_next()
	return null


func _mostrar_detalle_seleccionado() -> void:
	var seleccionado := _arbol.get_selected()
	if seleccionado == null:
		_detalle.text = ""
		return
	var objeto = seleccionado.get_metadata(0)
	if not objeto is Dictionary:
		_detalle.text = ""
		return
	_detalle.text = _texto_detalle(objeto)


func _texto_detalle(objeto: Dictionary) -> String:
	var lineas := [_nombre_objeto(objeto)]
	var descripcion := String(objeto.get("descripcion", "")).strip_edges()
	lineas.append(
		descripcion if not descripcion.is_empty() else String(_textos.get("sin_descripcion", ""))
	)
	var usos = objeto.get("usos", [])
	if usos is Array and not usos.is_empty():
		lineas.append(String(_textos.get("detalle_uso", "Uso: %s")) % ", ".join(usos))
	var origen := String(objeto.get("origen", "")).strip_edges()
	if not origen.is_empty():
		lineas.append(String(_textos.get("detalle_origen", "Origen: %s")) % origen)
	return "\n\n".join(lineas)


static func _nombre_objeto(objeto: Dictionary) -> String:
	var nombre := String(objeto.get("nombre", objeto.get("titulo", ""))).strip_edges()
	if not nombre.is_empty():
		return nombre
	return String(objeto.get("id", "objeto")).replace("_", " ").replace("-", " ").capitalize()


static func _cargar_textos() -> Dictionary:
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	return datos if datos is Dictionary else {}
