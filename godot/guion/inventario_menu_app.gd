## Superficie de inventario del menú global (#97).
##
## Muestra el inventario persistente sin crear una segunda fuente de verdad.
## Guardar/vender siguen fuera de esta superficie; #955 añade únicamente una
## combinación de dos objetos delegada al dominio transaccional. En casa enseña
## carried + home_storage; fuera de casa solo carried.
class_name InventarioMenuApp
extends PanelContainer

signal volver

const RUTA_TEXTOS := "res://datos/inventario_presentacion.json"

var _textos: Dictionary = {}
var _arbol: Tree
var _detalle: RichTextLabel
var _ayuda: Label
var _slot_a_boton: Button
var _slot_b_boton: Button
var _combinar_boton: Button
var _feedback_combinacion: Label
var _volver_boton: Button
var _estado_partida: Dictionary = {}
var _modelo_actual: Dictionary = {}
var _slot_a := ""
var _slot_b := ""


func _init() -> void:
	visible = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloSiga.tema()
	custom_minimum_size = Vector2(760, 500)
	_asegurar_montado()


static func etiqueta() -> String:
	var textos := _cargar_textos()
	return String(textos.get("titulo", "Inventario"))


## Modelo puro de presentación. Duplica los objetos para que una UI nunca pueda
## mutar el guardado por accidente.
static func modelo(estado_partida: Dictionary) -> Dictionary:
	var bruto = estado_partida.get("inventario", {})
	var inventario: Dictionary = (
		bruto.duplicate(true) if bruto is Dictionary else Inventario.nuevo()
	)
	Inventario.completar(inventario)
	var jornada = estado_partida.get("jornada", {})
	var en_casa := jornada is Dictionary and String(jornada.get("fase", "")) == "casa"
	return {
		"en_casa": en_casa,
		Inventario.CARRIED: inventario[Inventario.CARRIED].duplicate(true),
		Inventario.HOME_STORAGE:
		inventario[Inventario.HOME_STORAGE].duplicate(true) if en_casa else [],
	}


func abrir(estado_partida: Dictionary) -> void:
	_asegurar_montado()
	_estado_partida = estado_partida
	_slot_a = ""
	_slot_b = ""
	_modelo_actual = modelo(estado_partida)
	_refrescar()
	_refrescar_combinacion()
	visible = true
	var primero := _primer_objeto_seleccionable()
	if primero != null:
		primero.select(0)
		_arbol.grab_focus()
		_mostrar_detalle_seleccionado()
	else:
		_volver_boton.grab_focus()


## El controlador dueño del modal restaura pausa, ratón y HUD al recibir volver.
func cerrar() -> void:
	volver.emit()


func _asegurar_montado() -> void:
	if is_instance_valid(_arbol):
		return
	if _textos.is_empty():
		_textos = _cargar_textos()
	_montar()


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
	_arbol.item_activated.connect(_asignar_seleccion_al_primer_slot)
	cuerpo.add_child(_arbol)

	_detalle = RichTextLabel.new()
	_detalle.name = "InventarioDetalle"
	_detalle.bbcode_enabled = false
	_detalle.fit_content = false
	_detalle.scroll_active = true
	_detalle.custom_minimum_size.x = 330
	cuerpo.add_child(_detalle)

	var combinacion := VBoxContainer.new()
	combinacion.name = "CombinacionObjetos"
	combinacion.add_theme_constant_override("separation", 6)
	caja.add_child(combinacion)

	var combinacion_titulo := Label.new()
	combinacion_titulo.text = String(_textos.get("combinacion_titulo", "Combinar objetos"))
	combinacion.add_child(combinacion_titulo)

	var combinacion_ayuda := Label.new()
	combinacion_ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combinacion_ayuda.text = String(_textos.get("combinacion_ayuda", ""))
	combinacion.add_child(combinacion_ayuda)

	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	combinacion.add_child(slots)

	_slot_a_boton = Button.new()
	_slot_a_boton.name = "CombinacionSlotA"
	_slot_a_boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_a_boton.accessibility_name = String(_textos.get("combinacion_slot_a", "Ranura A"))
	_slot_a_boton.pressed.connect(_asignar_seleccion.bind("a"))
	slots.add_child(_slot_a_boton)

	_slot_b_boton = Button.new()
	_slot_b_boton.name = "CombinacionSlotB"
	_slot_b_boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_b_boton.accessibility_name = String(_textos.get("combinacion_slot_b", "Ranura B"))
	_slot_b_boton.pressed.connect(_asignar_seleccion.bind("b"))
	slots.add_child(_slot_b_boton)

	_combinar_boton = Button.new()
	_combinar_boton.name = "CombinacionEjecutar"
	_combinar_boton.text = String(_textos.get("combinacion_combinar", "Combinar"))
	_combinar_boton.pressed.connect(combinar_slots)
	combinacion.add_child(_combinar_boton)

	_feedback_combinacion = Label.new()
	_feedback_combinacion.name = "CombinacionFeedback"
	_feedback_combinacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combinacion.add_child(_feedback_combinacion)

	_volver_boton = Button.new()
	_volver_boton.name = "InventarioVolver"
	_volver_boton.text = String(_textos.get("volver", "Volver"))
	_volver_boton.pressed.connect(cerrar)
	caja.add_child(_volver_boton)


