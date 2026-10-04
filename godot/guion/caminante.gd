## El cuerpo que anda. Primera persona, con paso normal, carrera, agachado y
## salto (petición de playtest tras #562): siguen siendo gestos utilitarios
## para sortear la geometría del sitio, no un modo de movimiento propio.
extends CharacterBody3D

enum DispositivoEntrada {
	TECLADO_RATON,
	MANDO,
}

const VELOCIDAD := 2.6
const VELOCIDAD_CORRER := 4.4
const VELOCIDAD_AGACHADO := 1.4
const ACELERACION := 10.0
const FRENADO := 14.0
const SENSIBILIDAD_RATON_BASE := 0.0022
## Sensibilidad del giro por arrastre táctil, en radianes por píxel. No reutiliza
## la del ratón a propósito: el dedo recorre muchos más píxeles por gesto, así
## que el valor queda explícito y acotado para que un barrido no pegue un volantazo.
const SENSIBILIDAD_TACTIL_BASE := 0.0018
## La zona izquierda reclama un dedo para desplazamiento; el resto queda libre
## para mirar con el arrastre táctil ya integrado. El radio convierte píxeles
## de desplazamiento en un vector analógico acotado.
const ZONA_MOVIMIENTO_TACTIL := 0.45
const RADIO_MOVIMIENTO_TACTIL := 96.0
const VOLUMEN_PISADA_DB := -8.0
const GRUPO_CAMARA := "caminante_camara"
const AccionesTactiles98Overlay = preload("res://guion/acciones_tactiles_98.gd")

const MOVER_IZQUIERDA := "mover_izquierda"
const MOVER_DERECHA := "mover_derecha"
const MOVER_ADELANTE := "mover_adelante"
const MOVER_ATRAS := "mover_atras"
const SALTAR := "saltar"
const CORRER := "correr"
const AGACHARSE := "agacharse"

## Altura de la cápsula y de la cámara en pie frente a agachado. La cápsula
## vive en `escenas/caminante.tscn`; aquí solo se redimensiona en caliente.
const ALTURA_NORMAL := 1.7
const ALTURA_AGACHADO := 1.05
const CAMARA_Y_NORMAL := 0.65
const CAMARA_Y_AGACHADO := 0.30
const IMPULSO_SALTO := 4.6

## El stick derecho mira. Va en radianes POR SEGUNDO y no por fotograma, que es
## lo que hace que mirar cueste lo mismo en una máquina lenta que en una rápida.
const SENSIBILIDAD_MANDO_BASE := 2.4

## El stick descansa cerca del centro, no en el centro: sin esto la cámara
## deriva sola con un mando gastado. El mapa de acciones ya trae su zona muerta;
## esta segunda guarda suaviza el borde del vector combinado.
const ZONA_MUERTA := 0.12

## Cambiar el tipo de prompt exige un gesto inequívoco. Un stick gastado puede
## oscilar dentro de la zona de reposo y no debe hacer parpadear teclado ↔ mando.
const UMBRAL_CAMBIO_DISPOSITIVO := 0.35

## Cuánto se puede mirar arriba y abajo. Sin tope, la cámara se da la vuelta.
const TOPE_VERTICAL := deg_to_rad(85.0)

## El encuadre de conversación usa una cámara hermana: no gira el cuerpo ni
## cambia la dirección de movimiento del jugador. #276
const DURACION_ENFOQUE_DIALOGO := 0.22
const ALTURA_ENFOQUE_DIALOGO := 0.35

var _detector_interaccion: DetectorInteraccion3D
var _prompt_interaccion: Label
var _hud_prioridades: HUDLayer
var _objetivo_foco: Interactuable3D
var _preferencias_camara: Dictionary = {}
var _ultimo_dispositivo := DispositivoEntrada.TECLADO_RATON
var _texto_interaccion_actual := ""
var _agachado := false
var _camara_dialogo: Camera3D
var _objetivo_dialogo: Node3D
var _tween_camara_dialogo: Tween
var _dedo_movimiento_tactil := -1
var _origen_movimiento_tactil := Vector2.ZERO
var _movimiento_tactil := Vector2.ZERO
var _acciones_tactiles: AccionesTactiles98

