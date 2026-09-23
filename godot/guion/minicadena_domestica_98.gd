## Radio/minicadena doméstica de 1998 (#670).
##
## El aparato no crea otro reloj, otra música ni una conexión de red. La
## programación se resuelve desde `Jornada` y un catálogo local; la escucha
## deliberada puede usar el contrato común de #442 sin activar semillas por
## limitarse a encender el aparato o dejarlo como ruido de fondo.
class_name MinicadenaDomestica98
extends Node3D

const RUTA_CATALOGO := "res://datos/radio_domestica_98.json"
const FUENTE_RADIO := "radio"
const FUENTE_CASSETTE := "cassette"
const NOMBRE_CONTROLES := "ControlesMinicadena"
const NOMBRE_VISUAL := "VisualMinicadena"
const NOMBRE_AUDIO := "MusicaPuntual"
const BUS_AUDIO := &"Musica"
const VOLUMENES_LOCALES_DB := [-18.0, -12.0, -7.0, -3.0]
const FRECUENCIAS_RADIO_HZ := [132.0, 165.0, 198.0, 231.0]
const FRECUENCIA_CASSETTE_HZ := 96.0
const AUDIO_MIX_RATE := 22050
const AUDIO_FRAMES := 4096
const AUDIO_UNIT_SIZE := 1.5
const AUDIO_MAX_DISTANCE := 7.0
const AUDIO_PANNING_STRENGTH := 0.65

var _catalogo: Dictionary = {}
var _jornada: Dictionary = {}
var _encendida := false
var _fuente := FUENTE_RADIO
var _indice_emisora := 0
var _cassette_insertada := false
var _indice_segmento := 0
var _atencion_clave := ""
var _atencion_pasos := 0
var _indice_volumen := 2
var _reproduciendo := false
var _posicion_pausa := 0.0
var _audio: AudioStreamPlayer3D


func _ready() -> void:
	_sincronizar_audio()


func configurar(jornada: Dictionary = {}) -> void:
	_jornada = jornada
	if _catalogo.is_empty():
		_cargar_catalogo()
	if get_node_or_null(NOMBRE_VISUAL) == null:
		_montar_visual()
	if get_node_or_null(NOMBRE_AUDIO) == null:
		_montar_audio()
	if get_node_or_null(NOMBRE_CONTROLES) == null:
		_montar_controles()
	_sincronizar_audio()


func esta_encendida() -> bool:
	return _encendida


func fuente_actual() -> String:
	return _fuente


func cassette_insertada() -> bool:
	return _cassette_insertada


func esta_reproduciendo() -> bool:
	return _encendida and _reproduciendo


func volumen_local_db() -> float:
	return float(VOLUMENES_LOCALES_DB[_indice_volumen])


func emisoras() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var bruto = _catalogo.get("emisoras", [])
	if typeof(bruto) != TYPE_ARRAY:
		return salida
	for valor in bruto:
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var emisora: Dictionary = valor
		salida.append(emisora.duplicate(true))
	return salida


func emisora_actual() -> Dictionary:
	var lista := emisoras()
	if lista.is_empty():
		return {}
	var indice := posmod(_indice_emisora, lista.size())
	return lista[indice]


func contenido_actual() -> Dictionary:
	if _fuente == FUENTE_CASSETTE:
		return _segmento_cassette_actual()
	return programa_actual()


func programa_actual(jornada: Dictionary = {}) -> Dictionary:
	var contexto := jornada
	if contexto.is_empty():
		contexto = _jornada_actual()
	return seleccionar_programa(emisora_actual(), contexto)


func titulo_actual() -> String:
	if not _encendida:
		return ""
	return String(contenido_actual().get("titulo", ""))


func transcripcion_actual() -> String:
	if not _encendida:
		return ""
	return String(contenido_actual().get("transcripcion", ""))


func alternar_encendido() -> void:
	_encendida = not _encendida
	_reproduciendo = _encendida
	if not _encendida:
		_reiniciar_atencion()
	_sincronizar_audio()


func cambiar_emisora() -> void:
	if not _encendida:
		return
	if _fuente == FUENTE_CASSETTE:
		_avanzar_cassette()
		return
	var lista := emisoras()
	if lista.is_empty():
		return
	_indice_emisora = posmod(_indice_emisora + 1, lista.size())
	_reiniciar_atencion()
	_sincronizar_audio(true)


func alternar_cassette() -> void:
	_cassette_insertada = not _cassette_insertada
	_fuente = FUENTE_CASSETTE if _cassette_insertada else FUENTE_RADIO
	_indice_segmento = 0
	_reiniciar_atencion()
	_sincronizar_audio(true)


