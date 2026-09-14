## La Ventanilla de Reclamaciones: la pantalla.
##
## Aquí es donde el port deja de parecer un formulario. El resto de SIGA-98 es
## deliberadamente quieto —un documento no se mueve—, y esta pantalla es lo
## contrario: la réplica del rival **se escribe sola**, perder una vida
## **sacude** el mostrador y el aviso parpadea. Nada de eso cambia una regla;
## todo el juego está en `Combate`, que no sabe pintar.
##
## Tres cosas que el movimiento tiene que respetar para no mentir:
##
## - **La ronda ya está resuelta cuando empieza la animación.** Lo que se ve es
##   el relato de algo decidido, no un sorteo en curso — si no, una animación
##   interrumpida cambiaría el resultado.
## - **Se puede saltar.** Pulsar durante el escrito lo completa de golpe. Un
##   efecto de texto que obligue a esperar es lo que hace que la segunda
##   partida se juegue con el sonido quitado.
## - **Y se puede apagar.** `reduccion_movimiento` deja el mismo combate sin
##   sacudidas ni escritura progresiva.
extends Control

## Cuánto tarda en escribirse una réplica, por carácter.
const SEGUNDOS_POR_CARACTER := 0.018

## Cuánto se sacude el mostrador al encajar un golpe.
const SACUDIDA := 7.0
const SACUDIDA_SEGUNDOS := 0.28

var contenido := Contenido.new()
var partida := Partida.new()
var historias := Historias.new()

var combate: Dictionary = {}
var racha := 0
var reduccion_movimiento := false

var _azar := RandomNumberGenerator.new()
var _rival: Dictionary = {}
var _escribiendo := ""
var _escrito := 0.0
var _sacudida := 0.0
var _tablero: Control
var _replica: RichTextLabel
var _cronica: Label
var _vidas: Label
var _marcador: Label
var _botones: HBoxContainer
var _habilidades: HBoxContainer
var _lista: ItemList
var _ficha: RichTextLabel
var _habilidad_elegida_eje := ""


func _ready() -> void:
	theme = EstiloSiga.tema()
	contenido.cargar()
	historias.cargar()
	partida.cargar()
	_sembrar_tiradas()
	_construir()
	_llenar_turno()


func _process(delta: float) -> void:
	if not _escribiendo.is_empty():
		_escrito += delta / SEGUNDOS_POR_CARACTER
		var hasta := mini(int(_escrito), _escribiendo.length())
		_replica.text = _escribiendo.substr(0, hasta)
		if hasta >= _escribiendo.length():
			_escribiendo = ""

	if _sacudida > 0.0:
		_sacudida = maxf(0.0, _sacudida - delta)
		var fuerza := SACUDIDA * (_sacudida / SACUDIDA_SEGUNDOS)
		_tablero.position = Vector2(
			_azar.randf_range(-fuerza, fuerza), _azar.randf_range(-fuerza, fuerza)
		)
		if is_zero_approx(_sacudida):
			_tablero.position = Vector2.ZERO


func _unhandled_input(evento: InputEvent) -> void:
	# Saltar el escrito: quien ya ha leído la frase no tiene por qué esperarla.
	if evento.is_pressed() and not _escribiendo.is_empty():
		_escrito = float(_escribiendo.length())


func _draw() -> void:
	EstiloSiga.dibujar_bisel(self, Rect2(Vector2.ZERO, size), EstiloSiga.GRIS, true)


# --- Turno ------------------------------------------------------------------


func _llenar_turno() -> void:
	combate = {}
	_lista.clear()
	for reclamante in Ventanilla.disponibles(contenido, partida.estado["pistas_descubiertas"]):
		_lista.add_item(tr(reclamante["nombre"]))
		_lista.set_item_metadata(_lista.item_count - 1, reclamante)
	_lista.visible = true
	_botones.visible = false
	_habilidades.visible = false
	_cronica.text = tr("VENTANILLA_LLAME")
	_replica.text = ""
	_ficha.text = tr("VENTANILLA_NADIE")
	_actualizar_marcador()


func _al_llamar(indice: int) -> void:
	_rival = _lista.get_item_metadata(indice)
	combate = Combate.nuevo("reactiva", _rival, historias.cargas(partida.estado))
	_lista.visible = false
	_botones.visible = true
	_habilidades.visible = true
	_cronica.text = tr("VENTANILLA_SE_PRESENTA") % tr(_rival["nombre"])
	_replica.text = ""
	_pintar_ficha()
	_pintar_habilidades()
	_actualizar_marcador()


func _al_jugar(tipo: String) -> void:
	if combate.is_empty() or combate["terminado"]:
		return
	var ronda := Combate.jugar(combate, tipo, _habilidad_elegida(), _tirada())
	_habilidad_elegida_eje = ""
	_contar(ronda)


