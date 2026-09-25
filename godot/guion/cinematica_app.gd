## El reproductor común de cinemáticas.
##
## Es la respuesta a que el medio lo elija cada momento: si cada cinemática
## trajera su propio reproductor, diez momentos darían diez ritmos, diez
## rótulos y diez formas de saltar. Aquí sabe pintar planos 3D (mueve una
## cámara por el mundo de la escena) y planos 2D (mueve figuras declaradas como
## rectángulos sobre un fondo), y aporta lo común: el rótulo, la voz, el salto
## y el acortado por repetición.
##
## Un plano 3D puede optar por una trayectoria explícita con `camara_desde` y/o
## `mira_desde`. Los planos antiguos conservan exactamente su acercamiento corto.
## La extensión es solo de puesta en escena: no cambia estado ni duración.
##
## Sobre todo eso pone el lenguaje de cine común (`LenguajeCine`, #395):
## formato panorámico con franjas, focal cerrada con profundidad de campo,
## cámara en mano leve, grano y viñeta. Un plano puede ajustar `fov` y `foco`.
##
## No sabe qué cinemática está poniendo. Recibe planos ya resueltos y emite
## `terminada` cuando acaba o cuando la saltan — quien la pidió decide qué pasa
## después.
extends Node3D

signal terminada

## Avisa de en qué plano va. Existe para que una escena pueda colgar algo de un
## momento concreto —el compañero que se acerca en el segundo plano del careo—
## sin tener que llevar su propio reloj en paralelo, que es como se
## desincronizan las cosas.
signal plano_entrado(indice: int, plano: Dictionary)

## Override opcional del mundo 3D. Los llamantes antiguos pueden seguir
## pasándolo, pero no hace falta: como este reproductor es Node3D, si está
## montado dentro de la escena jugable ya comparte su World3D y la cámara puede
## rodar ahí directamente. Así una cinemática no necesita conocer `_mundo` ni
## ninguna propiedad privada de quien la instancia.
var mundo: Node3D = null

var _rodaje: Array = []
var _plano := 0
var _transcurrido := 0.0
var _reproduciendo := false
var _id := ""
var _estado: Dictionary = {}
var _reduccion_movimiento := false

var _camara: Camera3D
## El plató: un mundo 3D propio para los planos que traen `decorado`. Existe
## porque hay momentos —el sello, la carta— que ocurren dentro de una pantalla
## de interfaz, sin sala detrás por la que mover la cámara.
var _plato: SubViewportContainer
var _vista_plato: SubViewport
var _decorado: Node3D
var _huella_decorado := 0
var _lienzo: Control
var _rotulo: Label
var _voz: Label
var _fondo: ColorRect
var _figuras: Node2D
var _fundido: ColorRect
var _grano: ColorRect
var _franja_superior: ColorRect
var _franja_inferior: ColorRect
## Reloj de toda la cinemática, no del plano: las franjas entran al empezar la
## secuencia y salen al acabarla, no en cada corte.
var _reloj := 0.0
var _total := 0.0


func _ready() -> void:
	_montar()


## Pone una cinemática ya resuelta (ver `Cinematica.resolver`).
##
## Si se le dan [param id] y [param estado], **anota él mismo** que se ha visto,
## al terminar o al saltar. Podría hacerlo cada llamante, y por eso lo hace el
## reproductor: de diez sitios que tengan que acordarse, uno no se acuerda, y su
## cinemática se quedaría eterna mientras las otras nueve se acortan.
func reproducir(rodaje: Array, id: String = "", estado: Dictionary = {}) -> void:
	_id = id
	_estado = estado
	_rodaje = rodaje
	_reduccion_movimiento = bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	_plano = -1
	_reproduciendo = true
	visible = true
	_reloj = 0.0
	_total = Cinematica.duracion(rodaje)
	_grano.material.set_shader_parameter("quieto", _reduccion_movimiento)
	_grano.visible = true
	_actualizar_franjas()
	_siguiente()


func saltar() -> void:
	if not _reproduciendo:
		return
	_terminar()


func _process(delta: float) -> void:
	if not _reproduciendo:
		return
	_transcurrido += delta
	_reloj += delta
	_actualizar_franjas()
	var plano: Dictionary = _rodaje[_plano]
	var duracion: float = plano["segundos"]
	var avance: float = clampf(_transcurrido / duracion, 0.0, 1.0)

	match plano["tipo"]:
		"3d":
			_mover_camara(plano, avance)
		"2d":
			_figuras.queue_redraw()
	_actualizar_fundido(plano, avance)

	if _transcurrido >= duracion:
		_siguiente()