@onready var _camara: Camera3D = $Camara
@onready var _colision: CollisionShape3D = $Colision


func _ready() -> void:
	add_to_group(GRUPO_CAMARA)
	recargar_preferencias_camara()
	_asegurar_controles_movimiento()
	_montar_interaccion()
	_montar_acciones_tactiles()
	# `Dia` añade el reproductor 3D de pasos justo después de meter el caminante
	# en el árbol. Diferir un turno permite atenuarlo aquí, junto al cuerpo que
	# los produce, sin crear un bus global que también bajaría puertas o voces.
	call_deferred("_ajustar_volumen_pisadas")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _montar_acciones_tactiles() -> void:
	_acciones_tactiles = AccionesTactiles98Overlay.new()
	_acciones_tactiles.name = "AccionesTactiles98"
	add_child(_acciones_tactiles)


func acciones_tactiles_disponibles() -> bool:
	return AccionesTactiles98.debe_mostrarse(
		is_physics_processing(),
		get_tree().paused,
		is_instance_valid(_camara_dialogo),
		Input.mouse_mode == Input.MOUSE_MODE_CAPTURED,
	)


func recargar_preferencias_camara() -> void:
	_preferencias_camara = PreferenciasSiga.cargar()


## Centra temporalmente la vista en el interlocutor sin apropiarse del movimiento.
## La cámara normal queda intacta debajo: al terminar no hay que reconstruir yaw
## ni pitch y el jugador recupera exactamente el encuadre que tenía al hablar.
func enfocar_conversacion(objetivo: Node3D) -> void:
	terminar_enfoque_conversacion()
	if not is_instance_valid(objetivo) or not is_instance_valid(_camara):
		return
	var padre := _camara.get_parent() as Node3D
	if padre == null:
		return

	var camara := Camera3D.new()
	camara.name = "CamaraConversacion"
	camara.fov = _camara.fov
	camara.near = _camara.near
	camara.far = _camara.far
	camara.keep_aspect = _camara.keep_aspect
	camara.cull_mask = _camara.cull_mask
	padre.add_child(camara)
	camara.transform = _camara.transform

	_camara.current = false
	camara.current = true
	_camara_dialogo = camara
	_objetivo_dialogo = objetivo

	var origen := camara.rotation
	camara.look_at(_punto_enfoque_dialogo(), Vector3.UP)
	var destino := camara.rotation
	camara.rotation = origen

	# Reducción de movimiento conserva la atribución visual pero elimina el giro
	# animado de cámara. No se crea un tween de duración artificialmente corta.
	if bool(_preferencias_camara.get("reduccion_movimiento", false)):
		camara.rotation = destino
		return

	_tween_camara_dialogo = create_tween()
	_tween_camara_dialogo.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween_camara_dialogo.tween_property(camara, "rotation", destino, DURACION_ENFOQUE_DIALOGO)


func terminar_enfoque_conversacion() -> void:
	if _tween_camara_dialogo != null:
		_tween_camara_dialogo.kill()
	_tween_camara_dialogo = null
	_objetivo_dialogo = null
	if is_instance_valid(_camara_dialogo):
		_camara.current = true
		_camara_dialogo.queue_free()
	_camara_dialogo = null


func _punto_enfoque_dialogo() -> Vector3:
	if not is_instance_valid(_objetivo_dialogo):
		return global_position - global_transform.basis.z
	return _objetivo_dialogo.global_position + Vector3.UP * ALTURA_ENFOQUE_DIALOGO


