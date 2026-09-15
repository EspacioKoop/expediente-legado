## Explorador corporativo del escritorio OS98 (#536).
##
## Presenta el modelo declarativo de ExploradorSigaModelo y mantiene únicamente
## estado de navegación/actividad reciente. No contiene estado de campaña.
class_name ExploradorSiga
extends VBoxContainer

var _modelo := ExploradorSigaModelo.new()
var _ruta_actual := ExploradorSigaModelo.RUTA_RAIZ
var _historial: Array[String] = []
var _indice_historial := -1

var _boton_atras: Button
var _boton_adelante: Button
var _boton_arriba: Button
var _ruta: LineEdit
var _lista: ItemList
var _visor: RichTextLabel
var _estado: Label


func configurar_contexto(contexto: Dictionary) -> void:
	_modelo.configurar_contexto(contexto)
	if is_node_ready():
		_refrescar()


func _ready() -> void:
	custom_minimum_size = Vector2(560, 390)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_construir_interfaz()
	_navegar_a(ExploradorSigaModelo.RUTA_RAIZ, true)


func _construir_interfaz() -> void:
	var barra := HBoxContainer.new()
	barra.name = "BarraNavegacion"
	barra.add_theme_constant_override("separation", 4)
	add_child(barra)

	_boton_atras = Button.new()
	_boton_atras.name = "Atras"
	_boton_atras.text = "<"
	_boton_atras.tooltip_text = "Atrás"
	_boton_atras.pressed.connect(_ir_atras)
	barra.add_child(_boton_atras)

	_boton_adelante = Button.new()
	_boton_adelante.name = "Adelante"
	_boton_adelante.text = ">"
	_boton_adelante.tooltip_text = "Adelante"
	_boton_adelante.pressed.connect(_ir_adelante)
	barra.add_child(_boton_adelante)

	_boton_arriba = Button.new()
	_boton_arriba.name = "Arriba"
	_boton_arriba.text = "↑"
	_boton_arriba.tooltip_text = "Subir un nivel"
	_boton_arriba.pressed.connect(_ir_arriba)
	barra.add_child(_boton_arriba)

	_ruta = LineEdit.new()
	_ruta.name = "Ruta"
	_ruta.placeholder_text = "Mi equipo"
	_ruta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ruta.text_submitted.connect(_ruta_introducida)
	barra.add_child(_ruta)

	var contenido := VSplitContainer.new()
	contenido.name = "Contenido"
	contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenido.split_offset = 220
	add_child(contenido)

	_lista = ItemList.new()
	_lista.name = "Entradas"
	_lista.custom_minimum_size = Vector2(0, 180)
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.select_mode = ItemList.SELECT_SINGLE
	_lista.item_activated.connect(_activar_indice)
	contenido.add_child(_lista)

	_visor = RichTextLabel.new()
	_visor.name = "VisorDocumento"
	_visor.custom_minimum_size = Vector2(0, 110)
	_visor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_visor.fit_content = false
	_visor.selection_enabled = true
	_visor.text = "Seleccione una carpeta o abra un documento con doble clic o Enter."
	contenido.add_child(_visor)

	_estado = Label.new()
	_estado.name = "Estado"
	_estado.text = ""
	add_child(_estado)


func _navegar_a(ruta: String, registrar_historial: bool) -> void:
	var normalizada := _modelo.normalizar_ruta(ruta)
	var entrada := _modelo.resolver_ruta(normalizada)
	if entrada.is_empty() or String(entrada.get("tipo", "")) != "carpeta":
		_mostrar_estado("Ruta no encontrada")
		return
	if not _modelo.puede_acceder(entrada):
		_mostrar_estado("Acceso denegado")
		return

	_ruta_actual = normalizada
	if registrar_historial:
		if _indice_historial < _historial.size() - 1:
			_historial.resize(_indice_historial + 1)
		_historial.append(_ruta_actual)
		_indice_historial = _historial.size() - 1
	_refrescar()