func _unhandled_input(evento: InputEvent) -> void:
	# El salto debe ser deliberado. Las transiciones suelen empezar mientras el
	# jugador aún mantiene movimiento; aceptar cualquier `pressed` hacía que un
	# repeat de esa tecla cerrase la cinemática en su primer fotograma (#280).
	if not _reproduciendo:
		return
	if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("ui_cancel"):
		saltar()


func _siguiente() -> void:
	_plano += 1
	_transcurrido = 0.0
	if _plano >= _rodaje.size():
		_terminar()
		return

	var plano: Dictionary = _rodaje[_plano]
	_rotulo.text = String(plano.get("rotulo", ""))
	_voz.text = String(plano.get("voz", ""))
	# Un rótulo largo es una frase y quiere cuerpo menor; uno corto es un
	# nombre y quiere presencia.
	_rotulo.add_theme_font_size_override("font_size", 34 if _rotulo.text.length() > 28 else 48)

	_actualizar_fundido(plano, 0.0)
	plano_entrado.emit(_plano, plano)
	_sonar_plano(plano)

	var es_2d: bool = plano["tipo"] == "2d"
	_fondo.visible = es_2d
	_figuras.visible = es_2d
	var decorado: Dictionary = plano.get("decorado", {}) if not es_2d else {}
	_preparar_plato(decorado)
	if _camara != null:
		_camara.current = not es_2d and (not decorado.is_empty() or _tiene_mundo_3d())
		if not es_2d:
			_ajustar_optica(plano)


## Acento puntual opt-in del plano. Se delega en `Sonido`, que crea una voz
## efímera y la libera al terminar. El reproductor no conserva AudioStream ni
## AudioStreamPlayer propios: al cerrar/saltar la cinemática, liberar este nodo
## libera también cualquier hijo que todavía estuviera sonando.
func _sonar_plano(plano: Dictionary) -> void:
	var nombre := String(plano.get("sonido", ""))
	if nombre.is_empty():
		return
	var tono := float(plano.get("sonido_tono", 1.0))
	Sonido.sonar(self, nombre, tono)


func _terminar() -> void:
	_reproduciendo = false
	# Los acentos pueden seguir sonando al saltar o al avanzar artificialmente
	# una prueba. Se cortan aquí, antes de que el llamante reciba `terminada`
	# y libere este nodo, para no dejar recursos de audio vivos al desmontar.
	Sonido.detener(self)
	# Saltarla cuenta como verla: quien la salta ya la conoce, que es
	# exactamente lo que el acortado quiere premiar.
	if not _id.is_empty() and not _estado.is_empty():
		Cinematica.anotar_vista(_estado, _id)
	_rotulo.text = ""
	_voz.text = ""
	_grano.visible = false
	_actualizar_franjas()
	_fondo.visible = false
	_figuras.visible = false
	if _fundido != null:
		_fundido.color = Color(0.0, 0.0, 0.0, 0.0)
	_preparar_plato({})
	terminada.emit()


func _tiene_mundo_3d() -> bool:
	return mundo != null or (is_inside_tree() and get_world_3d() != null)


