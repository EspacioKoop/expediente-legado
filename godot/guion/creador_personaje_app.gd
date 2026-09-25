## Ficha de creación del protagonista.
##
## No es un editor escultórico: ofrece diferencias grandes y legibles a baja
## resolución, coherentes con el estilo PSX, y mantiene separado el pasado del
## aspecto físico. La previsualización 3D consume el mismo perfil que se guarda,
## de modo que los controles nunca describen una silueta distinta a la jugable.
extends Control

const ANCHO_ETIQUETA := 150.0
const ALTO_CONTROL := 38.0
const TAM_BOTON := Vector2(190, 46)

var _partida := Partida.new()
var _perfil: Dictionary
var _alta_pendiente := false
var _avatar: OptionButton
var _altura: HSlider
var _previsualizacion: PrevisualizadorPersonaje3D
var _trasfondo: OptionButton
var _descripcion: Label
var _auditorias: AuditoriasSiga
var _resumen: Label
var _estado: Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = EstiloJuego.tema()
	_partida.cargar()
	_perfil = PerfilJugador.completar(_partida.estado.get("perfil_jugador", {}))
	_alta_pendiente = not PerfilJugador.esta_configurado(_perfil)
	if _alta_pendiente:
		var historial_auditoria := Auditorias.historial(_partida.estado)
		_partida.estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([], historial_auditoria, false)
	_construir()
	_cargar_controles()
	_refrescar()


func _construir() -> void:
	# Pantalla del jugador, no un programa de SIGA: fondo grafito propio y texto
	# claro. Sin él, el tema dejaba texto negro sobre el gris de serie de Godot.
	var fondo := ColorRect.new()
	fondo.name = "Fondo"
	fondo.color = EstiloJuego.FONDO
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	# Dentro del fondo y no a su lado: así el fondo es de verdad lo que hay detrás
	# de cada texto, también para `ContrasteTexto`.
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 48)
	for lado in ["top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 32)
	fondo.add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 18)
	margen.add_child(raiz)

	var titulo := Label.new()
	titulo.text = tr("PERSONAJE_TITULO")
	EstiloJuego.titulo_seccion(titulo, 30)
	raiz.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = tr("PERSONAJE_SUBTITULO")
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	EstiloJuego.secundario(subtitulo)
	raiz.add_child(subtitulo)

	var columnas := HBoxContainer.new()
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_theme_constant_override("separation", 24)
	raiz.add_child(columnas)

	var aspecto := _columna(columnas, "PERSONAJE_APARIENCIA", 1.0)
	# Un cuerpo entero de entre los de la ficha: cara, pelo y ropa vienen con
	# él. La altura es lo único que se ajusta encima.
	var avatares := []
	for avatar in PerfilJugador.AVATARES:
		avatares.append([avatar["nombre"], avatar["id"]])
	_avatar = _opcion(aspecto, "PERSONAJE_AVATAR", avatares)
	_altura = _deslizador(aspecto, "PERSONAJE_ALTURA", 0.92, 1.08)

	var vista := PanelContainer.new()
	vista.name = "Vista"
	vista.custom_minimum_size.x = 250.0
	vista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vista.size_flags_stretch_ratio = 0.9
	vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_child(vista)
	_previsualizacion = PrevisualizadorPersonaje3D.new()
	vista.add_child(_previsualizacion)

	var pasado := _columna(columnas, "PERSONAJE_TRASFONDO", 1.1)
	var etiqueta := Label.new()
	etiqueta.text = tr("PERSONAJE_ANTES_DE_SIGA")
	EstiloJuego.secundario(etiqueta)
	pasado.add_child(etiqueta)
	_trasfondo = OptionButton.new()
	_trasfondo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trasfondo.custom_minimum_size.y = ALTO_CONTROL
	for entrada in PerfilJugador.TRASFONDOS:
		_trasfondo.add_item(tr(String(entrada["nombre"])))
		_trasfondo.set_item_metadata(_trasfondo.item_count - 1, entrada["id"])
	_trasfondo.item_selected.connect(func(_indice): _refrescar())
	pasado.add_child(_trasfondo)

	_descripcion = Label.new()
	_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descripcion.custom_minimum_size.y = 72
	pasado.add_child(_descripcion)

	var nota := Label.new()
	nota.text = tr("PERSONAJE_NOTA_TRASFONDO")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	EstiloJuego.secundario(nota)
	pasado.add_child(nota)
	pasado.add_child(HSeparator.new())

	_auditorias = AuditoriasSiga.new()
	_auditorias.name = "AuditoriasIniciales"
	_auditorias.configurar_estado(_partida.estado, _alta_pendiente)
	pasado.add_child(_auditorias)

	var pie := HBoxContainer.new()
	pie.name = "Pie"
	pie.add_theme_constant_override("separation", 16)
	raiz.add_child(pie)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(textos)
	_resumen = Label.new()
	_resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	EstiloJuego.secundario(_resumen)
	textos.add_child(_resumen)
	_estado = Label.new()
	_estado.add_theme_color_override("font_color", EstiloJuego.ACENTO)
	textos.add_child(_estado)

	var volver := Button.new()
	volver.text = tr("PERSONAJE_CANCELAR")
	volver.custom_minimum_size = TAM_BOTON
	volver.pressed.connect(_volver)
	pie.add_child(volver)
	var guardar := Button.new()
	guardar.text = tr("PERSONAJE_GUARDAR")
	guardar.custom_minimum_size = TAM_BOTON
	EstiloJuego.hacer_primario(guardar)
	guardar.pressed.connect(_guardar)
	pie.add_child(guardar)


