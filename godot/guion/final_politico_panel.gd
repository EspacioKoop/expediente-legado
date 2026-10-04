## Epílogo político accesible para el clímax de Hastur (#1103 / #925).
##
## Presenta hechos de la vuelta antes de sintetizar el patrón. No anima ni
## bloquea el teclado: el botón recibe foco y la acción semántica cancelar
## también permite continuar.
##
## Consume hasta dos lecturas sociales ya registradas por #920, sin crear estado
## paralelo. #922/#923 todavía no exponen un evento persistido de epílogo: este
## presentador no los reconstruye ni inventa a partir del estado derivado del sueño.
## Si no hay lecturas compatibles, el cierre queda semánticamente equivalente.
class_name FinalPoliticoPanel
extends Control

signal continuar_solicitado

const RUTA_TEXTOS := "res://datos/final_politico_textos.json"
const MAX_ECOS := 2

var _resumen: Dictionary = {}
var _figura_vida: Array = []
var _ecos: Array = []
var _textos: Dictionary = {}
var _boton: Button


func configurar(resumen: Dictionary, figura_vida: Array = []) -> void:
	_resumen = resumen.duplicate(true)
	_figura_vida = figura_vida.duplicate(true)
	_ecos = _preparar_ecos(resumen)


func _ready() -> void:
	_textos = _cargar_textos()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_construir()


func bloquear(bloqueado: bool) -> void:
	if is_instance_valid(_boton):
		_boton.disabled = bloqueado


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancelar"):
		get_viewport().set_input_as_handled()
		continuar_solicitado.emit()


func _preparar_ecos(resumen: Dictionary) -> Array:
	var ecos: Array = []

	var exposicion = resumen.get("eco_exposicion", {})
	if typeof(exposicion) == TYPE_DICTIONARY:
		var detalle_exposicion: Dictionary = exposicion
		var fuente := String(detalle_exposicion.get("fuente", "")).strip_edges()
		var eje := String(detalle_exposicion.get("eje", "")).strip_edges()
		if not fuente.is_empty() and not eje.is_empty():
			ecos.append({"tipo": "exposicion", "detalle": detalle_exposicion.duplicate(true)})

	var sueno = resumen.get("eco_sueno", {})
	if ecos.size() < MAX_ECOS and typeof(sueno) == TYPE_DICTIONARY:
		var detalle_sueno: Dictionary = sueno
		var familia := String(detalle_sueno.get("familia", "")).strip_edges()
		if not familia.is_empty():
			ecos.append({"tipo": "sueno", "detalle": detalle_sueno.duplicate(true)})

	# #1875 sigue siendo parte del epílogo. Los ecos nuevos tienen prioridad
	# porque #2300 los añade explícitamente, pero las lecturas sociales rellenan
	# cualquier hueco disponible dentro del mismo presupuesto MAX_ECOS.
	var sociales := _ecos_sociales(resumen)
	for eco_social in sociales:
		if ecos.size() >= MAX_ECOS:
			break
		ecos.append(eco_social)

	return ecos


func _ecos_sociales(resumen: Dictionary) -> Array:
	var candidatos: Array = []
	var lecturas = resumen.get("lecturas_sociales", [])
	if typeof(lecturas) != TYPE_ARRAY:
		return candidatos

	for lectura in lecturas:
		if typeof(lectura) != TYPE_DICTIONARY:
			continue
		var actor := String(lectura.get("actor", "")).strip_edges()
		var evento := String(lectura.get("evento_observado", "")).strip_edges()
		if actor.is_empty() or evento.is_empty():
			continue
		(
			candidatos
			. append(
				{
					"tipo": "social",
					"id": "%s:%s" % [actor, evento],
					"detalle": (lectura as Dictionary).duplicate(true),
				}
			)
		)

	candidatos.sort_custom(func(a, b): return String(a["id"]) < String(b["id"]))
	return candidatos


static func _cargar_textos() -> Dictionary:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	return (datos as Dictionary).duplicate(true) if datos is Dictionary else {}