func _actualizar_enfoque_conversacion() -> void:
	if not is_instance_valid(_camara_dialogo):
		return
	if not is_instance_valid(_objetivo_dialogo):
		terminar_enfoque_conversacion()
		return
	if _tween_camara_dialogo != null and _tween_camara_dialogo.is_running():
		return
	# Si el jugador camina durante la línea, la cámara acompaña su posición y
	# mantiene al emisor centrado. El movimiento físico nunca se desactiva.
	_camara_dialogo.look_at(_punto_enfoque_dialogo(), Vector3.UP)


func _montar_interaccion() -> void:
	_detector_interaccion = DetectorInteraccion3D.new()
	_detector_interaccion.name = "DetectorInteraccion3D"
	_camara.add_child(_detector_interaccion)
	_detector_interaccion.objetivo_cambiado.connect(_mostrar_prompt_interaccion)
	_detector_interaccion.objetivo_perdido.connect(_ocultar_prompt_interaccion)

	_prompt_interaccion = Label.new()
	_prompt_interaccion.name = "PromptInteraccion"
	_prompt_interaccion.theme = EstiloSiga.tema()
	_prompt_interaccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_interaccion.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_interaccion.offset_left = -260
	_prompt_interaccion.offset_top = -74
	_prompt_interaccion.offset_right = 260
	_prompt_interaccion.offset_bottom = -30
	_prompt_interaccion.visible = false


## El prompt deja de vivir en su propio CanvasLayer: el día lo registra en el
## árbitro común para que diálogo, tutorial y modales puedan quitarle prioridad.
func conectar_hud(hud: HUDLayer) -> void:
	_hud_prioridades = hud
	if _prompt_interaccion.get_parent() == null:
		hud.add_child(_prompt_interaccion)
	hud.registrar(HUDLayer.INTERACCION, _prompt_interaccion)
	if not _prompt_interaccion.text.is_empty():
		hud.activar(HUDLayer.INTERACCION)


func _mostrar_prompt_interaccion(objetivo: Interactuable3D, texto: String) -> void:
	_marcar_objetivo(_objetivo_foco, false)
	_objetivo_foco = objetivo
	_marcar_objetivo(_objetivo_foco, true)
	_texto_interaccion_actual = texto
	_refrescar_prompt_interaccion()
	if _hud_prioridades != null:
		if texto.is_empty():
			_hud_prioridades.desactivar(HUDLayer.INTERACCION)
		else:
			_hud_prioridades.activar(HUDLayer.INTERACCION)
	else:
		_prompt_interaccion.visible = not texto.is_empty()


func _ocultar_prompt_interaccion() -> void:
	_marcar_objetivo(_objetivo_foco, false)
	_objetivo_foco = null
	_texto_interaccion_actual = ""
	_prompt_interaccion.text = ""
	if _hud_prioridades != null:
		_hud_prioridades.desactivar(HUDLayer.INTERACCION)
	else:
		_prompt_interaccion.visible = false


func _marcar_objetivo(objetivo: Interactuable3D, en_foco: bool) -> void:
	if objetivo is CompaneroInteractivo3D:
		objetivo.marcar_en_foco(en_foco)


func _refrescar_prompt_interaccion() -> void:
	if not is_instance_valid(_prompt_interaccion):
		return
	_prompt_interaccion.text = _texto_con_entrada("interactuar", _texto_interaccion_actual)


## El prompt enseña una sola entrada: la del último dispositivo usado. `InputMap`
## sigue siendo la fuente de verdad, así que un remapeo se refleja sin hardcodear
## una tecla física y cambiar de teclado/ratón a mando refresca el texto en vivo.
func _texto_con_entrada(accion: StringName, texto: String) -> String:
	if texto.is_empty():
		return ""
	for evento in InputMap.action_get_events(accion):
		if not _evento_pertenece_a_dispositivo(evento):
			continue
		var nombre := _nombre_entrada(evento)
		if not nombre.is_empty():
			return "[%s]  %s" % [nombre, texto]
	return texto


