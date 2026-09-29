## Presentación runtime genérica de los mutadores nocturnos de #1770.
##
## Consume únicamente `espacio["mutador_nocturno"]`: no decide el mutador, no
## escribe Jornada y no crea física. Toda la capa puede desaparecer sin alterar
## navegación, objetivos o progreso.
class_name SuenoMutadorPresentacion3D
extends Node3D

const NOMBRE := "MutadorNocturno1770"
const COLOR_HUMEDAD := Color(0.12, 0.20, 0.28, 0.56)
const COLOR_APAGON := Color(0.58, 0.62, 0.42)
const COLOR_REPETICION := Color(0.34, 0.25, 0.42)
const ESCALA_CELDA := 1.35

var _id := ""
var _animar := false
var _tiempo := 0.0
var _luces: Array[OmniLight3D] = []
var _sonido_a: AudioStreamPlayer3D
var _sonido_b: AudioStreamPlayer3D
var _proximo_pulso := 1.25
var _eco_pendiente := -1.0


static func montar(mundo: Node3D, espacio: Dictionary) -> SuenoMutadorPresentacion3D:
	if mundo == null:
		return null
	var meta: Variant = espacio.get("mutador_nocturno", {})
	if not meta is Dictionary:
		return null
	var id := String((meta as Dictionary).get("id", ""))
	if not MutadoresSueno.IDS.has(id):
		return null

	var existente := mundo.get_node_or_null(NOMBRE)
	if existente is SuenoMutadorPresentacion3D:
		if String(existente.get_meta("mutador_id", "")) == id:
			return existente as SuenoMutadorPresentacion3D
		existente.queue_free()

	var capa := SuenoMutadorPresentacion3D.new()
	capa.name = NOMBRE
	capa.configurar(meta as Dictionary, espacio)
	mundo.add_child(capa)
	# Node reactiva automáticamente _process al entrar en árbol cuando el script
	# lo implementa; fijar el estado después de add_child mantiene reduce_motion.
	capa.set_process(capa._animar or capa._id == MutadoresSueno.DESFASE)
	return capa


func configurar(meta: Dictionary, espacio: Dictionary) -> void:
	_id = String(meta.get("id", ""))
	_animar = bool(meta.get("animacion", false))
	set_meta("mutador_id", _id)
	set_meta("afecta_navegacion", false)
	set_meta("afecta_objetivo", false)
	set_meta("presentacion", meta.duplicate(true))

	match _id:
		MutadoresSueno.HUMEDAD:
			_montar_humedad(espacio)
		MutadoresSueno.APAGONES:
			_montar_apagones(espacio)
		MutadoresSueno.REPETICION:
			_montar_repeticion(espacio)
		MutadoresSueno.DESFASE:
			_montar_desfase(espacio)



func _process(delta: float) -> void:
	_tiempo += delta
	if _id == MutadoresSueno.APAGONES and _animar:
		var pulso := 0.72 + 0.18 * sin(_tiempo * 3.2)
		for luz in _luces:
			if is_instance_valid(luz):
				luz.light_energy = pulso
	elif _id == MutadoresSueno.DESFASE:
		_actualizar_desfase()


func _montar_humedad(espacio: Dictionary) -> void:
	var centro := _centro(espacio)
	for i in range(3):
		var charco := MeshInstance3D.new()
		charco.name = "Charco%d" % (i + 1)
		var malla := CylinderMesh.new()
		malla.top_radius = 0.40 + float(i) * 0.11
		malla.bottom_radius = malla.top_radius
		malla.height = 0.012
		charco.mesh = malla
		charco.position = centro + Vector3(float(i - 1) * 0.72, 0.018, float(i % 2) * 0.44)
		charco.scale.z = 0.62 + float(i) * 0.08
		charco.material_override = _material(COLOR_HUMEDAD, true, 0.18)
		charco.set_meta("solo_visual", true)
		add_child(charco)