func _refrescar() -> void:
	_arbol.clear()
	_detalle.text = ""
	var en_casa := bool(_modelo_actual.get("en_casa", false))
	_ayuda.text = String(_textos.get("ayuda_casa" if en_casa else "ayuda_fuera", ""))
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


func seleccionar_para_combinar(objeto_id: String, slot: String) -> bool:
	if slot not in ["a", "b"] or not _objeto_visible(objeto_id):
		_feedback(String(_textos.get("combinacion_objeto_ausente", "Objeto no disponible.")))
		return false
	if slot == "a":
		_slot_a = "" if _slot_a == objeto_id else objeto_id
	else:
		_slot_b = "" if _slot_b == objeto_id else objeto_id
	_refrescar_combinacion()
	return true


func combinar_slots() -> Dictionary:
	var inventario := _inventario_mutable()
	var resultado := CombinacionObjetos.combinar(
		inventario, CombinacionesObjetosCatalogo.recetas(), _slot_a, _slot_b
	)
	if String(resultado.get("estado", "")) == CombinacionObjetos.ESTADO_EXITO:
		var objeto = resultado.get("resultado", {})
		var nombre := _nombre_objeto(objeto) if objeto is Dictionary else ""
		_feedback(String(_textos.get("combinacion_exito", "Combinación conseguida: %s")) % nombre)
		_slot_a = ""
		_slot_b = ""
		_modelo_actual = modelo(_estado_partida)
		_refrescar()
		_refrescar_combinacion()
		return resultado

	_feedback(_mensaje_fallo(String(resultado.get("motivo", ""))))
	_refrescar_combinacion()
	return resultado


func _asignar_seleccion(slot: String) -> void:
	var objeto := _objeto_seleccionado()
	if objeto.is_empty():
		_feedback(String(_textos.get("combinacion_sin_seleccion", "Selecciona un objeto.")))
		return
	seleccionar_para_combinar(String(objeto.get("id", "")), slot)


func _asignar_seleccion_al_primer_slot() -> void:
	var objeto := _objeto_seleccionado()
	if objeto.is_empty():
		return
	var slot := "a" if _slot_a.is_empty() else "b"
	seleccionar_para_combinar(String(objeto.get("id", "")), slot)


func _objeto_seleccionado() -> Dictionary:
	var seleccionado := _arbol.get_selected()
	if seleccionado == null:
		return {}
	var objeto = seleccionado.get_metadata(0)
	return objeto.duplicate(true) if objeto is Dictionary else {}


func _objeto_visible(objeto_id: String) -> bool:
	for ubicacion in [Inventario.CARRIED, Inventario.HOME_STORAGE]:
		for objeto in _modelo_actual.get(ubicacion, []):
			if objeto is Dictionary and String(objeto.get("id", "")) == objeto_id:
				return true
	return false


func _inventario_mutable() -> Dictionary:
	var bruto = _estado_partida.get("inventario", null)
	if not bruto is Dictionary:
		_estado_partida["inventario"] = Inventario.nuevo()
	var inventario: Dictionary = _estado_partida["inventario"]
	Inventario.completar(inventario)
	return inventario


func _refrescar_combinacion() -> void:
	if not is_instance_valid(_slot_a_boton):
		return
	_slot_a_boton.text = _texto_slot(
		String(_textos.get("combinacion_slot_a", "Ranura A")), _slot_a
	)
	_slot_b_boton.text = _texto_slot(
		String(_textos.get("combinacion_slot_b", "Ranura B")), _slot_b
	)
	_combinar_boton.disabled = _slot_a.is_empty() or _slot_b.is_empty()


func _texto_slot(titulo: String, objeto_id: String) -> String:
	var vacio := String(_textos.get("combinacion_vacia", "—"))
	return "%s: %s" % [titulo, vacio if objeto_id.is_empty() else _nombre_visible(objeto_id)]


func _nombre_visible(objeto_id: String) -> String:
	for ubicacion in [Inventario.CARRIED, Inventario.HOME_STORAGE]:
		for objeto in _modelo_actual.get(ubicacion, []):
			if objeto is Dictionary and String(objeto.get("id", "")) == objeto_id:
				return _nombre_objeto(objeto)
	return objeto_id.replace("_", " ").capitalize()


func _feedback(texto: String) -> void:
	if is_instance_valid(_feedback_combinacion):
		_feedback_combinacion.text = texto


func _mensaje_fallo(motivo: String) -> String:
	match motivo:
		"slot_vacio":
			return String(_textos.get("combinacion_slot_vacio", "Necesitas dos objetos."))
		"mismo_objeto":
			return String(_textos.get("combinacion_mismo_objeto", "Necesitas dos objetos distintos."))
		"sin_receta":
			return String(_textos.get("combinacion_sin_receta", "No encaja nada útil."))
		"objeto_ausente":
			return String(
				_textos.get("combinacion_objeto_ausente", "Uno de esos objetos ya no está disponible.")
			)
		_:
			return String(_textos.get("combinacion_error", "La combinación no pudo completarse."))


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
		var usos_texto := PackedStringArray()
		for uso in usos:
			usos_texto.append(String(uso))
		lineas.append(String(_textos.get("detalle_uso", "Uso: %s")) % ", ".join(usos_texto))
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