func _t(clave: String, fallback: String = "") -> String:
	return String(_textos.get(clave, fallback if not fallback.is_empty() else clave))


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.035, 0.03, 0.05, 0.94)
	add_child(fondo)

	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caja.position = Vector2(-380, -260)
	caja.custom_minimum_size = Vector2(760, 520)
	caja.add_theme_constant_override("separation", 12)
	add_child(caja)

	var ribbon := _etiqueta(_t("ribbon"))
	ribbon.name = "Ribbon"
	caja.add_child(ribbon)

	var patron := String(_resumen.get("patron", FinalPolitico.PATRON_SIN_REGISTRO))
	var titulo := _etiqueta(_t("titulo_%s" % patron))
	titulo.name = "Titulo"
	titulo.add_theme_font_size_override("font_size", 24)
	caja.add_child(titulo)

	var cuerpo := _etiqueta(_t("texto_%s" % patron))
	cuerpo.name = "Sintesis"
	caja.add_child(cuerpo)

	var dominantes: Array = _resumen.get("dominantes", [])
	var lectura := _etiqueta(_texto_dominantes(dominantes))
	lectura.name = "Dominantes"
	caja.add_child(lectura)

	var hechos_titulo := _etiqueta(_t("hechos_titulo"))
	hechos_titulo.name = "HechosTitulo"
	caja.add_child(hechos_titulo)

	var ejemplos: Array = _resumen.get("ejemplos", [])
	if ejemplos.is_empty():
		caja.add_child(_etiqueta(_t("hechos_vacio")))
	else:
		for ejemplo in ejemplos:
			caja.add_child(_etiqueta(_texto_ejemplo(ejemplo)))

	_montar_ecos(caja)
	_montar_religion(caja)
	_montar_auditorias(caja)
	_montar_vida(caja)

	_boton = Button.new()
	_boton.name = "Continuar"
	_boton.theme = EstiloSiga.tema()
	_boton.text = _t("continuar")
	_boton.accessibility_name = _boton.text
	_boton.pressed.connect(func(): continuar_solicitado.emit())
	caja.add_child(_boton)
	_boton.grab_focus()


func _montar_ecos(caja: VBoxContainer) -> void:
	if _ecos.is_empty():
		return

	var titulo := _etiqueta(_t("ecos_titulo"))
	titulo.name = "EcosTitulo"
	caja.add_child(titulo)

	for indice in range(_ecos.size()):
		var eco = _ecos[indice]
		var linea := _etiqueta(_texto_eco(eco))
		linea.name = "Eco%s" % indice
		caja.add_child(linea)


func _texto_eco(eco: Dictionary) -> String:
	var detalle_crudo = eco.get("detalle", {})
	if typeof(detalle_crudo) != TYPE_DICTIONARY:
		return ""
	var detalle: Dictionary = detalle_crudo
	match String(eco.get("tipo", "")):
		"exposicion":
			return _eco_exposicion(detalle)
		"sueno":
			return _eco_sueno(detalle)
		"social":
			return _eco_social(detalle)
		_:
			return ""


func _eco_exposicion(detalle: Dictionary) -> String:
	return (
		_t("eco_exposicion_formato", "%s · %s")
		% [
			_legible(String(detalle.get("fuente", ""))),
			_nombre_eje(String(detalle.get("eje", ""))),
		]
	)


func _eco_sueno(detalle: Dictionary) -> String:
	return _t("eco_sueno_formato", "%s") % _legible(String(detalle.get("familia", "")))


func _eco_social(detalle: Dictionary) -> String:
	var actor := String(detalle.get("actor", "")).strip_edges()
	if actor.is_empty():
		return ""
	var reaccion := String(detalle.get("reaccion", "")).strip_edges()
	if reaccion.is_empty():
		return _t("eco_social_formato") % actor
	return _t("eco_social_formato_detallado") % [actor, _legible(reaccion)]


func _montar_religion(caja: VBoxContainer) -> void:
	var resumen_crudo = _resumen.get("religion", {})
	if typeof(resumen_crudo) != TYPE_DICTIONARY:
		return
	var resumen: Dictionary = resumen_crudo
	if String(resumen.get("estado", "")) != "factual":
		return

	var modulos_crudos = resumen.get("modulos", [])
	if typeof(modulos_crudos) != TYPE_ARRAY:
		return
	var hechos := []
	for modulo_crudo in modulos_crudos:
		if typeof(modulo_crudo) != TYPE_DICTIONARY:
			continue
		var hechos_crudos = (modulo_crudo as Dictionary).get("hechos", [])
		if typeof(hechos_crudos) != TYPE_ARRAY:
			continue
		for hecho_crudo in hechos_crudos:
			if typeof(hecho_crudo) == TYPE_DICTIONARY:
				hechos.append((hecho_crudo as Dictionary).duplicate(true))
	if hechos.is_empty():
		return

	var titulo := _etiqueta(_t("religion_titulo"))
	titulo.name = "ReligionTitulo"
	caja.add_child(titulo)

	var limite := mini(4, hechos.size())
	for indice in range(limite):
		var linea := _etiqueta(_texto_hecho_religion(hechos[indice]))
		linea.name = "ReligionHecho%d" % indice
		caja.add_child(linea)
	if hechos.size() > limite:
		caja.add_child(_etiqueta(_t("religion_mas") % (hechos.size() - limite)))


