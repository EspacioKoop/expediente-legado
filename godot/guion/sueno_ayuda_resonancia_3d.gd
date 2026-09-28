class_name SuenoAyudaResonancia3D
extends Node3D

## Feedback local y efímero para una ayuda ya validada (#378).
## Solo crea presentación visual/sonora. No tiene colisión ni escribe estado.

const AyudaCatalogo = preload("res://guion/red/ayuda_catalogo.gd")
const AyudaDatos = preload("res://guion/red/ayuda_datos.gd")

const DURACION_SEGUNDOS := 1.8
const FRECUENCIA := 22_050
const DURACION_AUDIO := 0.72
const COLOR_RESONANCIA := Color(0.48, 0.58, 0.92)
const COLOR_COMPANIA := Color(0.63, 0.72, 0.96, 0.42)
const ENERGIA_LEVE := 0.78
const ENERGIA_MEDIA := 1.08
const RANGO_LEVE := 3.8
const RANGO_MEDIA := 5.0

static var _eco_cache: AudioStreamWAV

var _luz: OmniLight3D
var _silueta: MeshInstance3D
var _audio: AudioStreamPlayer3D
var _tiempo := 0.0
var _energia_base := 0.0
var _silueta_y_base := 0.0


func mostrar(evento: Dictionary, conocimiento: Array = [], ahora_unix: int = -1) -> bool:
	var ahora := ahora_unix
	if ahora < 0:
		ahora = int(Time.get_unix_time_from_system())
	var validacion := AyudaDatos.validar_evento(evento, ahora, conocimiento)
	if not validacion["ok"]:
		return false
	var normalizado: Dictionary = validacion["event"]
	var feedback := AyudaCatalogo.feedback_para(normalizado["payload"], conocimiento)
	if not feedback["ok"]:
		return false

	var datos: Dictionary = normalizado["payload"]
	var feedback_datos: Dictionary = feedback["feedback"]
	var strength := String(datos["strength"])
	set_meta("decorativo", true)
	set_meta("anchor_id", String(datos["anchor_id"]))
	set_meta("help_type", String(datos["help_type"]))
	set_meta("event_id", String(normalizado.get("event_id", "")))
	_montar_visual(String(feedback_datos["visual"]), strength)
	_montar_audio(String(feedback_datos["audio"]))
	_tiempo = 0.0
	set_process(true)
	return true


func _montar_visual(tipo_visual: String, strength: String) -> void:
	if tipo_visual == "silueta_compania":
		_montar_silueta(strength)
		return
	_montar_luz(strength)


func _montar_luz(strength: String) -> void:
	_luz = OmniLight3D.new()
	_luz.name = "PulsoResonancia"
	_luz.light_color = COLOR_RESONANCIA
	_luz.shadow_enabled = false
	_luz.light_energy = ENERGIA_MEDIA if strength == "media" else ENERGIA_LEVE
	_luz.omni_range = RANGO_MEDIA if strength == "media" else RANGO_LEVE
	_energia_base = _luz.light_energy
	add_child(_luz)


func _montar_silueta(strength: String) -> void:
	_silueta = MeshInstance3D.new()
	_silueta.name = "SiluetaCompania"
	var capsula := CapsuleMesh.new()
	capsula.radius = 0.17 if strength == "leve" else 0.20
	capsula.height = 1.15 if strength == "leve" else 1.30
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = COLOR_COMPANIA
	capsula.material = material
	_silueta.mesh = capsula
	_silueta_y_base = capsula.height * 0.5
	_silueta.position = Vector3(0.0, _silueta_y_base, 0.0)
	add_child(_silueta)


func _montar_audio(tipo_audio: String) -> void:
	if tipo_audio != "eco_breve":
		return
	_audio = AudioStreamPlayer3D.new()
	_audio.name = "EcoResonancia"
	_audio.stream = _eco_breve()
	_audio.volume_db = -9.0
	_audio.unit_size = 4.0
	_audio.max_distance = 14.0
	# Godot 4.7 inicia autoplay al entrar en el árbol; evita llamar play()
	# durante SceneTree._init(), cuando el nodo aún puede estar fuera del árbol.
	_audio.autoplay = true
	add_child(_audio)


func _process(delta: float) -> void:
	_tiempo += maxf(delta, 0.0)
	var restante := maxf(0.0, 1.0 - _tiempo / DURACION_SEGUNDOS)
	if _luz != null:
		var pulso := 0.72 + 0.28 * sin(_tiempo * TAU * 2.4)
		_luz.light_energy = _energia_base * restante * pulso
	if _silueta != null:
		_silueta.position.y = _silueta_y_base + sin(_tiempo * TAU * 0.85) * 0.03
		_silueta.transparency = 1.0 - restante
	if _tiempo >= DURACION_SEGUNDOS:
		set_process(false)
		queue_free()


static func _eco_breve() -> AudioStreamWAV:
	if _eco_cache != null:
		return _eco_cache

	var pista := AudioStreamWAV.new()
	pista.format = AudioStreamWAV.FORMAT_16_BITS
	pista.mix_rate = FRECUENCIA
	pista.stereo = false

	var muestras := int(FRECUENCIA * DURACION_AUDIO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var envolvente := exp(-t * 4.8)
		var muestra := sin(TAU * 294.0 * t) * 0.038 * envolvente
		muestra += sin(TAU * 441.0 * t) * 0.022 * envolvente
		muestra += sin(TAU * 147.0 * t) * 0.012 * exp(-t * 7.2)
		_escribir_muestra(datos, i, muestra)

	pista.data = datos
	_eco_cache = pista
	return pista


static func _escribir_muestra(datos: PackedByteArray, indice: int, muestra: float) -> void:
	var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
	if valor < 0:
		valor += 65536
	datos[indice * 2] = valor & 0xFF
	datos[indice * 2 + 1] = (valor >> 8) & 0xFF