func _mover_camara(plano: Dictionary, avance: float) -> void:
	if _camara == null or not (_plato.visible or _tiene_mundo_3d()):
		return
	var destino: Vector3 = plano["camara"]
	var mira_destino: Vector3 = plano["mira"]

	# #395/#856: los planos que necesitan contar una acción pueden declarar de
	# dónde vienen. La interpolación suave evita el arranque/parada mecánicos de
	# un lerp lineal. Con reducción de movimiento se usa la composición FINAL,
	# quieta: conserva sujeto, información y duración sin hacer travelling.
	if plano.has("camara_desde") or plano.has("mira_desde"):
		if _reduccion_movimiento:
			_camara.global_position = destino
			_camara.look_at(mira_destino, Vector3.UP)
			return
		var origen: Vector3 = plano.get("camara_desde", destino)
		var mira_origen: Vector3 = plano.get("mira_desde", mira_destino)
		var suave := avance * avance * (3.0 - 2.0 * avance)
		_camara.global_position = origen.lerp(destino, suave)
		_camara.look_at(mira_origen.lerp(mira_destino, suave), Vector3.UP)
		_camara.global_position += LenguajeCine.mano(_reloj, _reduccion_movimiento)
		return

	# Compatibilidad: los planos existentes sin trayectoria conservan el
	# acercamiento corto que llevan usando desde el reproductor original.
	# Con reducción de movimiento se conserva el plano y su duración, pero la
	# cámara queda fija en la posición declarada.
	var factor_movimiento := 0.0 if _reduccion_movimiento else avance
	var acercamiento: Vector3 = destino.normalized() * -0.25 * factor_movimiento
	_camara.global_position = destino + acercamiento
	_camara.look_at(mira_destino, Vector3.UP)
	# La mano va después de encuadrar: mueve la cámara unos milímetros sin
	# cambiar a dónde mira, como un operador que respira.
	_camara.global_position += LenguajeCine.mano(_reloj, _reduccion_movimiento)


## Focal y foco del plano: la óptica de cine, o la que el plano declare.
func _ajustar_optica(plano: Dictionary) -> void:
	_camara.fov = LenguajeCine.fov_de(plano)
	var camara: Vector3 = plano.get("camara", Vector3.ZERO)
	var mira: Vector3 = plano.get("mira", Vector3.FORWARD)
	_camara.attributes = LenguajeCine.atributos(LenguajeCine.foco_de(plano, camara, mira))


## Franjas del formato panorámico y, con ellas, dónde van los textos: el rótulo
## justo encima de la imagen recortada y la voz dentro de la franja, como un
## subtítulo de cine.
func _actualizar_franjas() -> void:
	var alto := LenguajeCine.alto_franja(_lienzo.size)
	var apertura := 0.0
	if _reproduciendo:
		apertura = LenguajeCine.apertura_franjas(_reloj, _total - _reloj, _reduccion_movimiento)
	var visible_alto := alto * apertura
	_franja_superior.size = Vector2(_lienzo.size.x, visible_alto)
	_franja_superior.position = Vector2.ZERO
	_franja_inferior.size = Vector2(_lienzo.size.x, visible_alto)
	_franja_inferior.position = Vector2(0.0, _lienzo.size.y - visible_alto)
	var hueco := maxf(alto, 60.0)
	_rotulo.offset_bottom = -hueco - 16.0
	_rotulo.offset_top = _rotulo.offset_bottom - 110.0
	_voz.offset_bottom = -hueco * 0.5 + 16.0
	_voz.offset_top = _voz.offset_bottom - 40.0


## Fundido opt-in para transiciones donde la acción es perder continuidad visual,
## no mover más la cámara. Usa la misma curva suave que los travellings y se
## reinicia en cada plano, así no contamina escenas que no declaran fundido.
func _actualizar_fundido(plano: Dictionary, avance: float) -> void:
	if _fundido == null:
		return
	var desde := clampf(float(plano.get("fundido_desde", 0.0)), 0.0, 1.0)
	var hasta := clampf(float(plano.get("fundido_hasta", desde)), 0.0, 1.0)
	var suave := avance * avance * (3.0 - 2.0 * avance)
	_fundido.color = Color(0.0, 0.0, 0.0, lerpf(desde, hasta, suave))


## Los planos 2D se dibujan aquí: la figura es una lista de rectángulos con
## color, y `desde`/`hasta` la desplazan. El reproductor no sabe si está
## pintando un sello o una carta.
func _dibujar_figuras() -> void:
	if not _reproduciendo or _plano < 0 or _plano >= _rodaje.size():
		return
	var plano: Dictionary = _rodaje[_plano]
	if plano["tipo"] != "2d":
		return

	var duracion: float = plano["segundos"]
	var avance: float = clampf(_transcurrido / duracion, 0.0, 1.0)
	var desde: Vector2 = plano.get("desde", Vector2.ZERO)
	var hasta: Vector2 = plano.get("hasta", desde)
	# La alternativa accesible no elimina la escena: presenta inmediatamente la
	# figura en su pose final y conserva rótulo, voz, duración y skip.
	var factor_movimiento := 1.0 if _reduccion_movimiento else avance
	var deriva: Vector2 = desde.lerp(hasta, factor_movimiento)
	var centro := _lienzo.size / 2.0

	for pieza in plano["figura"]:
		var rect: Rect2 = pieza["rect"]
		_figuras.draw_rect(
			Rect2(centro + rect.position + deriva, rect.size), pieza.get("color", EstiloSiga.BLANCO)
		)


