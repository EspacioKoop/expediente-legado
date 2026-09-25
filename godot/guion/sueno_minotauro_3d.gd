## Vertical 3D del sueño del Minotauro (#435/#437).
##
## SuenoMinotauro conserva la topología real y las reglas de seguridad. Esta
## capa únicamente las vuelve visibles: corredores de archivo, anclas de
## Ariadna, un ala que se repliega y una presencia procedural. No sustituye la
## sala nocturna, no crea cámara propia y no decide qué familia sale esa noche.
class_name SuenoMinotauro3D
extends Node3D

const ID_MITO := "minotauro"
const ESCALA_PLANO := 0.34
const NODOS_MARCABLES := [
	SuenoMinotauro.CRUCE_NORTE,
	SuenoMinotauro.CRUCE_SUR,
	SuenoMinotauro.BISAGRA,
	SuenoMinotauro.CENTRO,
]

const COLOR_SUELO := Color(0.18, 0.17, 0.15)
const COLOR_ARCHIVO := Color(0.32, 0.30, 0.25)
const COLOR_PAPEL := Color(0.72, 0.68, 0.54)
const COLOR_ARIADNA := Color(0.72, 0.10, 0.08)
const COLOR_PRESENCIA := Color(0.055, 0.045, 0.04)
const COLOR_BLOQUEO := Color(0.19, 0.06, 0.04, 0.72)

@export var reduccion_movimiento := false

var _estado: Dictionary = {}
var _arquitectura: Node3D
var _ala_replegable: Node3D
var _hilo_ariadna: Node3D
var _presencia: Node3D
var _audio_presencia: AudioStreamPlayer3D
var _luz_archivo: OmniLight3D
var _bloqueo_visual: MeshInstance3D
var _marcas := {}
var _nodo_actual := SuenoMinotauro.ENTRADA


func _ready() -> void:
	preparar()


func preparar() -> void:
	if get_node_or_null("LaberintoMinotauro") != null:
		return
	_estado = SuenoMinotauro.estado_nuevo()
	_arquitectura = Node3D.new()
	_arquitectura.name = "LaberintoMinotauro"
	add_child(_arquitectura)
	_montar_corredores()
	_montar_nodos()
	_montar_hilo_ariadna()
	_montar_ala_replegable()
	_montar_presencia()
	_montar_luz()
	_aplicar_estado_visual(false)


func estado() -> Dictionary:
	return _estado.duplicate(true)


func presentacion_transformacion() -> String:
	return SuenoMinotauro.presentacion_transformacion(_estado, reduccion_movimiento)


## La interacción representa dejar una marca y atravesar deliberadamente ese
## cruce. El grafo real nunca se modifica; solo cambia su lectura aparente.
func marcar_y_cruzar(nodo_aparente: String) -> bool:
	if not NODOS_MARCABLES.has(nodo_aparente):
		return false
	var fase_anterior := int(_estado.get("fase_topologica", 0))
	if not SuenoMinotauro.poner_marca(_estado, nodo_aparente):
		return false
	var nodo_real := SuenoMinotauro.nodo_real(nodo_aparente, fase_anterior)
	if not SuenoMinotauro.cruzar(_estado, nodo_real):
		return false
	_nodo_actual = nodo_real
	SuenoMinotauro.responder_minotauro(_estado, nodo_real)
	var cambio_topologico := fase_anterior != int(_estado.get("fase_topologica", 0))
	_aplicar_estado_visual(cambio_topologico)
	return true


func _usar_ancla(_actor: Node, nodo_aparente: String) -> void:
	marcar_y_cruzar(nodo_aparente)


func _montar_corredores() -> void:
	var plano := SuenoMinotauro.plano()
	var vecinos: Dictionary = plano.get("vecinos", {})
	var dibujados := {}
	for origen_variante in vecinos.keys():
		var origen := String(origen_variante)
		for destino_variante in vecinos.get(origen_variante, []):
			var destino := String(destino_variante)
			var clave := "%s>%s" % [origen, destino]
			var inversa := "%s>%s" % [destino, origen]
			if dibujados.has(clave) or dibujados.has(inversa):
				continue
			dibujados[clave] = true
			_crear_corredor(
				_posicion_local(origen), _posicion_local(destino), origen + "_" + destino
			)