func alternar_reproduccion() -> void:
	if not _encendida:
		return
	_reproduciendo = not _reproduciendo
	if not _reproduciendo:
		_reiniciar_atencion()
	_sincronizar_audio()


func cambiar_volumen() -> void:
	_indice_volumen = posmod(_indice_volumen + 1, VOLUMENES_LOCALES_DB.size())
	_sincronizar_audio()


## Representa atención activa, no segundos de reproducción pasiva. Cada pulsación
## completa un pequeño paso del contenido actual; solo al alcanzar el umbral
## declarado se registra la semilla y, en cassette, se avanza al siguiente corte.
func escuchar_actual() -> bool:
	if not _encendida or not _reproduciendo:
		return false
	var contenido := contenido_actual()
	if contenido.is_empty():
		return false
	var clave := "%s:%s" % [_fuente, String(contenido.get("id", ""))]
	if clave != _atencion_clave:
		_atencion_clave = clave
		_atencion_pasos = 0
	_atencion_pasos += 1
	var requerida := maxi(1, int(contenido.get("atencion_requerida", 1)))
	if _atencion_pasos < requerida:
		return false

	_activar_semilla(contenido)
	_activar_exposicion(contenido)
	if _fuente == FUENTE_CASSETTE:
		_avanzar_cassette()
	else:
		_atencion_pasos = requerida
	return true


## Misma escala narrativa que correo/chat: depende de acciones de Jornada y nunca
## consulta la hora del equipo. El corte doméstico solo necesita una referencia
## estable para resolver franjas de programación.
static func hora_narrativa(jornada: Dictionary) -> String:
	var acciones := clampi(
		int(jornada.get("acciones", Jornada.ACCIONES_POR_DIA)), 0, Jornada.ACCIONES_POR_DIA
	)
	var consumidas := Jornada.ACCIONES_POR_DIA - acciones
	var pasos := maxi(1, Jornada.ACCIONES_POR_DIA)
	var minutos := 8 * 60 + 16 + int(round(float(consumidas) * 480.0 / float(pasos)))
	return "%02d:%02d" % [int(minutos / 60), minutos % 60]


static func seleccionar_programa(emisora: Dictionary, jornada: Dictionary) -> Dictionary:
	var programas = emisora.get("programas", [])
	if typeof(programas) != TYPE_ARRAY or programas.is_empty():
		return {}
	var minuto := _minutos(hora_narrativa(jornada))
	var dia := maxi(1, int(jornada.get("dia", 1)))
	for valor in programas:
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var programa: Dictionary = valor
		var dias = programa.get("dias", [])
		if typeof(dias) == TYPE_ARRAY and not dias.is_empty() and not dias.has(dia):
			continue
		var desde := _minutos(String(programa.get("desde", "00:00")))
		var hasta := _minutos(String(programa.get("hasta", "23:59")))
		if minuto >= desde and minuto <= hasta:
			return programa.duplicate(true)
	return {}


## Los metadatos de un programa pueden describir un marco ideológico sin
## convertir la emisora completa en portavoz de una sola posición. Esta función
## es pura respecto a la radio: solo delega el registro en el contrato de #919.
static func registrar_exposicion_de_contenido(
	estado: Dictionary, contenido: Dictionary, jornada: int
) -> bool:
	var exposicion = contenido.get("exposicion_ideologica", {})
	if typeof(exposicion) != TYPE_DICTIONARY or exposicion.is_empty():
		return false
	var etiquetas: Array = []
	var etiquetas_brutas = exposicion.get("etiquetas", [])
	if typeof(etiquetas_brutas) == TYPE_ARRAY:
		etiquetas = (etiquetas_brutas as Array).duplicate()
	return (
		Prometeo
		. registrar_exposicion_ideologica(
			estado,
			String(exposicion.get("id", "")),
			String(exposicion.get("fuente", FUENTE_RADIO)),
			String(exposicion.get("eje", "")),
			jornada,
			etiquetas,
		)
	)


static func _minutos(hora: String) -> int:
	var partes := hora.split(":")
	if partes.size() != 2:
		return 0
	return clampi(int(partes[0]), 0, 23) * 60 + clampi(int(partes[1]), 0, 59)


func _segmento_cassette_actual() -> Dictionary:
	var cassette = _catalogo.get("cassette", {})
	if typeof(cassette) != TYPE_DICTIONARY:
		return {}
	var segmentos = cassette.get("segmentos", [])
	if typeof(segmentos) != TYPE_ARRAY or segmentos.is_empty():
		return {}
	var indice := posmod(_indice_segmento, segmentos.size())
	var valor = segmentos[indice]
	if typeof(valor) != TYPE_DICTIONARY:
		return {}
	var segmento: Dictionary = valor
	return segmento.duplicate(true)