func _contar(ronda: Dictionary) -> void:
	var texto := (
		tr("COMBATE_CRONICA")
		% [
			Combate.etiqueta(ronda["tipo_jugador"]),
			tr(_rival["nombre"]),
			Combate.etiqueta(ronda["tipo_rival"]),
			_veredicto(ronda["veredicto"])
		]
	)
	if not ronda["revelada"].is_empty():
		texto += "\n" + tr("VENTANILLA_ADELANTA") % ronda["revelada"]
	_cronica.text = texto

	_decir(ronda["replica"])
	if ronda["dano_al_jugador"] > 0 and not reduccion_movimiento:
		_sacudida = SACUDIDA_SEGUNDOS

	_pintar_habilidades()
	_actualizar_marcador()

	if ronda["terminado"]:
		_cerrar(ronda["ganador"] == "jugador")


func _cerrar(gano: bool) -> void:
	var cierre := Ventanilla.cerrar(partida.estado, racha, gano)
	racha = cierre["racha"]
	for id in cierre["logros"]:
		Prometeo.desbloquear_carta(partida.estado["tarot"], id)
	# La racha y las cartas ya están dadas en memoria. Si no se pudo escribir,
	# se dice en la crónica y el botón de llamar al siguiente pasa a ser el
	# reintento: vuelve a guardar lo mismo, no vuelve a cerrar este turno.
	var se_guardo := partida.guardar()

	_botones.visible = false
	_habilidades.visible = false
	_cronica.text += (
		"\n\n%s" % (tr("VENTANILLA_ATENDIDA") % racha if gano else tr("VENTANILLA_NO_ATENDIDA"))
	)
	_actualizar_marcador()
	if not se_guardo:
		_cronica.text += "\n\n%s" % tr("ARCHIVO_ERROR_GUARDAR")

	# Un botón para volver a la cola, en vez de saltar solo: el jugador decide
	# cuándo llama al siguiente.
	var siguiente := Button.new()
	siguiente.text = tr("VENTANILLA_SIGUIENTE")
	siguiente.pressed.connect(
		func():
			if partida.guardado_pendiente:
				_cronica.text += (
					"\n\n%s"
					% (
						tr("ARCHIVO_GUARDADO_HECHO")
						if partida.guardar()
						else tr("ARCHIVO_ERROR_GUARDAR")
					)
				)
				if partida.guardado_pendiente:
					return
			siguiente.queue_free()
			_llenar_turno()
	)
	_botones.get_parent().add_child(siguiente)


## La ficha del reclamante: lo mismo que sabe el corcho de él. Un reclamante
## de oficio no tiene expediente, y eso se DICE en vez de dejar el hueco en
## blanco — que no tenga ficha es su rasgo, no un fallo de la pantalla.
func _pintar_ficha() -> void:
	var etiqueta := tr("FICHA_PERSONA") if _rival["tipo"] == "PERSONA" else tr("FICHA_COMITE")
	var cuerpo: String = tr(_rival.get("resumen", ""))
	_ficha.text = tr("FICHA_RECLAMANTE") % [tr(_rival["nombre"]), etiqueta, cuerpo]


func _decir(frase: String) -> void:
	if frase.is_empty():
		_replica.text = ""
		return
	if reduccion_movimiento:
		_replica.text = frase
		return
	_escribiendo = frase
	_escrito = 0.0
	_replica.text = ""


func _veredicto(cual: String) -> String:
	match cual:
		"gana_jugador":
			return tr("VEREDICTO_JUGADOR")
		"gana_rival":
			return tr("VEREDICTO_RIVAL")
		_:
			return tr("VEREDICTO_EMPATE")


## De dónde salen las tiradas de este combate (#147).
##
## Antes era `randomize()`, o sea el reloj: el mismo combate salía distinto cada
## vez y un careo que se torcía no se podía volver a ver. Ahora se deriva de la
## semilla de la partida, la vuelta y el día, así que el combate de un día es
## SIEMPRE el mismo combate — recargar la partida no vuelve a tirar los dados,
## que es justo lo que permitía repetir un turno hasta que saliera bien.
func _sembrar_tiradas() -> void:
	var jornada: Dictionary = partida.estado.get("jornada", {})
	_azar.seed = Azar.derivar(
		int(partida.estado.get("semilla", 0)),
		"combate",
		[int(jornada.get("vuelta", 1)), int(jornada.get("dia", 1))]
	)


## Las tiradas del combate salen de aquí, no de `randf` suelto: un solo sitio
## que sortea es un solo sitio al que mirar cuando algo sale raro.
func _tirada() -> Callable:
	return func(): return _azar.randf()


# --- Habilidades ------------------------------------------------------------


func _habilidad_elegida() -> String:
	return _habilidad_elegida_eje


