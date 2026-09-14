## El careo: cinemática de entrada y duelo, con público.
##
## Reproduce el plano de rodaje de `CareoCinematica` sobre el acusado, deja que
## se acerque el compañero (`Cunado`) y encima monta el duelo, que es el
## `Combate` de siempre. Ninguna de esas tres piezas sabe de las otras: aquí
## solo se ponen en fila.
##
## Nada de esto cambia el veredicto. Cuando esta escena arranca, la acusación ya
## está firmada — el careo es una escena con una vida en juego, no un examen.
extends Node3D

signal terminado(gano: bool)

## Cada cuánto habla el compañero, como mucho. Sin tope comentaría cada ronda y
## dejaría de tener gracia: un cuñado que no calla nunca es ruido, y uno que
## habla de vez en cuando es un cuñado.
const PAUSA_ENTRE_COMENTARIOS := 2.5

## Con qué nombre se lleva la cuenta de veces vista.
const ID_CINEMATICA := "careo"

var acusado: Dictionary = {}
var folio := ""
var cargas: Dictionary = {}

## La partida, para que la cinemática se acorte sola con las repeticiones. Sin
## ella el careo funciona igual, solo que siempre a duración completa.
var estado: Dictionary = {}

## La semilla de las tiradas de este careo (#147). La pone quien abre la escena
## —derivada de la partida— para que el careo se pueda volver a ver igual. En
## cero se cae al reloj: es el modo de abrir la escena suelta desde el editor o
## desde la herramienta de capturas, donde no hay partida de la que derivar.
var semilla_tiradas := 0

var _reproductor: Node3D
var _en_cinematica := true
var _combate: Dictionary = {}
var _azar := RandomNumberGenerator.new()
var _desde := 0.0

var _voz: Label
var _cronica: Label
var _marcador: Label
var _botones: HBoxContainer
var _figura_cunado: Node3D
var _camara_duelo: Camera3D


func _ready() -> void:
	if semilla_tiradas != 0:
		_azar.seed = semilla_tiradas
	else:
		_azar.randomize()
	if acusado.is_empty():
		acusado = {"nombre": "El acusado", "ataques": []}

	_montar_sala()
	_montar_interfaz()
	_combate = Combate.nuevo("ciclo", acusado, cargas)

	# La cinemática la pone el reproductor común, no esta escena: el ritmo, el
	# rótulo, el salto y el acortado por repetición son suyos.
	_reproductor = load("res://escenas/cinematica.tscn").instantiate()
	_reproductor.mundo = self
	add_child(_reproductor)
	_reproductor.terminada.connect(_empezar_duelo)
	_reproductor.plano_entrado.connect(_al_entrar_plano)
	var vistas := Cinematica.vistas_de(estado, ID_CINEMATICA)
	_reproductor.reproducir(
		CareoCinematica.planos_de(acusado, folio, vistas), ID_CINEMATICA, estado
	)


## El compañero llega en el segundo plano: justo cuando la cosa se está
## poniendo solemne.
func _al_entrar_plano(indice: int, _plano: Dictionary) -> void:
	if indice == 1:
		_figura_cunado.visible = true
		_decir(Cunado.comentario("llegada", _tirada()))


func _empezar_duelo() -> void:
	if not _en_cinematica:
		return
	_en_cinematica = false
	_camara_duelo.current = true
	_camara_duelo.position = Vector3(0.0, 1.6, 2.9)
	_camara_duelo.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	_botones.visible = true
	_figura_cunado.visible = true
	_actualizar_marcador()
	_cronica.text = tr("CAREO_NO_RECONOCE") % acusado["nombre"]


func _al_jugar(tipo: String) -> void:
	if _combate["terminado"]:
		return
	var ronda := Combate.jugar(_combate, tipo, "", _tirada())
	# El sonido cuenta un daño que YA está resuelto. En empate no hay golpe y
	# nunca interviene en la tirada, la vida ni el veredicto.
	if ronda["veredicto"] != "empate":
		Sonido.sonar_stream(self, Sonido.impacto_careo())

	_cronica.text = (
		tr("COMBATE_CRONICA")
		% [
			Combate.etiqueta(ronda["tipo_jugador"]),
			acusado["nombre"],
			Combate.etiqueta(ronda["tipo_rival"]),
			_veredicto(ronda["veredicto"])
		]
	)
	if not ronda["replica"].is_empty():
		_cronica.text += "\n" + tr("CAREO_REPLICA") % ronda["replica"]

	_actualizar_marcador()

	if ronda["terminado"]:
		var gano: bool = ronda["ganador"] == "jugador"
		_decir(Cunado.comentario("victoria" if gano else "derrota", _tirada()))
		_botones.visible = false
		terminado.emit(gano)
	elif Time.get_ticks_msec() / 1000.0 - _desde > PAUSA_ENTRE_COMENTARIOS:
		_decir(Cunado.sobre_ronda(ronda, _tirada()))


func _decir(frase: String) -> void:
	if frase.is_empty():
		return
	_voz.text = tr("VOZ_CUNADO") % frase
	_desde = Time.get_ticks_msec() / 1000.0


func _veredicto(cual: String) -> String:
	match cual:
		"gana_jugador":
			return tr("CAREO_VEREDICTO_JUGADOR")
		"gana_rival":
			return tr("CAREO_VEREDICTO_RIVAL")
		_:
			return tr("VEREDICTO_EMPATE")