func _avanzar_cassette() -> void:
	var cassette = _catalogo.get("cassette", {})
	if typeof(cassette) != TYPE_DICTIONARY:
		return
	var segmentos = cassette.get("segmentos", [])
	if typeof(segmentos) != TYPE_ARRAY or segmentos.is_empty():
		return
	_indice_segmento = posmod(_indice_segmento + 1, segmentos.size())
	_reiniciar_atencion()
	_sincronizar_audio(true)


func _activar_semilla(contenido: Dictionary) -> bool:
	var semilla = contenido.get("semilla", {})
	if typeof(semilla) != TYPE_DICTIONARY or semilla.is_empty():
		return false
	var jornada := _jornada_actual()
	if jornada.is_empty():
		return false
	return (
		SemillasOniricas
		. activar_semilla_onirica(
			jornada,
			String(semilla.get("id_mito", "")),
			String(semilla.get("fuente", "")),
			int(semilla.get("intensidad", 1)),
		)
	)


func _activar_exposicion(contenido: Dictionary) -> bool:
	var estado := _estado_partida_actual()
	if estado.is_empty():
		return false
	var jornada := maxi(1, int(_jornada_actual().get("dia", 1)))
	return registrar_exposicion_de_contenido(estado, contenido, jornada)


func _estado_partida_actual() -> Dictionary:
	if not is_inside_tree():
		return {}
	var escena := get_tree().current_scene
	if escena == null:
		return {}
	var partida_actual: Variant = escena.get("partida")
	if partida_actual is Partida:
		return (partida_actual as Partida).estado
	return {}


func _jornada_actual() -> Dictionary:
	if not _jornada.is_empty():
		return _jornada
	var nodo: Node = self
	while nodo != null:
		for propiedad in nodo.get_property_list():
			if String(propiedad.get("name", "")) != "jornada":
				continue
			var valor: Variant = nodo.get("jornada")
			if typeof(valor) == TYPE_DICTIONARY:
				return valor
			return {}
		nodo = nodo.get_parent()
	return {}


func _reiniciar_atencion() -> void:
	_atencion_clave = ""
	_atencion_pasos = 0