func _crear_corredor(desde: Vector3, hasta: Vector3, nombre: String) -> void:
	var direccion := hasta - desde
	var longitud := direccion.length()
	if longitud <= 0.01:
		return
	var centro := desde.lerp(hasta, 0.5)
	var lateral := Vector3(-direccion.z, 0.0, direccion.x).normalized()
	var suelo := _crear_caja(
		_arquitectura,
		"Suelo_" + nombre,
		Vector3(2.2, 0.12, longitud),
		centro + Vector3(0.0, -0.06, 0.0),
		COLOR_SUELO,
	)
	suelo.look_at(hasta, Vector3.UP)
	for lado in [-1.0, 1.0]:
		var pared := _crear_caja(
			_arquitectura,
			"Archivo_%s_%s" % [nombre, "I" if lado < 0.0 else "D"],
			Vector3(0.22, 1.55, longitud),
			centro + lateral * lado * 1.12 + Vector3(0.0, 0.72, 0.0),
			COLOR_ARCHIVO,
		)
		pared.look_at(hasta + lateral * lado * 1.12, Vector3.UP)


func _montar_nodos() -> void:
	var posiciones: Dictionary = SuenoMinotauro.plano().get("posiciones", {})
	for nodo_variante in posiciones.keys():
		var nodo_id := String(nodo_variante)
		var posicion := _posicion_local(nodo_id)
		_crear_caja(
			_arquitectura,
			"Nodo_" + nodo_id,
			Vector3(2.8, 0.16, 2.8),
			posicion,
			COLOR_PAPEL if NODOS_MARCABLES.has(nodo_id) else COLOR_SUELO,
		)
		if not NODOS_MARCABLES.has(nodo_id):
			continue
		var ancla := Interactuable3D.new()
		ancla.name = "AnclaAriadna_" + nodo_id
		ancla.position = posicion + Vector3(0.0, 0.42, 0.0)
		ancla.verbo = Interactuable3D.Verbo.USAR
		ancla.nombre_objeto = "marca de Ariadna"
		ancla.activado.connect(_usar_ancla.bind(nodo_id))
		_arquitectura.add_child(ancla)

		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(1.4, 1.1, 1.4)
		colision.shape = forma
		ancla.add_child(colision)
		_crear_caja(
			ancla,
			"Placa",
			Vector3(0.62, 0.08, 0.62),
			Vector3.ZERO,
			COLOR_ARIADNA,
		)


func _montar_hilo_ariadna() -> void:
	_hilo_ariadna = Node3D.new()
	_hilo_ariadna.name = "HiloAriadna"
	_arquitectura.add_child(_hilo_ariadna)


func _montar_ala_replegable() -> void:
	_ala_replegable = Node3D.new()
	_ala_replegable.name = "AlaReplegable"
	_ala_replegable.position = _posicion_local(SuenoMinotauro.CENTRO)
	_arquitectura.add_child(_ala_replegable)
	for indice in range(5):
		var x := -2.8 + float(indice) * 1.4
		_crear_caja(
			_ala_replegable,
			"ArchivadorImposible%02d" % indice,
			Vector3(0.92, 2.4 + float(indice % 2) * 0.6, 0.72),
			Vector3(x, 1.1, -1.7),
			COLOR_ARCHIVO,
		)
	var tira := _crear_caja(
		_ala_replegable,
		"PapelContinuo",
		Vector3(6.8, 0.06, 0.22),
		Vector3(0.0, 2.8, -1.25),
		COLOR_PAPEL,
	)
	tira.rotation_degrees.z = 7.0


func _montar_presencia() -> void:
	_presencia = Node3D.new()
	_presencia.name = "PresenciaMinotauro"
	_arquitectura.add_child(_presencia)
	_crear_esfera(_presencia, "Cabeza", 0.72, Vector3.ZERO, COLOR_PRESENCIA)
	_crear_esfera(_presencia, "Morro", 0.43, Vector3(0.0, -0.18, -0.58), COLOR_PRESENCIA)
	_crear_cuerno(_presencia, "CuernoIzquierdo", Vector3(-0.52, 0.55, 0.0), -22.0)
	_crear_cuerno(_presencia, "CuernoDerecho", Vector3(0.52, 0.55, 0.0), 22.0)

	_audio_presencia = AudioStreamPlayer3D.new()
	_audio_presencia.name = "RespiracionMinotauro"
	_audio_presencia.stream = SuenoMinotauroAudio.respiracion()
	_audio_presencia.unit_size = 2.8
	_audio_presencia.max_distance = 18.0
	_presencia.add_child(_audio_presencia)
	_audio_presencia.play()

	_bloqueo_visual = _crear_caja(
		_arquitectura,
		"SombraBloqueo",
		Vector3(1.8, 2.5, 0.18),
		Vector3.ZERO,
		COLOR_BLOQUEO,
	)
	_bloqueo_visual.visible = false


