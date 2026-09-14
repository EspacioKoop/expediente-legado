## El cuerpo que anda. Primera persona, sin correr y sin saltar.
##
## Las dos ausencias son deliberadas: esto no es un juego de movimiento, es el
## rato entre el trabajo y la cama. Ir despacio es parte de lo que se cuenta, y
## un salto convertiría cualquier sitio en un sitio para trepar.
extends CharacterBody3D

const VELOCIDAD := 2.6
const ACELERACION := 10.0
const FRENADO := 14.0
const SENSIBILIDAD_RATON_BASE := 0.0022
const VOLUMEN_PISADA_DB := -8.0
const GRUPO_CAMARA := "caminante_camara"

const MOVER_IZQUIERDA := "mover_izquierda"
const MOVER_DERECHA := "mover_derecha"
const MOVER_ADELANTE := "mover_adelante"
const MOVER_ATRAS := "mover_atras"

## El stick derecho mira. Va en radianes POR SEGUNDO y no por fotograma, que es
## lo que hace que mirar cueste lo mismo en una máquina lenta que en una rápida.
const SENSIBILIDAD_MANDO_BASE := 2.4

## El stick descansa cerca del centro, no en el centro: sin esto la cámara
## deriva sola con un mando gastado. El mapa de acciones ya trae su zona muerta;
## esta segunda guarda suaviza el borde del vector combinado.
const ZONA_MUERTA := 0.12

## Cuánto se puede mirar arriba y abajo. Sin tope, la cámara se da la vuelta.
const TOPE_VERTICAL := deg_to_rad(85.0)

enum DispositivoEntrada {
	TECLADO_RATON,
	MANDO,
}

const NOMBRES_BOTONES_MANDO := {
	JOY_BUTTON_A: "A / Cruz",
	JOY_BUTTON_B: "B / Círculo",
	JOY_BUTTON_X: "X / Cuadrado",
	JOY_BUTTON_Y: "Y / Triángulo",
	JOY_BUTTON_BACK: "Select / Vista",
	JOY_BUTTON_GUIDE: "Guía",
	JOY_BUTTON_START: "Start / Menú",
	JOY_BUTTON_LEFT_STICK: "Stick izquierdo",
	JOY_BUTTON_RIGHT_STICK: "Stick derecho",
	JOY_BUTTON_LEFT_SHOULDER: "LB / L1",
	JOY_BUTTON_RIGHT_SHOULDER: "RB / R1",
	JOY_BUTTON_DPAD_UP: "Cruceta arriba",
	JOY_BUTTON_DPAD_DOWN: "Cruceta abajo",
	JOY_BUTTON_DPAD_LEFT: "Cruceta izquierda",
	JOY_BUTTON_DPAD_RIGHT: "Cruceta derecha",
}

var _detector_interaccion: DetectorInteraccion3D
var _prompt_interaccion: Label
var _hud_prioridades: HUDLayer
var _objetivo_foco: Interactuable3D
var _preferencias_camara: Dictionary = {}
var _ultimo_dispositivo := DispositivoEntrada.TECLADO_RATON
var _texto_interaccion_actual := ""

@onready var _camara: Camera3D = $Camara


func _ready() -> void:
	add_to_group(GRUPO_CAMARA)
	recargar_preferencias_camara()
	_asegurar_controles_movimiento()
	_montar_interaccion()
	# `Dia` añade el reproductor 3D de pasos justo después de meter el caminante
	# en el árbol. Diferir un turno permite atenuarlo aquí, junto al cuerpo que
	# los produce, sin crear un bus global que también bajaría puertas o voces.
	call_deferred("_ajustar_volumen_pisadas")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func recargar_preferencias_camara() -> void:
	_preferencias_camara = PreferenciasSiga.cargar()


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
		return String(
			NOMBRES_BOTONES_MANDO.get(evento.button_index, "Botón %d" % evento.button_index)
		)
	if evento is InputEventKey:
		var codigo := evento.physical_keycode if evento.physical_keycode != 0 else evento.keycode
		return OS.get_keycode_string(codigo)
	return evento.as_text().strip_edges()


func _registrar_dispositivo_entrada(evento: InputEvent) -> void:
	if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
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


func _ajustar_volumen_pisadas() -> void:
	for hijo in get_children():
		if hijo is AudioStreamPlayer3D:
			hijo.volume_db = VOLUMEN_PISADA_DB
			return


func _unhandled_input(evento: InputEvent) -> void:
	_registrar_dispositivo_entrada(evento)
	# El menú global es el único dueño de `cancelar`: al abrirlo libera el ratón y
	# al cerrarlo restaura el modo anterior. Si el sistema operativo lo soltó por
	# otro motivo, un clic dentro del juego recupera la captura sin otra tecla.
	if evento is InputEventMouseButton and evento.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if not evento is InputEventMouseMotion or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var sensibilidad := SENSIBILIDAD_RATON_BASE * _sensibilidad_raton()
	rotate_y(-evento.relative.x * sensibilidad)
	_camara.rotation.x = clampf(
		_camara.rotation.x - evento.relative.y * sensibilidad * _sentido_vertical(),
		-TOPE_VERTICAL,
		TOPE_VERTICAL
	)


func _physics_process(delta: float) -> void:
	_mirar_con_mando(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	var entrada := Input.get_vector(MOVER_IZQUIERDA, MOVER_DERECHA, MOVER_ADELANTE, MOVER_ATRAS)
	# `Input.get_vector` ya limita la diagonal a longitud 1 y conserva cuánto se
	# inclina un stick. No normalizar aquí evita convertir media inclinación en
	# velocidad máxima y conserva diagonales sin acelerarlas.
	var direccion := transform.basis * Vector3(entrada.x, 0, entrada.y)
	var objetivo := direccion * VELOCIDAD
	var respuesta := ACELERACION if entrada.length_squared() > 0.0001 else FRENADO
	velocity.x = move_toward(velocity.x, objetivo.x, respuesta * delta)
	velocity.z = move_toward(velocity.z, objetivo.z, respuesta * delta)
	move_and_slide()


## Mirar con el stick derecho, además de con el ratón.
##
## Va en `_physics_process` y no en `_unhandled_input` porque un stick no manda
## eventos mientras está quieto en una posición: manda su posición, y hay que
## leerla cada paso. El ratón es al revés, y por eso siguen siendo dos caminos.
func _mirar_con_mando(delta: float) -> void:
	var mirada := Input.get_vector(
		"mirar_izquierda", "mirar_derecha", "mirar_arriba", "mirar_abajo"
	)
	var magnitud := mirada.length()
	if magnitud <= ZONA_MUERTA:
		return

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