func _refrescar() -> void:
	if _lista == null:
		return
	_ruta.text = _ruta_legible(_ruta_actual)
	_lista.clear()
	for entrada in _modelo.listar_ruta(_ruta_actual):
		var bloqueada := not _modelo.puede_acceder(entrada)
		var tipo := String(entrada.get("tipo", ""))
		var prefijo := "[+] " if tipo == "carpeta" else "    "
		if bloqueada:
			prefijo = "[x] "
		var indice := _lista.add_item(prefijo + String(entrada.get("nombre", "")))
		_lista.set_item_metadata(indice, entrada)
		_lista.set_item_tooltip_enabled(indice, true)
		_lista.set_item_tooltip(indice, _descripcion_entrada(entrada, bloqueada))

	if _lista.item_count == 0:
		_mostrar_estado("Carpeta vacía")
	else:
		_mostrar_estado("%d elemento(s)" % _lista.item_count)
	_actualizar_navegacion()


func _activar_indice(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	var valor: Variant = _lista.get_item_metadata(indice)
	if not valor is Dictionary:
		return
	var entrada := valor as Dictionary
	if not _modelo.puede_acceder(entrada):
		_mostrar_estado("Acceso denegado")
		return
	if String(entrada.get("tipo", "")) == "carpeta":
		_navegar_a(String(entrada.get("ruta", "")), true)
		return
	_abrir_documento(entrada)


func _abrir_documento(entrada: Dictionary) -> void:
	var accion := String(entrada.get("accion", ""))
	if accion != "mostrar_contenido":
		_mostrar_estado("Este elemento no tiene una acción disponible")
		return
	_modelo.registrar_apertura(String(entrada.get("id", "")))
	var tipo := String(entrada.get("tipo", "texto"))
	var rotulo := String(
		(
			{
				"texto": "ARCHIVO DE TEXTO",
				"circular": "CIRCULAR INTERNA",
				"formulario": "FORMULARIO",
			}
			. get(tipo, "DOCUMENTO")
		)
	)
	_visor.text = (
		"%s — %s\n\n%s"
		% [
			rotulo,
			String(entrada.get("nombre", "")),
			String(entrada.get("contenido", "")),
		]
	)
	_mostrar_estado("Abierto: %s" % String(entrada.get("nombre", "")))
	# La carpeta virtual de recientes refleja inmediatamente actividad real.
	if _ruta_actual == ExploradorSigaModelo.RUTA_RECIENTES:
		_refrescar()


func _ir_atras() -> void:
	if _indice_historial <= 0:
		return
	_indice_historial -= 1
	_navegar_a(_historial[_indice_historial], false)


func _ir_adelante() -> void:
	if _indice_historial < 0 or _indice_historial >= _historial.size() - 1:
		return
	_indice_historial += 1
	_navegar_a(_historial[_indice_historial], false)


func _ir_arriba() -> void:
	if _ruta_actual == ExploradorSigaModelo.RUTA_RAIZ:
		return
	_navegar_a(_modelo.ruta_padre(_ruta_actual), true)


func _ruta_introducida(texto: String) -> void:
	_navegar_a(texto, true)


func _actualizar_navegacion() -> void:
	_boton_atras.disabled = _indice_historial <= 0
	_boton_adelante.disabled = _indice_historial < 0 or _indice_historial >= _historial.size() - 1
	_boton_arriba.disabled = _ruta_actual == ExploradorSigaModelo.RUTA_RAIZ


func _mostrar_estado(texto: String) -> void:
	if _estado != null:
		_estado.text = texto


func _ruta_legible(ruta: String) -> String:
	if ruta == ExploradorSigaModelo.RUTA_RAIZ:
		return "Mi equipo"
	return "Mi equipo/" + ruta.trim_prefix(ExploradorSigaModelo.RUTA_RAIZ + "/")


func _descripcion_entrada(entrada: Dictionary, bloqueada: bool) -> String:
	if bloqueada:
		return "Acceso restringido"
	var fecha := String(entrada.get("fecha_narrativa", ""))
	if fecha.is_empty():
		return String(entrada.get("nombre", ""))
	return "%s · %s" % [String(entrada.get("nombre", "")), fecha]