func _evento_pertenece_a_dispositivo(evento: InputEvent) -> bool:
	if _ultimo_dispositivo == DispositivoEntrada.MANDO:
		return evento is InputEventJoypadButton or evento is InputEventJoypadMotion
	return evento is InputEventKey or evento is InputEventMouseButton


func _nombre_entrada(evento: InputEvent) -> String:
	if evento is InputEventJoypadButton:
		return PreferenciasSiga.nombre_boton_mando(
			evento.button_index, PreferenciasSiga.familia_mando(evento.device)
		)
	if evento is InputEventKey:
		var codigo: Key = (
			evento.physical_keycode if evento.physical_keycode != 0 else evento.keycode
		)
		return OS.get_keycode_string(codigo)
	return evento.as_text().strip_edges()


func _registrar_dispositivo_entrada(evento: InputEvent) -> void:
	if evento is InputEventJoypadButton:
		if evento.pressed:
			_usar_dispositivo_entrada(DispositivoEntrada.MANDO)
	elif evento is InputEventJoypadMotion:
		if absf(evento.axis_value) >= UMBRAL_CAMBIO_DISPOSITIVO:
			_usar_dispositivo_entrada(DispositivoEntrada.MANDO)
	elif (
		evento is InputEventKey
		or evento is InputEventMouseButton
		or evento is InputEventMouseMotion
	):
		_usar_dispositivo_entrada(DispositivoEntrada.TECLADO_RATON)


func _usar_dispositivo_entrada(dispositivo: int) -> void:
	if dispositivo == _ultimo_dispositivo:
		return
	_ultimo_dispositivo = dispositivo
	if not _texto_interaccion_actual.is_empty():
		_refrescar_prompt_interaccion()


## Declara un esquema de movimiento propio en vez de depender de las acciones
## UI de Godot. Solo instala los valores por defecto cuando la acción no existe:
## una pantalla de remapeo (#113) puede declararla antes y este código no le
## vuelve a añadir teclas a espaldas del jugador.
func _asegurar_controles_movimiento() -> void:
	_asegurar_accion(MOVER_IZQUIERDA, KEY_A, KEY_LEFT)
	_asegurar_accion(MOVER_DERECHA, KEY_D, KEY_RIGHT)
	_asegurar_accion(MOVER_ADELANTE, KEY_W, KEY_UP)
	_asegurar_accion(MOVER_ATRAS, KEY_S, KEY_DOWN)
	_asegurar_accion_simple(SALTAR, KEY_SPACE)
	_asegurar_accion_simple(CORRER, KEY_SHIFT)
	_asegurar_accion_simple(AGACHARSE, KEY_CTRL)


func _asegurar_accion(accion: StringName, tecla_fisica: Key, flecha: Key) -> void:
	if InputMap.has_action(accion):
		return
	InputMap.add_action(accion)

	var wasd := InputEventKey.new()
	wasd.physical_keycode = tecla_fisica
	InputMap.action_add_event(accion, wasd)

	var cursor := InputEventKey.new()
	cursor.keycode = flecha
	InputMap.action_add_event(accion, cursor)


func _asegurar_accion_simple(accion: StringName, tecla_fisica: Key) -> void:
	if InputMap.has_action(accion):
		return
	InputMap.add_action(accion)
	var evento := InputEventKey.new()
	evento.physical_keycode = tecla_fisica
	InputMap.action_add_event(accion, evento)


func _ajustar_volumen_pisadas() -> void:
	for hijo in get_children():
		if hijo is AudioStreamPlayer3D:
			hijo.volume_db = VOLUMEN_PISADA_DB
			return