func _cargar_catalogo() -> void:
	var archivo := FileAccess.open(RUTA_CATALOGO, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo abrir %s" % RUTA_CATALOGO)
		return
	var valor = JSON.parse_string(archivo.get_as_text())
	if typeof(valor) != TYPE_DICTIONARY:
		push_error("Catálogo de radio doméstica inválido")
		return
	_catalogo = valor


func _montar_audio() -> void:
	_audio = AudioStreamPlayer3D.new()
	_audio.name = NOMBRE_AUDIO
	_audio.bus = BUS_AUDIO
	_audio.volume_db = volumen_local_db()
	_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_audio.unit_size = AUDIO_UNIT_SIZE
	_audio.max_distance = AUDIO_MAX_DISTANCE
	_audio.panning_strength = AUDIO_PANNING_STRENGTH
	add_child(_audio)


func _sincronizar_audio(regenerar_stream: bool = false) -> void:
	if _audio == null:
		_audio = get_node_or_null(NOMBRE_AUDIO) as AudioStreamPlayer3D
	if _audio == null:
		return
	_audio.volume_db = volumen_local_db()
	if regenerar_stream or _audio.stream == null:
		if _audio.playing:
			_audio.stop()
		_audio.stream = _crear_textura_audio()
		_posicion_pausa = 0.0
	if not _encendida:
		if _audio.playing:
			_audio.stop()
		_posicion_pausa = 0.0
		return
	if not _audio.is_inside_tree():
		return
	if not _reproduciendo:
		if _audio.playing or _audio.has_stream_playback():
			_posicion_pausa = _audio.get_playback_position()
		_audio.stop()
		return
	if not _audio.playing:
		_audio.play(_posicion_pausa)


## Cama diegética mínima y original: no suplanta voces ni música del contenido.
## La semántica sigue en la transcripción; esta textura solo hace audible que el
## aparato está encendido y diferencia radio/cassette sin introducir assets o red.
func _crear_textura_audio() -> AudioStreamWAV:
	var pista := AudioStreamWAV.new()
	pista.format = AudioStreamWAV.FORMAT_16_BITS
	pista.mix_rate = AUDIO_MIX_RATE
	pista.stereo = false
	pista.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pista.loop_begin = 0
	pista.loop_end = AUDIO_FRAMES

	var datos := PackedByteArray()
	datos.resize(AUDIO_FRAMES * 2)
	var frecuencia := _frecuencia_audio_actual()
	var semilla := _indice_emisora * 37 + (97 if _fuente == FUENTE_CASSETTE else 13)
	for i in range(AUDIO_FRAMES):
		var tiempo := float(i) / float(AUDIO_MIX_RATE)
		var portadora := sin(TAU * frecuencia * tiempo)
		var pulso := sin(TAU * 2.0 * tiempo + float(semilla))
		var ruido := sin(float(i * 31 + semilla * 17) * 12.9898)
		var amplitud := 0.026 if _fuente == FUENTE_CASSETTE else 0.038
		var muestra_float := portadora * amplitud * (0.8 + 0.2 * pulso) + ruido * 0.012
		var muestra := int(clampf(muestra_float, -1.0, 1.0) * 32767.0)
		datos[i * 2] = muestra & 0xFF
		datos[i * 2 + 1] = (muestra >> 8) & 0xFF
	pista.data = datos
	return pista


func _frecuencia_audio_actual() -> float:
	if _fuente == FUENTE_CASSETTE:
		return FRECUENCIA_CASSETTE_HZ
	if FRECUENCIAS_RADIO_HZ.is_empty():
		return 132.0
	return float(FRECUENCIAS_RADIO_HZ[posmod(_indice_emisora, FRECUENCIAS_RADIO_HZ.size())])


func _montar_visual() -> void:
	var visual := Node3D.new()
	visual.name = NOMBRE_VISUAL
	add_child(visual)
	var carcasa := MeshInstance3D.new()
	carcasa.name = "CarcasaMinicadenaOriginal98"
	carcasa.mesh = load("res://assets/modelos/props_originales_98/minicadena_98.obj") as Mesh
	visual.add_child(carcasa)


func _montar_controles() -> void:
	var controles := Node3D.new()
	controles.name = NOMBRE_CONTROLES
	add_child(controles)
	_crear_control(
		controles,
		"Encendido",
		Vector3(-0.27, 0.34, 0.18),
		Vector3(0.13, 0.12, 0.10),
		"minicadena",
		_al_encendido,
	)
	_crear_control(
		controles,
		"Sintonizador",
		Vector3(0.27, 0.34, 0.18),
		Vector3(0.13, 0.12, 0.10),
		"sintonizador",
		_al_sintonizador,
	)
	_crear_control(
		controles,
		"Volumen",
		Vector3(0, 0.34, 0.18),
		Vector3(0.09, 0.09, 0.10),
		"volumen minicadena",
		_al_volumen,
	)
	_crear_control(
		controles,
		"Cassette",
		Vector3(0, 0.10, 0.19),
		Vector3(0.30, 0.10, 0.10),
		"cassette",
		_al_cassette,
	)
	_crear_control(
		controles,
		"ReproducirPausa",
		Vector3(-0.12, 0.29, 0.19),
		Vector3(0.10, 0.09, 0.10),
		"reproducción",
		_al_reproduccion,
	)
	_crear_control(
		controles,
		"Escucha",
		Vector3(0.12, 0.29, 0.19),
		Vector3(0.10, 0.09, 0.10),
		"contenido",
		_al_escucha,
	)


func _crear_control(
	padre: Node3D,
	nombre: String,
	pos: Vector3,
	tam: Vector3,
	objeto: String,
	callback: Callable,
) -> void:
	var control := Interactuable3D.new()
	control.name = nombre
	control.position = pos
	control.verbo = Interactuable3D.Verbo.USAR
	control.nombre_objeto = objeto
	control.sonido = Interactuable3D.SIN_SONIDO
	padre.add_child(control)
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	control.add_child(colision)
	control.activado.connect(callback)


func _al_encendido(_actor: Node) -> void:
	alternar_encendido()


func _al_sintonizador(_actor: Node) -> void:
	cambiar_emisora()


func _al_cassette(_actor: Node) -> void:
	alternar_cassette()


func _al_volumen(_actor: Node) -> void:
	cambiar_volumen()


func _al_reproduccion(_actor: Node) -> void:
	alternar_reproduccion()


func _al_escucha(_actor: Node) -> void:
	escuchar_actual()


func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	Modelos._pintar(malla, color, "plastico_domestico")
	raiz.add_child(malla)


func _cilindro(
	raiz: Node3D,
	pos: Vector3,
	radio: float,
	alto: float,
	color: Color,
	rotacion: Vector3 = Vector3.ZERO,
) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	malla.rotation_degrees = rotacion
	Modelos._pintar(malla, color, "plastico_domestico")
	raiz.add_child(malla)