## Una columna del creador: tarjeta con su rótulo, y desplazable, porque la de
## trasfondo crece con las auditorías y a 720p no cabe entera.
func _columna(padre: HBoxContainer, clave: String, proporcion: float) -> VBoxContainer:
	var tarjeta := PanelContainer.new()
	tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tarjeta.size_flags_stretch_ratio = proporcion
	tarjeta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	padre.add_child(tarjeta)
	var desplazable := ScrollContainer.new()
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tarjeta.add_child(desplazable)
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", 12)
	desplazable.add_child(caja)
	_cabecera(caja, clave)
	return caja


func _cabecera(caja: VBoxContainer, clave: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = tr(clave)
	EstiloJuego.titulo_seccion(etiqueta, 20)
	caja.add_child(etiqueta)
	caja.add_child(HSeparator.new())


func _opcion(caja: VBoxContainer, clave: String, opciones: Array) -> OptionButton:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	caja.add_child(fila)
	var etiqueta := Label.new()
	etiqueta.text = tr(clave)
	etiqueta.custom_minimum_size.x = ANCHO_ETIQUETA
	fila.add_child(etiqueta)
	var control := OptionButton.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.y = ALTO_CONTROL
	for opcion in opciones:
		control.add_item(tr(String(opcion[0])))
		control.set_item_metadata(control.item_count - 1, opcion[1])
	control.item_selected.connect(func(_indice): _refrescar())
	fila.add_child(control)
	return control


func _deslizador(caja: VBoxContainer, clave: String, minimo: float, maximo: float) -> HSlider:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	caja.add_child(fila)
	var etiqueta := Label.new()
	etiqueta.text = tr(clave)
	etiqueta.custom_minimum_size.x = ANCHO_ETIQUETA
	fila.add_child(etiqueta)
	var control := HSlider.new()
	control.min_value = minimo
	control.max_value = maximo
	control.step = 0.01
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	control.custom_minimum_size.y = ALTO_CONTROL
	control.accessibility_name = etiqueta.text
	control.value_changed.connect(func(_valor): _refrescar())
	fila.add_child(control)
	return control


func _cargar_controles() -> void:
	var apariencia: Dictionary = _perfil["apariencia"]
	_seleccionar(_avatar, apariencia["avatar"])
	_altura.value = float(apariencia["altura"])
	_seleccionar(_trasfondo, _perfil["trasfondo"])


func _seleccionar(control: OptionButton, valor) -> void:
	for i in range(control.item_count):
		if control.get_item_metadata(i) == valor:
			control.select(i)
			return


func _valor(control: OptionButton):
	if control.selected < 0:
		return null
	return control.get_item_metadata(control.selected)


func _desde_controles() -> Dictionary:
	return (
		PerfilJugador
		. completar(
			{
				"apariencia":
				{
					"avatar": _valor(_avatar),
					"altura": _altura.value,
				},
				"trasfondo": _valor(_trasfondo),
			}
		)
	)


func _refrescar() -> void:
	if _trasfondo == null:
		return
	var candidato := _desde_controles()
	if _previsualizacion != null:
		_previsualizacion.aplicar(candidato)
	var pasado := PerfilJugador.trasfondo_por_id(String(candidato["trasfondo"]))
	_descripcion.text = tr(String(pasado.get("descripcion", "")))
	var etiquetas := Array(pasado.get("etiquetas", []))
	_resumen.text = (
		tr("PERSONAJE_RESUMEN")
		% [
			", ".join(etiquetas),
			_avatar.get_item_text(maxi(_avatar.selected, 0)),
			float(candidato["apariencia"]["altura"]),
		]
	)


func _guardar() -> void:
	_perfil = _desde_controles()
	_perfil["configurado"] = true
	_partida.estado["perfil_jugador"] = _perfil
	var auditoria_previa: Dictionary = {}
	if _alta_pendiente and _auditorias != null:
		auditoria_previa = (Dictionary(_partida.estado.get(Auditorias.CLAVE_ESTADO, {})).duplicate(
			true
		))
		if not Auditorias.resolver_seleccion(_partida.estado, _auditorias.seleccion()):
			_estado.text = tr("PERSONAJE_ERROR_GUARDAR")
			return
	if not _partida.guardar():
		if _alta_pendiente and not auditoria_previa.is_empty():
			_partida.estado[Auditorias.CLAVE_ESTADO] = auditoria_previa
		_estado.text = tr("PERSONAJE_ERROR_GUARDAR")
		return
	if _alta_pendiente:
		_alta_pendiente = false
		var error := get_tree().change_scene_to_file("res://escenas/dia.tscn")
		if error != OK:
			_estado.text = tr("PERSONAJE_ERROR_JORNADA")
		return
	_estado.text = tr("PERSONAJE_GUARDADA")


func _volver() -> void:
	get_tree().change_scene_to_file("res://escenas/inicio.tscn")