## Solo un clic deliberado recupera la captura del mundo 3D. La rueda también
## es `InputEventMouseButton`, pero nunca debe esconder el cursor al hacer scroll
## en SIGA-98. Y si una pantalla ha desactivado la física del caminante, el mundo
## tampoco puede reclamar el ratón aunque reciba un evento no gestionado.
static func debe_recapturar_raton(
	evento: InputEvent, fisica_activa: bool, arbol_pausado: bool
) -> bool:
	if not fisica_activa or arbol_pausado or not evento is InputEventMouseButton:
		return false
	var raton := evento as InputEventMouseButton
	return (
		raton.pressed
		and (
			raton.button_index
			in [
				MOUSE_BUTTON_LEFT,
				MOUSE_BUTTON_RIGHT,
				MOUSE_BUTTON_MIDDLE,
			]
		)
	)


## El giro de ratón entra por `_input`, antes del filtrado de GUI. Un `Control`
## a pantalla completa puede consumir MouseMotion y hacer que `_unhandled_input`
## nunca lo vea; eso deja el cursor capturado pero la cámara inmóvil.
func _input(evento: InputEvent) -> void:
	if not evento is InputEventMouseMotion:
		return
	_registrar_dispositivo_entrada(evento)
	if not debe_procesar_movimiento_raton(
		Input.mouse_mode == Input.MOUSE_MODE_CAPTURED,
		is_physics_processing(),
		get_tree().paused,
		is_instance_valid(_camara_dialogo),
	):
		return
	_aplicar_movimiento_raton(evento)


static func debe_procesar_movimiento_raton(
	capturado: bool, fisica_activa: bool, arbol_pausado: bool, dialogo_activo: bool
) -> bool:
	return capturado and fisica_activa and not arbol_pausado and not dialogo_activo


func _aplicar_movimiento_raton(evento: InputEventMouseMotion) -> void:
	var sensibilidad := SENSIBILIDAD_RATON_BASE * _sensibilidad_raton()
	rotate_y(-evento.relative.x * sensibilidad)
	_camara.rotation.x = clampf(
		_camara.rotation.x - evento.relative.y * sensibilidad * _sentido_vertical(),
		-TOPE_VERTICAL,
		TOPE_VERTICAL
	)


## El movimiento táctil usa la zona izquierda y no necesita capturar puntero.
## Se evalúa en _unhandled_input para que cualquier Control tenga prioridad.
static func debe_procesar_movimiento_tactil(fisica_activa: bool, arbol_pausado: bool) -> bool:
	return fisica_activa and not arbol_pausado


static func es_zona_movimiento_tactil(posicion: Vector2, tamano: Vector2) -> bool:
	if tamano.x <= 0.0 or tamano.y <= 0.0:
		return false
	return (
		posicion.x >= 0.0
		and posicion.y >= 0.0
		and posicion.x <= tamano.x * ZONA_MOVIMIENTO_TACTIL
		and posicion.y <= tamano.y
	)


static func vector_movimiento_tactil(
	origen: Vector2, posicion: Vector2, radio: float = RADIO_MOVIMIENTO_TACTIL
) -> Vector2:
	if radio <= 0.0:
		return Vector2.ZERO
	return ((posicion - origen) / radio).limit_length(1.0)


func _limpiar_movimiento_tactil() -> void:
	_dedo_movimiento_tactil = -1
	_origen_movimiento_tactil = Vector2.ZERO
	_movimiento_tactil = Vector2.ZERO


## El arrastre táctil mira con los mismos guardas de gameplay que el ratón,
## salvo la captura: el tacto no captura puntero. Que una GUI se haya quedado
## el gesto se resuelve escuchando el drag en `_unhandled_input`, no aquí.
static func debe_procesar_arrastre_tactil(
	fisica_activa: bool, arbol_pausado: bool, dialogo_activo: bool
) -> bool:
	return fisica_activa and not arbol_pausado and not dialogo_activo


## Misma inversión Y y mismo tope vertical que el ratón; solo cambia la
## sensibilidad, que es propia del tacto y no lee las preferencias de ratón.
func _aplicar_arrastre_tactil(evento: InputEventScreenDrag) -> void:
	rotate_y(-evento.relative.x * SENSIBILIDAD_TACTIL_BASE)
	_camara.rotation.x = clampf(
		_camara.rotation.x - evento.relative.y * SENSIBILIDAD_TACTIL_BASE * _sentido_vertical(),
		-TOPE_VERTICAL,
		TOPE_VERTICAL
	)


