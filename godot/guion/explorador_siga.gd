## Explorador corporativo del escritorio OS98 (#536, #539, #664).
##
## Presenta el modelo declarativo de ExploradorSigaModelo y superpone los medios
## extraíbles simulados sin tocar el filesystem real ni conservar estado de campaña.
class_name ExploradorSiga
extends VBoxContainer

signal documento_abierto(id: String)
signal ruta_abierta(ruta: String)
signal paquete_software_obtenido(id: String)

var _modelo := ExploradorSigaModelo.new()
var _medios := MediosExtraiblesSigaModelo.new()
var _ruta_actual := ExploradorSigaModelo.RUTA_RAIZ
var _historial: Array[String] = []
var _indice_historial := -1

var _boton_atras: Button
var _boton_adelante: Button
var _boton_arriba: Button
var _ruta: LineEdit
var _selector_medio: OptionButton
var _boton_medio: Button
var _lista: ItemList
var _visor: RichTextLabel
var _estado: Label


func configurar_contexto(contexto: Dictionary) -> void:
	_modelo.configurar_contexto(contexto)
	_medios.configurar_contexto(contexto)
	if is_node_ready():
		if _resolver_ruta(_ruta_actual).is_empty():
			_ruta_actual = ExploradorSigaModelo.RUTA_RAIZ
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
	_boton_atras.tooltip_text = tr("EXPLORADOR_ATRAS")
	_boton_atras.pressed.connect(_ir_atras)
	barra.add_child(_boton_atras)

	_boton_adelante = Button.new()
	_boton_adelante.name = "Adelante"
	_boton_adelante.text = ">"
	_boton_adelante.tooltip_text = tr("EXPLORADOR_ADELANTE")
	_boton_adelante.pressed.connect(_ir_adelante)
	barra.add_child(_boton_adelante)

	_boton_arriba = Button.new()
	_boton_arriba.name = "Arriba"
	_boton_arriba.text = "↑"
	_boton_arriba.tooltip_text = tr("EXPLORADOR_SUBIR")
	_boton_arriba.pressed.connect(_ir_arriba)
	barra.add_child(_boton_arriba)

	_ruta = LineEdit.new()
	_ruta.name = "Ruta"
	_ruta.placeholder_text = tr("EXPLORADOR_RAIZ")
	_ruta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ruta.text_submitted.connect(_ruta_introducida)
	barra.add_child(_ruta)

	var barra_medios := HBoxContainer.new()
	barra_medios.name = "BarraMedios"
	barra_medios.add_theme_constant_override("separation", 4)
	add_child(barra_medios)

	_selector_medio = OptionButton.new()
	_selector_medio.name = "Medio"
	_selector_medio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selector_medio.item_selected.connect(_medio_seleccionado)
	barra_medios.add_child(_selector_medio)

	_boton_medio = Button.new()
	_boton_medio.name = "InsertarRetirarMedio"
	_boton_medio.pressed.connect(_alternar_medio)
	barra_medios.add_child(_boton_medio)

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
	_visor.text = tr("EXPLORADOR_VISOR_INICIAL")
	contenido.add_child(_visor)

	_estado = Label.new()
	_estado.name = "Estado"
	_estado.text = ""
	add_child(_estado)

	_refrescar_medios()


func _navegar_a(ruta: String, registrar_historial: bool) -> void:
	var normalizada := _modelo.normalizar_ruta(ruta)
	var entrada := _resolver_ruta(normalizada)
	if entrada.is_empty() or String(entrada.get("tipo", "")) != "carpeta":
		_mostrar_estado("Ruta no encontrada")
		return
	if not _puede_acceder(entrada):
		_mostrar_estado("Acceso denegado")
		return

	_ruta_actual = normalizada
	if registrar_historial:
		if _indice_historial < _historial.size() - 1:
			_historial.resize(_indice_historial + 1)
		_historial.append(_ruta_actual)
		_indice_historial = _historial.size() - 1
	_refrescar()
	ruta_abierta.emit(_ruta_actual)