func _texto_hecho_religion(hecho: Dictionary) -> String:
	var canal := String(hecho.get("canal", ""))
	var canales = _textos.get("religion_canales", {})
	var nombre_canal := canal
	if canales is Dictionary:
		nombre_canal = String((canales as Dictionary).get(canal, canal))

	var contexto := _legible(String(hecho.get("contexto", "")))
	var detalle := _legible(String(hecho.get("fuente", "")))
	if canal == ReligionEventos.CANAL_CONVICCION:
		var declaraciones = _textos.get("religion_declaraciones", {})
		var declaracion := String(hecho.get("declaracion", ""))
		if declaraciones is Dictionary and not declaracion.is_empty():
			detalle = String((declaraciones as Dictionary).get(declaracion, declaracion))
	elif canal == ReligionEventos.CANAL_VINCULO:
		var actor := String(hecho.get("actor", ""))
		if not actor.is_empty():
			detalle = _legible(actor)

	return _t("religion_hecho_formato") % [nombre_canal, contexto, detalle]


func _legible(valor: String) -> String:
	var limpio := valor.strip_edges()
	if limpio.is_empty():
		return _t("religion_sin_detalle")
	return limpio.replace(":", " · ").replace("_", " ").replace("-", " ").capitalize()


func _montar_auditorias(caja: VBoxContainer) -> void:
	var resumen_crudo = _resumen.get("auditoria", {})
	if typeof(resumen_crudo) != TYPE_DICTIONARY:
		return
	var condiciones_crudas = (resumen_crudo as Dictionary).get("condiciones", [])
	if typeof(condiciones_crudas) != TYPE_ARRAY or (condiciones_crudas as Array).is_empty():
		return

	var titulo := _etiqueta(tr("AUDITORIAS_FINAL_TITULO"))
	titulo.name = "AuditoriasTitulo"
	caja.add_child(titulo)
	for condicion in condiciones_crudas:
		if typeof(condicion) != TYPE_DICTIONARY:
			continue
		var fila: Dictionary = condicion
		var id := String(fila.get("id", ""))
		if id.is_empty():
			continue
		var nombre := tr("AUDITORIAS_%s" % id.to_upper())
		var estado := _texto_estado_auditoria(String(fila.get("estado", "")))
		var linea := _etiqueta(tr("AUDITORIAS_FINAL_LINEA") % [nombre, estado])
		linea.name = "Auditoria_%s" % id
		caja.add_child(linea)


func _montar_vida(caja: VBoxContainer) -> void:
	if _figura_vida.is_empty():
		return

	var lienzo := Control.new()
	lienzo.name = "RemateVidaVisual"
	lienzo.custom_minimum_size = Vector2(760, 190)
	lienzo.clip_contents = true
	lienzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(lienzo)

	for pieza in _figura_vida:
		if typeof(pieza) != TYPE_DICTIONARY:
			continue
		var rect_crudo = (pieza as Dictionary).get("rect")
		var color_crudo = (pieza as Dictionary).get("color")
		if typeof(rect_crudo) != TYPE_RECT2 or typeof(color_crudo) != TYPE_COLOR:
			continue
		var rect: Rect2 = rect_crudo
		var marca := ColorRect.new()
		marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marca.position = rect.position + Vector2(380, 95)
		marca.size = rect.size
		marca.color = color_crudo
		lienzo.add_child(marca)


func _texto_estado_auditoria(estado: String) -> String:
	match estado:
		"activa":
			return tr("AUDITORIAS_FINAL_ESTADO_ACTIVA")
		"fallida":
			return tr("AUDITORIAS_FINAL_ESTADO_FALLIDA")
		"completada":
			return tr("AUDITORIAS_FINAL_ESTADO_COMPLETADA")
		_:
			return tr("AUDITORIAS_FINAL_ESTADO_PENDIENTE")


func _texto_dominantes(dominantes: Array) -> String:
	if dominantes.is_empty():
		return _t("dominantes_vacio")
	var nombres := []
	for eje in dominantes:
		nombres.append(_nombre_eje(String(eje)))
	if nombres.size() == 1:
		return _t("dominante_uno") % nombres[0]
	return _t("dominante_plural") % ", ".join(nombres)


func _texto_ejemplo(ejemplo: Dictionary) -> String:
	var contexto := String(ejemplo.get("contexto", "")).replace("-", " ").capitalize()
	var eje := _nombre_eje(String(ejemplo.get("eje", "")))
	return _t("hecho_formato") % [contexto, eje]


func _nombre_eje(eje: String) -> String:
	var ejes = _textos.get("ejes", {})
	if ejes is Dictionary:
		return String((ejes as Dictionary).get(eje, eje))
	return eje


func _etiqueta(texto: String) -> Label:
	var marca := Label.new()
	marca.text = texto
	marca.theme = EstiloSiga.tema()
	marca.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	marca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marca.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	marca.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	marca.add_theme_constant_override("outline_size", 4)
	return marca