func _montar_luz() -> void:
	_luz_archivo = OmniLight3D.new()
	_luz_archivo.name = "LuzArchivo"
	_luz_archivo.position = Vector3(0.0, 4.2, 0.0)
	_arquitectura.add_child(_luz_archivo)
	_aplicar_luz_presencia(SuenoMinotauro.PRESENCIAS[0])


func _aplicar_luz_presencia(presencia: String) -> void:
	if _luz_archivo == null:
		return
	var energia := 2.4
	var alcance := 11.0
	var color := Color(0.72, 0.64, 0.48)
	if presencia == "respiracion":
		energia = 2.9
		alcance = 12.5
		color = Color(0.74, 0.60, 0.43)
	elif presencia == "cruce":
		energia = 3.5
		alcance = 14.0
		color = Color(0.76, 0.52, 0.36)
	elif presencia == "cerca":
		energia = 4.2
		alcance = 16.0
		color = Color(0.80, 0.42, 0.30)
	_luz_archivo.light_energy = energia
	_luz_archivo.omni_range = alcance
	_luz_archivo.light_color = color


func _aplicar_estado_visual(animar_repliegue: bool) -> void:
	var fase := posmod(
		int(_estado.get("fase_topologica", 0)), SuenoMinotauro.TRANSFORMACIONES.size()
	)
	var posiciones := [
		Vector3.ZERO,
		Vector3(0.0, 1.7, -0.6),
		Vector3(0.0, 2.6, 0.8),
		Vector3(0.0, 3.6, -1.2),
	]
	var rotaciones := [
		Vector3.ZERO,
		Vector3(0.0, 0.0, -18.0),
		Vector3(0.0, 28.0, 0.0),
		Vector3(0.0, 0.0, 90.0),
	]
	var destino_posicion: Vector3 = posiciones[fase]
	var destino_rotacion: Vector3 = rotaciones[fase]
	if reduccion_movimiento or not animar_repliegue:
		_ala_replegable.position = _posicion_local(SuenoMinotauro.CENTRO) + destino_posicion
		_ala_replegable.rotation_degrees = destino_rotacion
	else:
		var tween := create_tween()
		tween.set_parallel(true)
		(
			tween
			. tween_property(
				_ala_replegable,
				"position",
				_posicion_local(SuenoMinotauro.CENTRO) + destino_posicion,
				0.72,
			)
		)
		tween.tween_property(_ala_replegable, "rotation_degrees", destino_rotacion, 0.72)
	_actualizar_marcas()
	_actualizar_presencia()


func _actualizar_marcas() -> void:
	var marcas: Array = _estado.get("marcas", [])
	for indice in range(marcas.size()):
		var lectura := SuenoMinotauro.leer_marca(_estado, indice)
		var real := String(lectura.get("real", ""))
		var marca := _marcas.get(real) as MeshInstance3D
		if marca == null:
			marca = _crear_caja(
				_arquitectura,
				"Hilo_" + real,
				Vector3(0.10, 0.82, 0.10),
				Vector3.ZERO,
				COLOR_ARIADNA,
			)
			_marcas[real] = marca
		var aparente := String(lectura.get("aparece_en", real))
		marca.position = _posicion_local(aparente) + Vector3(0.0, 0.48, 0.0)
	_reconstruir_hilo_ariadna()