func _montar_apagones(espacio: Dictionary) -> void:
	var centro := _centro(espacio)
	for i in range(2):
		var luz := OmniLight3D.new()
		luz.name = "FuenteLocal%d" % (i + 1)
		luz.position = centro + Vector3(-1.2 + float(i) * 2.4, 1.45, -0.35)
		luz.light_color = COLOR_APAGON
		luz.light_energy = 0.72
		luz.omni_range = 3.4
		luz.shadow_enabled = false
		luz.set_meta("fuente_local", true)
		add_child(luz)
		_luces.append(luz)

		var baliza := MeshInstance3D.new()
		baliza.name = "Baliza%d" % (i + 1)
		var esfera := SphereMesh.new()
		esfera.radius = 0.055
		esfera.height = 0.11
		baliza.mesh = esfera
		baliza.position = luz.position
		baliza.material_override = _material(COLOR_APAGON, false, 0.4)
		baliza.set_meta("ruta_legible", true)
		add_child(baliza)


func _montar_repeticion(espacio: Dictionary) -> void:
	var centro := _centro(espacio)
	for i in range(2):
		var eco := MeshInstance3D.new()
		eco.name = "EcoIdentidad%d" % (i + 1)
		var caja := BoxMesh.new()
		caja.size = Vector3(0.28, 0.62, 0.18)
		eco.mesh = caja
		eco.position = centro + Vector3(-1.15 + float(i) * 2.3, 0.32, 0.75)
		eco.material_override = _material(COLOR_REPETICION, false, 0.85)
		eco.set_meta("identidad_repetida", "eco-secundario-1770")
		eco.set_meta("sin_progreso", true)
		add_child(eco)


func _montar_desfase(espacio: Dictionary) -> void:
	var centro := _centro(espacio)
	var stream := _pulso_sintetico()
	_sonido_a = AudioStreamPlayer3D.new()
	_sonido_a.name = "PulsoOriginal"
	_sonido_a.stream = stream
	_sonido_a.position = centro + Vector3(-0.8, 1.0, 0.0)
	_sonido_a.unit_size = 3.0
	add_child(_sonido_a)

	_sonido_b = AudioStreamPlayer3D.new()
	_sonido_b.name = "PulsoDesfasado"
	_sonido_b.stream = stream
	_sonido_b.position = centro + Vector3(0.8, 1.0, 0.0)
	_sonido_b.unit_size = 3.0
	(
		_sonido_b
		. set_meta(
			"retardo_ambiental",
			float((get_meta("presentacion", {}) as Dictionary).get("retardo_ambiental", 0.40)),
		)
	)
	add_child(_sonido_b)


func _actualizar_desfase() -> void:
	if not is_instance_valid(_sonido_a) or not is_instance_valid(_sonido_b):
		return
	var retardo := float(_sonido_b.get_meta("retardo_ambiental", 0.40))
	if _tiempo >= _proximo_pulso:
		_sonido_a.play()
		_eco_pendiente = _tiempo + retardo
		_proximo_pulso = _tiempo + 3.8
	if _eco_pendiente > 0.0 and _tiempo >= _eco_pendiente:
		_sonido_b.play()
		_eco_pendiente = -1.0


func _centro(espacio: Dictionary) -> Vector3:
	var entrada: Variant = espacio.get("entrada", Vector2i.ZERO)
	var salida: Variant = espacio.get("salida", Vector2i.ZERO)
	if entrada is Vector2i and salida is Vector2i:
		var medio := (Vector2(entrada) + Vector2(salida)) * 0.5
		return Vector3(medio.x * ESCALA_CELDA, 0.0, medio.y * ESCALA_CELDA)
	return Vector3.ZERO


func _material(color: Color, transparente: bool, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if transparente:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _pulso_sintetico() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var datos := PackedByteArray()
	var total := 180
	for i in range(total):
		var envolvente := 1.0 - float(i) / float(total)
		var muestra := int(sin(float(i) * 0.48) * 3800.0 * envolvente)
		datos.append(muestra & 0xFF)
		datos.append((muestra >> 8) & 0xFF)
	stream.data = datos
	return stream