func _unhandled_input(evento: InputEvent) -> void:
	# MouseMotion ya se atendió en `_input`; aquí quedan los eventos que deben
	# respetar que una GUI los haya consumido, especialmente el clic de recaptura.
	if evento is InputEventMouseMotion:
		return
	if evento is InputEventScreenTouch:
		var toque := evento as InputEventScreenTouch
		if not toque.pressed:
			if toque.index == _dedo_movimiento_tactil:
				_limpiar_movimiento_tactil()
			return
		if (
			_dedo_movimiento_tactil < 0
			and debe_procesar_movimiento_tactil(is_physics_processing(), get_tree().paused)
			and es_zona_movimiento_tactil(
				toque.position,
				get_viewport().get_visible_rect().size,
			)
		):
			_dedo_movimiento_tactil = toque.index
			_origen_movimiento_tactil = toque.position
			_movimiento_tactil = Vector2.ZERO
		return
	# Un drag que llega aquí no fue consumido por ninguna GUI. El dedo reclamado
	# por movimiento nunca gira la cámara; un segundo dedo conserva el look de
	# #2079. El tacto tampoco cambia los prompts teclado/ratón ↔ mando.
	if evento is InputEventScreenDrag:
		var arrastre := evento as InputEventScreenDrag
		if arrastre.index == _dedo_movimiento_tactil:
			_movimiento_tactil = vector_movimiento_tactil(
				_origen_movimiento_tactil, arrastre.position
			)
			return
		if debe_procesar_arrastre_tactil(
			is_physics_processing(),
			get_tree().paused,
			is_instance_valid(_camara_dialogo),
		):
			_aplicar_arrastre_tactil(arrastre)
		return
	_registrar_dispositivo_entrada(evento)
	# El menú global es el único dueño de `cancelar`: al abrirlo libera el ratón y
	# al cerrarlo restaura el modo anterior. Si el sistema operativo lo soltó por
	# otro motivo, un clic deliberado dentro del mundo recupera la captura.
	if (
		evento is InputEventMouseButton
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
		and debe_recapturar_raton(evento, is_physics_processing(), get_tree().paused)
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_mirar_con_mando(delta)
	_actualizar_agachado()

	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed(SALTAR) and not _agachado:
		velocity.y = IMPULSO_SALTO

	var entrada := (
		_movimiento_tactil
		if _dedo_movimiento_tactil >= 0
		else Input.get_vector(MOVER_IZQUIERDA, MOVER_DERECHA, MOVER_ADELANTE, MOVER_ATRAS)
	)
	# Ambos caminos entregan un Vector2 de longitud <= 1. No normalizar aquí
	# conserva media inclinación del stick físico y del gesto táctil.
	var direccion := transform.basis * Vector3(entrada.x, 0, entrada.y)
	# Agacharse manda sobre correr: no se puede correr agachado.
	var velocidad_base := VELOCIDAD
	if _agachado:
		velocidad_base = VELOCIDAD_AGACHADO
	elif Input.is_action_pressed(CORRER):
		velocidad_base = VELOCIDAD_CORRER
	var objetivo := direccion * velocidad_base
	var respuesta := ACELERACION if entrada.length_squared() > 0.0001 else FRENADO
	velocity.x = move_toward(velocity.x, objetivo.x, respuesta * delta)
	velocity.z = move_toward(velocity.z, objetivo.z, respuesta * delta)
	move_and_slide()
	_actualizar_enfoque_conversacion()


## Agacharse encoge la cápsula y baja la cámara; levantarse solo ocurre si hay
## sitio por encima, para no atravesar el techo de un hueco bajo.
func _actualizar_agachado() -> void:
	var quiere_agacharse := Input.is_action_pressed(AGACHARSE)
	if quiere_agacharse and not _agachado:
		_agachado = true
		_ajustar_altura(ALTURA_AGACHADO, CAMARA_Y_AGACHADO)
	elif not quiere_agacharse and _agachado and _hay_sitio_para_levantarse():
		_agachado = false
		_ajustar_altura(ALTURA_NORMAL, CAMARA_Y_NORMAL)


func _hay_sitio_para_levantarse() -> bool:
	var diferencia := ALTURA_NORMAL - ALTURA_AGACHADO
	var parametros := PhysicsTestMotionParameters3D.new()
	parametros.from = global_transform
	parametros.motion = Vector3.UP * diferencia
	var resultado := PhysicsTestMotionResult3D.new()
	return not PhysicsServer3D.body_test_motion(get_rid(), parametros, resultado)


func _ajustar_altura(altura: float, camara_y: float) -> void:
	var forma: CapsuleShape3D = _colision.shape
	forma.height = altura
	_camara.position.y = camara_y


## Mirar con el stick derecho, además de con el ratón.
##
## Va en `_physics_process` y no en `_input` porque un stick no manda
## eventos mientras está quieto en una posición: manda su posición, y hay que
## leerla cada paso. El ratón es al revés, y por eso siguen siendo dos caminos.
func _mirar_con_mando(delta: float) -> void:
	if is_instance_valid(_camara_dialogo):
		return
	var mirada := Input.get_vector(
		"mirar_izquierda", "mirar_derecha", "mirar_arriba", "mirar_abajo"
	)
	var magnitud := mirada.length()
	if magnitud <= ZONA_MUERTA:
		return

	if magnitud >= UMBRAL_CAMBIO_DISPOSITIVO:
		_usar_dispositivo_entrada(DispositivoEntrada.MANDO)
	# La salida de la zona muerta es continua: un stick apenas desplazado no
	# pega un salto de velocidad al cruzar el umbral.
	var escala := clampf((magnitud - ZONA_MUERTA) / (1.0 - ZONA_MUERTA), 0.0, 1.0)
	mirada = mirada.normalized() * escala
	var sensibilidad := SENSIBILIDAD_MANDO_BASE * _sensibilidad_mando()
	rotate_y(-mirada.x * sensibilidad * delta)
	_camara.rotation.x = clampf(
		_camara.rotation.x - mirada.y * sensibilidad * delta * _sentido_vertical(),
		-TOPE_VERTICAL,
		TOPE_VERTICAL
	)


func _sensibilidad_raton() -> float:
	return clampf(
		float(_preferencias_camara.get("sensibilidad_camara_raton", 1.0)),
		PreferenciasSiga.SENSIBILIDAD_CAMARA_MIN,
		PreferenciasSiga.SENSIBILIDAD_CAMARA_MAX
	)


func _sensibilidad_mando() -> float:
	return clampf(
		float(_preferencias_camara.get("sensibilidad_camara_mando", 1.0)),
		PreferenciasSiga.SENSIBILIDAD_CAMARA_MIN,
		PreferenciasSiga.SENSIBILIDAD_CAMARA_MAX
	)


func _sentido_vertical() -> float:
	return -1.0 if bool(_preferencias_camara.get("invertir_camara_y", false)) else 1.0


## Deja el cuerpo en un sitio, mirando al frente. Se usa al cambiar de espacio:
## conservar la posición anterior te dejaría dentro de un muro del sitio nuevo.
func situar(donde: Vector3, mirando: float = NAN) -> void:
	position = donde + Vector3(0, 1.0, 0)
	velocity = Vector3.ZERO
	# El rumbo lo declara el sitio. Sin esto se entra siempre mirando a -z, que
	# en la calle era mirar a la pared de al lado mientras el camino se va en
	# la otra dirección.
	if not is_nan(mirando):
		rotation.y = deg_to_rad(mirando)
		_camara.rotation.x = 0.0
