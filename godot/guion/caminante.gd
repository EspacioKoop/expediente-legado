## El cuerpo que anda. Primera persona, sin correr y sin saltar.
##
## Las dos ausencias son deliberadas: esto no es un juego de movimiento, es el
## rato entre el trabajo y la cama. Ir despacio es parte de lo que se cuenta, y
## un salto convertiría cualquier sitio en un sitio para trepar.
extends CharacterBody3D

const VELOCIDAD := 2.6
const SENSIBILIDAD := 0.0022
const VOLUMEN_PISADA_DB := -8.0

const MOVER_IZQUIERDA := "mover_izquierda"
const MOVER_DERECHA := "mover_derecha"
const MOVER_ADELANTE := "mover_adelante"
const MOVER_ATRAS := "mover_atras"

## El stick derecho mira. Va en radianes POR SEGUNDO y no por fotograma, que es
## lo que hace que mirar cueste lo mismo en una máquina lenta que en una rápida.
const SENSIBILIDAD_MANDO := 2.4

## El stick descansa cerca del centro, no en el centro: sin esto la cámara
## deriva sola con un mando gastado. El mapa de acciones ya trae su zona muerta;
## esta es la de la suma de los dos ejes.
const ZONA_MUERTA := 0.12

## Cuánto se puede mirar arriba y abajo. Sin tope, la cámara se da la vuelta.
const TOPE_VERTICAL := deg_to_rad(85.0)

@onready var _camara: Camera3D = $Camara
var _detector_interaccion: DetectorInteraccion3D
var _prompt_interaccion: Label


func _ready() -> void:
	_asegurar_controles_movimiento()
	_montar_interaccion()
	# `Dia` añade el reproductor 3D de pasos justo después de meter el caminante
	# en el árbol. Diferir un turno permite atenuarlo aquí, junto al cuerpo que
	# los produce, sin crear un bus global que también bajaría puertas o voces.
	call_deferred("_ajustar_volumen_pisadas")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _montar_interaccion() -> void:
	_detector_interaccion = DetectorInteraccion3D.new()
	_detector_interaccion.name = "DetectorInteraccion3D"
	_camara.add_child(_detector_interaccion)
	_detector_interaccion.objetivo_cambiado.connect(_mostrar_prompt_interaccion)
	_detector_interaccion.objetivo_perdido.connect(_ocultar_prompt_interaccion)

	var capa := CanvasLayer.new()
	capa.layer = 20
	add_child(capa)
	_prompt_interaccion = Label.new()
	_prompt_interaccion.theme = EstiloSiga.tema()
	_prompt_interaccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_interaccion.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_interaccion.offset_left = -220
	_prompt_interaccion.offset_top = -74
	_prompt_interaccion.offset_right = 220
	_prompt_interaccion.offset_bottom = -30
	_prompt_interaccion.visible = false
	capa.add_child(_prompt_interaccion)


func _mostrar_prompt_interaccion(_objetivo: Interactuable3D, texto: String) -> void:
	_prompt_interaccion.text = texto
	_prompt_interaccion.visible = not texto.is_empty()


func _ocultar_prompt_interaccion() -> void:
	_prompt_interaccion.text = ""
	_prompt_interaccion.visible = false


## Declara un esquema de movimiento propio en vez de depender de las acciones
## UI de Godot. Solo instala los valores por defecto cuando la acción no existe:
## una futura pantalla de remapeo (#98) puede declararla antes y este código no
## le volverá a añadir teclas a espaldas del jugador.
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
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-evento.relative.x * SENSIBILIDAD)
		_camara.rotation.x = clampf(
			_camara.rotation.x - evento.relative.y * SENSIBILIDAD, -TOPE_VERTICAL, TOPE_VERTICAL
		)
	# Soltar el ratón: sin esto, una ventana que captura el puntero y no lo
	# devuelve se siente como un programa colgado.
	elif evento.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)


func _physics_process(delta: float) -> void:
	_mirar_con_mando(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	var entrada := Input.get_vector(MOVER_IZQUIERDA, MOVER_DERECHA, MOVER_ADELANTE, MOVER_ATRAS)
	var direccion := (transform.basis * Vector3(entrada.x, 0, entrada.y)).normalized()
	velocity.x = direccion.x * VELOCIDAD
	velocity.z = direccion.z * VELOCIDAD
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
	if mirada.length() < ZONA_MUERTA:
		return

	rotate_y(-mirada.x * SENSIBILIDAD_MANDO * delta)
	_camara.rotation.x = clampf(
		_camara.rotation.x - mirada.y * SENSIBILIDAD_MANDO * delta, -TOPE_VERTICAL, TOPE_VERTICAL
	)


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