func _refrescar() -> void:
	if _lista == null:
		return
	_refrescar_medios()
	_ruta.text = _ruta_legible(_ruta_actual)
	_lista.clear()
	for entrada in _listar_ruta(_ruta_actual):
		var bloqueada := not _puede_acceder(entrada)
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


func _resolver_ruta(ruta: String) -> Dictionary:
	var entrada := _modelo.resolver_ruta(ruta)
	if not entrada.is_empty():
		return entrada
	return _medios.resolver_ruta(ruta)


func _listar_ruta(ruta: String) -> Array[Dictionary]:
	var resultado := _modelo.listar_ruta(ruta)
	resultado.append_array(_medios.listar_ruta(ruta))
	return resultado


func _puede_acceder(entrada: Dictionary) -> bool:
	if entrada.has("medio_id"):
		return _medios.puede_acceder(entrada)
	return _modelo.puede_acceder(entrada)


func _activar_indice(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	var valor: Variant = _lista.get_item_metadata(indice)
	if not valor is Dictionary:
		return
	var entrada := valor as Dictionary
	if not _puede_acceder(entrada):
		_mostrar_estado("Acceso denegado")
		return
	if String(entrada.get("tipo", "")) == "carpeta":
		_navegar_a(String(entrada.get("ruta", "")), true)
		return
	_abrir_documento(entrada)


func _abrir_documento(entrada: Dictionary) -> void:
	var accion := String(entrada.get("accion", ""))
	if accion == "mostrar_paquete_software":
		_abrir_paquete_software(entrada)
		return
	if accion != "mostrar_contenido":
		_mostrar_estado("Este elemento no tiene una acción disponible")
		return
	var documento_id := String(entrada.get("id", ""))
	if not entrada.has("medio_id"):
		_modelo.registrar_apertura(documento_id)
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
	if not documento_id.is_empty():
		documento_abierto.emit(documento_id)
	if _ruta_actual == ExploradorSigaModelo.RUTA_RECIENTES:
		_refrescar()


func _abrir_paquete_software(entrada: Dictionary) -> void:
	var paquete_id := String(entrada.get("paquete_id", ""))
	var paquete := SoftwareSigaModelo.new().ficha(paquete_id)
	if paquete.is_empty():
		_mostrar_estado(tr("EXPLORADOR_MEDIO_PAQUETE_NO_RECONOCIDO"))
		return
	_visor.text = (
		tr("EXPLORADOR_MEDIO_PAQUETE_FICHA")
		% [
			String(paquete.get("nombre", paquete_id)),
			String(paquete.get("version", "")),
			String(paquete.get("descripcion", "")),
			String(entrada.get("procedencia_medio", "")),
		]
	)
	_mostrar_estado(tr("EXPLORADOR_MEDIO_SOFTWARE_DISPONIBLE") % String(paquete.get("nombre", "")))
	paquete_software_obtenido.emit(paquete_id)


func _refrescar_medios() -> void:
	if _selector_medio == null or _boton_medio == null:
		return
	var seleccionado := _id_medio_seleccionado()
	_selector_medio.clear()
	for medio in _medios.medios_disponibles():
		var indice := _selector_medio.item_count
		var id := String(medio.get("id", ""))
		var etiqueta := String(medio.get("etiqueta", id))
		var tipo := String(medio.get("tipo", ""))
		_selector_medio.add_item("%s · %s" % [etiqueta, tipo])
		_selector_medio.set_item_metadata(indice, id)
		if id == seleccionado:
			_selector_medio.select(indice)

	if _selector_medio.item_count == 0:
		_boton_medio.disabled = true
		_boton_medio.text = tr("EXPLORADOR_MEDIO_INSERTAR")
		return
	if _selector_medio.selected < 0:
		_selector_medio.select(0)
	_boton_medio.disabled = false
	_actualizar_boton_medio()


func _medio_seleccionado(_indice: int) -> void:
	_actualizar_boton_medio()


func _actualizar_boton_medio() -> void:
	if _boton_medio == null:
		return
	var id := _id_medio_seleccionado()
	if id.is_empty():
		_boton_medio.disabled = true
		_boton_medio.text = tr("EXPLORADOR_MEDIO_INSERTAR")
		return
	_boton_medio.disabled = false
	_boton_medio.text = (
		tr("EXPLORADOR_MEDIO_RETIRAR")
		if _medios.esta_montado(id)
		else tr("EXPLORADOR_MEDIO_INSERTAR")
	)


func _id_medio_seleccionado() -> String:
	if _selector_medio == null:
		return ""
	var indice := _selector_medio.selected
	if indice < 0 or indice >= _selector_medio.item_count:
		return ""
	return String(_selector_medio.get_item_metadata(indice))


func _alternar_medio() -> void:
	var id := _id_medio_seleccionado()
	if id.is_empty():
		return

	if _medios.esta_montado(id):
		var dentro := _medios.ruta_pertenece_a_medio(_ruta_actual, id)
		var destino := ExploradorSigaModelo.RUTA_RAIZ
		if _medios.unidad_persistente(id):
			destino = _medios.ruta_de_medio(id)
		_medios.desmontar(id)
		if dentro:
			_navegar_a(destino, true)
			_mostrar_estado(tr("EXPLORADOR_MEDIO_RETIRADO_VENTANA"))
		else:
			_refrescar()
			_mostrar_estado(tr("EXPLORADOR_MEDIO_RETIRADO"))
		return

	var ruta_unidad := _medios.ruta_de_medio(id)
	if not _medios.montar(id):
		_mostrar_estado(tr("EXPLORADOR_MEDIO_NO_DISPONIBLE"))
		return
	if _resolver_ruta(_ruta_actual).is_empty():
		_navegar_a(
			ruta_unidad if _medios.unidad_persistente(id) else ExploradorSigaModelo.RUTA_RAIZ, true
		)
	else:
		_refrescar()
		_mostrar_estado(tr("EXPLORADOR_MEDIO_INSERTADO"))


func _ir_atras() -> void:
	if _indice_historial <= 0:
		return
	var destino := _indice_historial - 1
	while destino >= 0:
		if not _resolver_ruta(_historial[destino]).is_empty():
			_indice_historial = destino
			_navegar_a(_historial[_indice_historial], false)
			return
		destino -= 1


func _ir_adelante() -> void:
	if _indice_historial < 0 or _indice_historial >= _historial.size() - 1:
		return
	var destino := _indice_historial + 1
	while destino < _historial.size():
		if not _resolver_ruta(_historial[destino]).is_empty():
			_indice_historial = destino
			_navegar_a(_historial[_indice_historial], false)
			return
		destino += 1


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
	var raiz := tr("EXPLORADOR_RAIZ")
	if ruta == ExploradorSigaModelo.RUTA_RAIZ:
		return raiz
	return raiz + "/" + ruta.trim_prefix(ExploradorSigaModelo.RUTA_RAIZ + "/")


func _descripcion_entrada(entrada: Dictionary, bloqueada: bool) -> String:
	if bloqueada:
		return "Acceso restringido"
	if entrada.has("medio_id"):
		var procedencia := String(entrada.get("procedencia_medio", ""))
		var capacidad := String(entrada.get("capacidad_medio", ""))
		var modo := (
			tr("EXPLORADOR_MEDIO_SOLO_LECTURA")
			if bool(entrada.get("solo_lectura", true))
			else tr("EXPLORADOR_MEDIO_LECTURA_ESCRITURA")
		)
		return "%s · %s · %s" % [capacidad, modo, procedencia]
	var fecha := String(entrada.get("fecha_narrativa", ""))
	if fecha.is_empty():
		return String(entrada.get("nombre", ""))
	return "%s · %s" % [String(entrada.get("nombre", "")), fecha]