func _tirada() -> Callable:
	return func(): return _azar.randf()


func _actualizar_marcador() -> void:
	_marcador.text = (
		tr("CAREO_MARCADOR")
		% [
			"█".repeat(maxi(0, _combate["vida_jugador"])),
			acusado["nombre"],
			"█".repeat(maxi(0, _combate["vida_rival"]))
		]
	)


# --- La sala ----------------------------------------------------------------


func _montar_sala() -> void:
	var entorno := WorldEnvironment.new()
	var ajustes := Environment.new()
	ajustes.background_mode = Environment.BG_COLOR
	ajustes.background_color = Color(0.03, 0.03, 0.04)
	ajustes.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ajustes.ambient_light_color = Color(0.35, 0.35, 0.40)
	ajustes.ambient_light_energy = 0.5
	entorno.environment = ajustes
	add_child(entorno)

	# Un foco desde arriba y nada más: el careo no ocurre en una oficina, ocurre
	# en la idea que el sistema tiene de sí mismo.
	#
	# POR DEBAJO DEL TECHO. La primera versión lo puso a 4,2 m con el techo a
	# 2,9 y la sala salía completamente negra: estaba alumbrando el otro lado.
	var foco := SpotLight3D.new()
	foco.position = Vector3(0, Espacio3D.ALTURA_MURO - 0.25, 0.5)
	foco.rotation_degrees = Vector3(-78, 0, 0)
	foco.light_energy = 9.0
	foco.spot_range = 14.0
	foco.spot_angle = 45.0
	add_child(foco)

	# Y un relleno flojo desde la cámara, o el acusado es una silueta negra
	# desde cualquier ángulo que no sea justo debajo del foco.
	var relleno := OmniLight3D.new()
	relleno.position = Vector3(0, 1.8, 3.4)
	relleno.light_energy = 1.6
	relleno.omni_range = 9.0
	add_child(relleno)

	(
		Espacio3D
		. construir(
			self,
			{
				"suelo": Vector2(12, 12),
				"color_suelo": Color(0.14, 0.14, 0.15),
				"color_muro": Color(0.10, 0.10, 0.12),
				"color_techo": Color(0.06, 0.06, 0.07),
			}
		)
	)

	# El acusado conserva la silueta sin rostro. No es un placeholder: es la
	# abstracción deliberada que comparten el careo y el sueño.
	_figura(self, Vector3(0, 0, 0), Color(0.52, 0.51, 0.48))
	# El cuñado, en cambio, es una persona concreta. Reutiliza la misma malla
	# humana CC0 que los compañeros de oficina (#199) en vez de inventar una
	# segunda representación de personas para las cinemáticas.
	# Apartado de las cuatro posiciones de cámara. En la primera versión estaba
	# en (2.4, 0, 1.9) y la cámara de la órbita cae en (2.8, 1.7, 2.0): el plano
	# se rodaba DENTRO de su cabeza y no se veía más que un bulto negro.
	_figura_cunado = _persona(self, Vector3(-3.2, 0, 3.4), Color(0.44, 0.42, 0.38))
	_figura_cunado.visible = false

	# La cámara del duelo es de esta escena; la de la cinemática es del
	# reproductor. Dos cámaras y no una compartida: así saltar la cinemática no
	# tiene que devolver ninguna cámara a su sitio.
	_camara_duelo = Camera3D.new()
	add_child(_camara_duelo)


## La figura del acusado. La silueta vive en `FiguraSilueta` desde que el sueño
## (#87) empezó a poblar sus salas con los mismos sospechosos.
func _figura(raiz: Node3D, base: Vector3, color: Color) -> Node3D:
	return FiguraSilueta.construir(raiz, base, color)


## Una persona concreta usa la malla común. Si el asset no pudiera cargarse,
## la escena sigue siendo funcional con la silueta anterior en vez de fallar al
## montar el careo.
func _persona(raiz: Node3D, base: Vector3, color: Color) -> Node3D:
	var figura := Node3D.new()
	figura.position = base
	raiz.add_child(figura)
	if not Modelos.persona(figura, "persona", color):
		FiguraSilueta.construir(figura, Vector3.ZERO, color)
	return figura


func _montar_interfaz() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)

	var abajo := VBoxContainer.new()
	abajo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	abajo.offset_top = -150
	abajo.offset_left = 16
	abajo.offset_right = -16
	abajo.offset_bottom = -12
	capa.add_child(abajo)

	_marcador = _texto(18)
	abajo.add_child(_marcador)
	_cronica = _texto(18)
	abajo.add_child(_cronica)
	_voz = _texto(18)
	_voz.add_theme_color_override("font_color", Color(0.85, 0.82, 0.55))
	abajo.add_child(_voz)

	_botones = HBoxContainer.new()
	_botones.visible = false
	for tipo in Combate.TIPOS:
		var boton := Button.new()
		boton.text = Combate.etiqueta(tipo)
		boton.pressed.connect(_al_jugar.bind(tipo))
		_botones.add_child(boton)
	abajo.add_child(_botones)


func _texto(tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.theme = EstiloSiga.tema()
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	etiqueta.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	etiqueta.add_theme_constant_override("outline_size", 5)
	return etiqueta
