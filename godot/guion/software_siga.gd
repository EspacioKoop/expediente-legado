## Biblioteca de shareware/freeware ficticio del escritorio OS98 (#663).
##
## La ventana solo opera contra SoftwareSigaModelo. Las acciones de instalar,
## desinstalar y ejecutar son simuladas y emiten estado local persistible.
class_name SoftwareSiga
extends HSplitContainer

signal estado_cambiado(estado: Dictionary)

var _modelo := SoftwareSigaModelo.new()
var _lista: ItemList
var _titulo: Label
var _tipo: Label
var _origen: Label
var _licencia: Label
var _descripcion: RichTextLabel
var _estado: Label
var _resultado: Label
var _instalar: Button
var _ejecutar: Button


func configurar_estado(estado: Dictionary) -> void:
	_modelo.importar_estado(estado)
	if is_node_ready():
		_refrescar()


func exportar_estado() -> Dictionary:
	return _modelo.exportar_estado()


func _ready() -> void:
	custom_minimum_size = Vector2(600, 390)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_offset = 250
	_construir_interfaz()
	_refrescar()


func _construir_interfaz() -> void:
	var izquierda := VBoxContainer.new()
	izquierda.name = "Catalogo"
	izquierda.custom_minimum_size = Vector2(230, 0)
	izquierda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(izquierda)

	var cabecera := Label.new()
	cabecera.text = "Archivo de programas · 1998"
	izquierda.add_child(cabecera)

	var ayuda := Label.new()
	ayuda.text = "Enter/doble clic instala o ejecuta. Todo ocurre dentro del OS ficticio."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	izquierda.add_child(ayuda)

	_lista = ItemList.new()
	_lista.name = "Paquetes"
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.select_mode = ItemList.SELECT_SINGLE
	_lista.item_selected.connect(_seleccionar)
	_lista.item_activated.connect(_activar_indice)
	izquierda.add_child(_lista)

	var derecha := VBoxContainer.new()
	derecha.name = "Ficha"
	derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	derecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(derecha)

	_titulo = Label.new()
	_titulo.name = "Titulo"
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(_titulo)

	_tipo = Label.new()
	_tipo.name = "Tipo"
	derecha.add_child(_tipo)

	_origen = Label.new()
	_origen.name = "Origen"
	_origen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(_origen)

	_licencia = Label.new()
	_licencia.name = "Licencia"
	derecha.add_child(_licencia)

	_descripcion = RichTextLabel.new()
	_descripcion.name = "Descripcion"
	_descripcion.fit_content = false
	_descripcion.selection_enabled = true
	_descripcion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	derecha.add_child(_descripcion)

	_estado = Label.new()
	_estado.name = "Estado"
	derecha.add_child(_estado)

	var acciones := HBoxContainer.new()
	acciones.name = "Acciones"
	derecha.add_child(acciones)

	_instalar = Button.new()
	_instalar.name = "InstalarDesinstalar"
	_instalar.pressed.connect(_alternar_instalacion)
	acciones.add_child(_instalar)

	_ejecutar = Button.new()
	_ejecutar.name = "Ejecutar"
	_ejecutar.text = "Ejecutar / probar"
	_ejecutar.pressed.connect(_ejecutar_seleccion)
	acciones.add_child(_ejecutar)

	_resultado = Label.new()
	_resultado.name = "Resultado"
	_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(_resultado)


func _refrescar() -> void:
	if _lista == null:
		return
	var seleccionado := _id_seleccionado()
	_lista.clear()
	for paquete in _modelo.catalogo():
		var id := String(paquete.get("id", ""))
		var marca := "[instalado] " if _modelo.esta_instalado(id) else ""
		var indice := _lista.add_item(marca + String(paquete.get("nombre", id)))
		_lista.set_item_metadata(indice, id)
		if id == seleccionado:
			_lista.select(indice)

	var seleccion := _lista.get_selected_items()
	if seleccion.is_empty() and _lista.item_count > 0:
		_lista.select(0)
		_seleccionar(0)
	elif not seleccion.is_empty():
		_seleccionar(seleccion[0])


func _seleccionar(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	var id := String(_lista.get_item_metadata(indice))
	var paquete := _modelo.ficha(id)
	if paquete.is_empty():
		return
	_titulo.text = "%s · v%s" % [String(paquete.get("nombre", id)), String(paquete.get("version", "?"))]
	_tipo.text = "Tipo: %s · %d KB ficticios" % [String(paquete.get("tipo", "Utilidad")), int(paquete.get("tamano_kb", 0))]
	_origen.text = "Procedencia: %s" % String(paquete.get("origen", "desconocida"))
	_licencia.text = "Licencia ficticia: %s" % String(paquete.get("licencia", "freeware"))
	_descripcion.text = String(paquete.get("descripcion", ""))
	var instalado := _modelo.esta_instalado(id)
	_estado.text = "Estado: instalado" if instalado else "Estado: disponible"
	_instalar.text = "Desinstalar" if instalado else "Instalar"
	_ejecutar.disabled = not instalado
	_resultado.text = ""


func _activar_indice(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	_lista.select(indice)
	var id := String(_lista.get_item_metadata(indice))
	if _modelo.esta_instalado(id):
		_ejecutar_seleccion()
	else:
		_alternar_instalacion()


func _alternar_instalacion() -> void:
	var id := _id_seleccionado()
	if id.is_empty():
		return
	if _modelo.esta_instalado(id):
		_modelo.desinstalar(id)
	else:
		_modelo.instalar(id)
	_resultado.text = "Operación completada de forma simulada."
	estado_cambiado.emit(_modelo.exportar_estado())
	_refrescar()


func _ejecutar_seleccion() -> void:
	var id := _id_seleccionado()
	if id.is_empty():
		return
	var resultado := _modelo.ejecutar(id)
	_resultado.text = String(resultado.get("mensaje", ""))
	estado_cambiado.emit(_modelo.exportar_estado())


func _id_seleccionado() -> String:
	if _lista == null:
		return ""
	var seleccion := _lista.get_selected_items()
	if seleccion.is_empty():
		return ""
	return String(_lista.get_item_metadata(seleccion[0]))
