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

var _catalogo: Dictionary = {}
var _jornada: Dictionary = {}
var _encendida := false
var _fuente := FUENTE_RADIO
var _indice_emisora := 0
var _cassette_insertada := false
var _indice_segmento := 0
var _atencion_clave := ""
var _atencion_pasos := 0


func configurar(jornada: Dictionary = {}) -> void:
	_jornada = jornada
	if _catalogo.is_empty():
		_cargar_catalogo()
	if get_node_or_null(NOMBRE_VISUAL) == null:
		_montar_visual()
	if get_node_or_null(NOMBRE_CONTROLES) == null:
		_montar_controles()


func esta_encendida() -> bool:
	return _encendida


func fuente_actual() -> String:
	return _fuente


func cassette_insertada() -> bool:
	return _cassette_insertada


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
	if not _encendida:
		_reiniciar_atencion()


func cambiar_emisora() -> void:
	if not _encendida or _fuente != FUENTE_RADIO:
		return
	var lista := emisoras()
	if lista.is_empty():
		return
	_indice_emisora = posmod(_indice_emisora + 1, lista.size())
	_reiniciar_atencion()


func alternar_cassette() -> void:
	_cassette_insertada = not _cassette_insertada
	_fuente = FUENTE_CASSETTE if _cassette_insertada else FUENTE_RADIO
	_indice_segmento = 0
	_reiniciar_atencion()


## Representa atención activa, no segundos de reproducción pasiva. Cada pulsación
## completa un pequeño paso del contenido actual; solo al alcanzar el umbral
## declarado se registra la semilla y, en cassette, se avanza al siguiente corte.
func escuchar_actual() -> bool:
	if not _encendida:
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


func _montar_visual() -> void:
	var visual := Node3D.new()
	visual.name = NOMBRE_VISUAL
	add_child(visual)
	_caja(visual, Vector3(0, 0.20, 0), Vector3(0.78, 0.36, 0.28), Color(0.18, 0.18, 0.17))
	_caja(visual, Vector3(0, 0.23, 0.148), Vector3(0.30, 0.16, 0.018), Color(0.08, 0.08, 0.07))
	_caja(visual, Vector3(0, 0.10, 0.150), Vector3(0.26, 0.055, 0.016), Color(0.26, 0.22, 0.17))
	for x in [-0.25, 0.25]:
		_cilindro(
			visual,
			Vector3(x, 0.21, 0.155),
			0.105,
			0.022,
			Color(0.10, 0.10, 0.09),
			Vector3(90, 0, 0),
		)
	for x in [-0.11, 0.0, 0.11]:
		_cilindro(
			visual,
			Vector3(x, 0.335, 0.158),
			0.025,
			0.025,
			Color(0.38, 0.37, 0.33),
			Vector3(90, 0, 0),
		)


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
		"Cassette",
		Vector3(0, 0.10, 0.19),
		Vector3(0.30, 0.10, 0.10),
		"cassette",
		_al_cassette,
	)
	_crear_control(
		controles,
		"Escucha",
		Vector3(0, 0.29, 0.19),
		Vector3(0.20, 0.09, 0.10),
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