## El hilo conserva la topología real aunque las marcas cambien de posición
## aparente. Al atravesar tabiques o separarse de una marca desplazada, revela
## qué parte del espacio se ha replegado sin depender de ensayo ciego.
func _reconstruir_hilo_ariadna() -> void:
	if _hilo_ariadna == null:
		return
	for hijo in _hilo_ariadna.get_children():
		hijo.free()

	var puntos := [
		_posicion_local(SuenoMinotauro.ENTRADA) + Vector3(0.0, 0.16, 0.0),
	]
	var marcas: Array = _estado.get("marcas", [])
	for indice in range(marcas.size()):
		var lectura := SuenoMinotauro.leer_marca(_estado, indice)
		var real := String(lectura.get("real", ""))
		if real.is_empty():
			continue
		var punto_real := _posicion_local(real) + Vector3(0.0, 0.16, 0.0)
		_crear_esfera(
			_hilo_ariadna,
			"NudoReal_" + real,
			0.09,
			punto_real,
			COLOR_ARIADNA,
		)
		puntos.append(punto_real)

	for indice in range(puntos.size() - 1):
		var desde: Vector3 = puntos[indice]
		var hasta: Vector3 = puntos[indice + 1]
		_crear_tramo_hilo(desde, hasta, indice)


func _crear_tramo_hilo(desde: Vector3, hasta: Vector3, indice: int) -> void:
	var longitud := desde.distance_to(hasta)
	if longitud <= 0.01:
		return
	var tramo := _crear_caja(
		_hilo_ariadna,
		"Tramo%02d" % indice,
		Vector3(0.08, 0.04, longitud),
		desde.lerp(hasta, 0.5),
		COLOR_ARIADNA,
	)
	tramo.look_at(_hilo_ariadna.to_global(hasta), Vector3.UP)


func _actualizar_presencia() -> void:
	var presencia := String(_estado.get("presencia", SuenoMinotauro.PRESENCIAS[0]))
	var destino := _posicion_local(SuenoMinotauro.SALIDA) + Vector3(0.0, 2.5, -2.0)
	var escala := 0.62
	if presencia == "respiracion":
		destino = _posicion_local(SuenoMinotauro.BISAGRA) + Vector3(0.0, 2.1, -1.8)
		escala = 0.78
	elif presencia == "cruce":
		destino = _posicion_local(SuenoMinotauro.CRUCE_SUR) + Vector3(0.0, 1.8, 0.0)
		escala = 0.94
	elif presencia == "cerca":
		destino = _posicion_local(SuenoMinotauro.CENTRO) + Vector3(0.0, 1.7, 1.2)
		escala = 1.15
	_presencia.position = destino
	_presencia.scale = Vector3.ONE * escala
	if _audio_presencia != null:
		_audio_presencia.volume_db = SuenoMinotauroAudio.volumen_db(presencia)
		_audio_presencia.pitch_scale = SuenoMinotauroAudio.pitch_scale(presencia)
	_aplicar_luz_presencia(presencia)

	var bloqueo := String(_estado.get("bloqueo", ""))
	_bloqueo_visual.visible = not bloqueo.is_empty()
	if not bloqueo.is_empty():
		_bloqueo_visual.position = _posicion_local(bloqueo) + Vector3(0.0, 1.2, 0.0)


func _posicion_local(nodo: String) -> Vector3:
	return SuenoMinotauro.posicion(nodo) * ESCALA_PLANO


func _crear_caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color, color.a < 0.99)
	padre.add_child(nodo)
	return nodo


func _crear_esfera(
	padre: Node3D,
	nombre: String,
	radio: float,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 2.0
	malla.radial_segments = 10
	malla.rings = 6
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color)
	padre.add_child(nodo)
	return nodo


func _crear_cuerno(padre: Node3D, nombre: String, posicion: Vector3, giro_z: float) -> void:
	var malla := CylinderMesh.new()
	malla.top_radius = 0.05
	malla.bottom_radius = 0.18
	malla.height = 1.0
	malla.radial_segments = 7
	var cuerno := MeshInstance3D.new()
	cuerno.name = nombre
	cuerno.mesh = malla
	cuerno.position = posicion
	cuerno.rotation_degrees.z = giro_z
	cuerno.material_override = _material(Color(0.66, 0.58, 0.42))
	padre.add_child(cuerno)


func _material(color: Color, transparente: bool = false) -> StandardMaterial3D:
	if color == COLOR_ARCHIVO:
		return Mitologias435Materiales.crear("metal_archivo_oxidado", color, transparente)
	if color == COLOR_PAPEL:
		return Mitologias435Materiales.crear("papel_archivo_envejecido", color, transparente)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.76
	if transparente:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