func _pintar_habilidades() -> void:
	for hijo in _habilidades.get_children():
		hijo.queue_free()
	for eje in Combate.cargas_disponibles(combate):
		var habilidad: Dictionary = Historias.HABILIDADES[eje]
		var boton := Button.new()
		boton.text = tr("VENTANILLA_HABILIDAD") % [tr(habilidad["nombre"]), combate["cargas"][eje]]
		boton.tooltip_text = tr(habilidad["efecto"])
		boton.toggle_mode = true
		boton.pressed.connect(
			func():
				# Se arma para la ronda siguiente y no se gasta al pulsar: una
				# habilidad es una decisión DENTRO de la ronda.
				_habilidad_elegida_eje = eje if boton.button_pressed else ""
				for otro in _habilidades.get_children():
					if otro != boton:
						otro.button_pressed = false
		)
		_habilidades.add_child(boton)


func _actualizar_marcador() -> void:
	if combate.is_empty():
		_vidas.text = ""
	else:
		_vidas.text = (
			tr("COMBATE_VIDAS")
			% [
				_barra(combate["vida_jugador"]),
				combate["vida_jugador"],
				tr(_rival["nombre"]),
				_barra(combate["vida_rival"]),
				combate["vida_rival"]
			]
		)
	_marcador.text = (
		tr("VENTANILLA_MARCADOR") % [racha, partida.estado.get("coliseo_racha_mejor", 0)]
	)


## Las vidas como bloques y no como un número: se leen de un vistazo y el
## hueco que deja el que falta es lo que dice que has encajado un golpe.
func _barra(vidas: int) -> String:
	return "█".repeat(maxi(0, vidas)) + "░".repeat(maxi(0, Combate.VIDA_INICIAL - vidas))


# --- Cajas ------------------------------------------------------------------


func _construir() -> void:
	_tablero = VBoxContainer.new()
	_tablero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tablero.offset_left = 10
	_tablero.offset_top = 10
	_tablero.offset_right = -10
	_tablero.offset_bottom = -10
	_tablero.add_theme_constant_override("separation", 8)
	add_child(_tablero)

	_tablero.add_child(_titulo(tr("VENTANILLA_TITULO")))

	_marcador = _etiqueta("")
	_tablero.add_child(_marcador)

	_lista = ItemList.new()
	_lista.custom_minimum_size.y = 150
	_lista.add_theme_stylebox_override("panel", _hundido(EstiloSiga.BLANCO))
	_lista.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	_lista.item_activated.connect(_al_llamar)
	_lista.item_selected.connect(_al_llamar)
	_tablero.add_child(_lista)

	_vidas = _etiqueta("")
	_tablero.add_child(_vidas)

	_replica = RichTextLabel.new()
	_replica.bbcode_enabled = false
	_replica.custom_minimum_size.y = 120
	_replica.add_theme_stylebox_override("normal", _hundido(EstiloSiga.BLANCO))
	_replica.add_theme_color_override("default_color", EstiloSiga.NEGRO)
	_replica.add_theme_font_override("normal_font", theme.get_font("mono_font", "RichTextLabel"))
	_tablero.add_child(_replica)

	_cronica = _etiqueta("")
	_cronica.custom_minimum_size.y = 54
	_cronica.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_tablero.add_child(_cronica)

	# El hueco de en medio se llena con quién tienes delante, que es un dato que
	# ya existe en el corcho y que hacía falta: sin él, los reclamantes son
	# nombres intercambiables y da igual a quién atiendas.
	_ficha = RichTextLabel.new()
	_ficha.bbcode_enabled = true
	_ficha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ficha.add_theme_stylebox_override("normal", _hundido(EstiloSiga.GRIS))
	_ficha.add_theme_color_override("default_color", EstiloSiga.NEGRO)
	_tablero.add_child(_ficha)

	_botones = HBoxContainer.new()
	for tipo in Combate.TIPOS:
		var boton := Button.new()
		boton.text = Combate.etiqueta(tipo)
		boton.pressed.connect(_al_jugar.bind(tipo))
		_botones.add_child(boton)
	_tablero.add_child(_botones)

	_habilidades = HBoxContainer.new()
	_tablero.add_child(_habilidades)


func _titulo(texto: String) -> Control:
	var barra := PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = EstiloSiga.AZUL_TITULO
	caja.set_corner_radius_all(0)
	caja.content_margin_left = 6
	caja.content_margin_top = 3
	caja.content_margin_bottom = 3
	barra.add_theme_stylebox_override("panel", caja)
	var etiqueta := _etiqueta(texto)
	etiqueta.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	barra.add_child(etiqueta)
	return barra


func _etiqueta(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	etiqueta.add_theme_font_size_override("font_size", 14)
	return etiqueta


func _hundido(fondo: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.set_corner_radius_all(0)
	caja.border_width_top = EstiloSiga.GROSOR
	caja.border_width_left = EstiloSiga.GROSOR
	caja.border_width_bottom = EstiloSiga.GROSOR
	caja.border_width_right = EstiloSiga.GROSOR
	caja.border_color = EstiloSiga.GRIS_OSCURO
	caja.content_margin_left = 8
	caja.content_margin_right = 8
	caja.content_margin_top = 6
	caja.content_margin_bottom = 6
	return caja