## Monta (o reutiliza) el decorado de un plano en el plató. El decorado es un
## espacio en el formato de `Espacio3D` —bultos, luces, suelo—: el reproductor
## no sabe qué hay en la mesa, igual que no sabe qué es un sello en 2D. Planos
## seguidos con el mismo decorado no lo reconstruyen.
func _preparar_plato(decorado: Dictionary) -> void:
	if decorado.is_empty():
		_plato.visible = false
		if _camara.get_parent() != self:
			_camara.reparent(self, false)
		return
	var huella := hash(decorado)
	if _decorado == null or huella != _huella_decorado:
		if _decorado != null:
			_decorado.free()
		_decorado = Node3D.new()
		_vista_plato.add_child(_decorado)
		Espacio3D.construir(_decorado, decorado)
		_huella_decorado = huella
	if _camara.get_parent() != _vista_plato:
		_camara.reparent(_vista_plato, false)
	_plato.visible = true


# --- Cajas ------------------------------------------------------------------


func _montar() -> void:
	_camara = Camera3D.new()
	add_child(_camara)

	var capa := CanvasLayer.new()
	add_child(capa)

	_plato = SubViewportContainer.new()
	_plato.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_plato.stretch = true
	_plato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plato.visible = false
	capa.add_child(_plato)
	_vista_plato = SubViewport.new()
	_vista_plato.own_world_3d = true
	_plato.add_child(_vista_plato)
	var entorno := WorldEnvironment.new()
	entorno.environment = Environment.new()
	entorno.environment.background_mode = Environment.BG_COLOR
	entorno.environment.background_color = Color(0.05, 0.05, 0.06)
	entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.environment.ambient_light_color = Color(0.55, 0.55, 0.58)
	entorno.environment.ambient_light_energy = 0.55
	_vista_plato.add_child(entorno)
	# El plató es otro mundo 3D: sin esto, una cinemática con decorado se vería
	# sin el filtro que el resto del juego sí lleva (#1270).
	FiltroPantalla.aplicar(entorno, PreferenciasSiga.cargar())

	_lienzo = Control.new()
	_lienzo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lienzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_lienzo)

	_fondo = ColorRect.new()
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.color = Color(0.10, 0.10, 0.11)
	_fondo.visible = false
	_lienzo.add_child(_fondo)

	_figuras = Node2D.new()
	_figuras.draw.connect(_dibujar_figuras)
	_figuras.visible = false
	_lienzo.add_child(_figuras)

	_fundido = ColorRect.new()
	_fundido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundido.color = Color(0.0, 0.0, 0.0, 0.0)
	_lienzo.add_child(_fundido)

	# Grano y viñeta encima de la imagen y debajo de franjas y textos.
	_grano = ColorRect.new()
	_grano.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grano.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://arte/grano_cine.gdshader")
	material.set_shader_parameter("grano", LenguajeCine.GRANO)
	material.set_shader_parameter("vineta", LenguajeCine.VINETA)
	_grano.material = material
	_grano.visible = false
	_lienzo.add_child(_grano)

	_franja_superior = _franja()
	_franja_inferior = _franja()

	_rotulo = _texto(48)
	_rotulo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_rotulo.offset_top = -230
	_rotulo.offset_left = 60
	_rotulo.offset_right = -60
	_rotulo.offset_bottom = -120
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lienzo.add_child(_rotulo)

	_voz = _texto(18)
	_voz.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_voz.offset_top = -60
	_voz.offset_left = 16
	_voz.offset_right = -16
	_voz.offset_bottom = -20
	_voz.add_theme_color_override("font_color", Color(0.85, 0.82, 0.55))
	_voz.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lienzo.add_child(_voz)


func _franja() -> ColorRect:
	var franja := ColorRect.new()
	franja.color = Color.BLACK
	franja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	franja.size = Vector2.ZERO
	_lienzo.add_child(franja)
	return franja


func _texto(tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.theme = EstiloSiga.tema()
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	etiqueta.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	etiqueta.add_theme_constant_override("outline_size", 5)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return etiqueta
