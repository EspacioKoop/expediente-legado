class_name SuenoAyudaResonancia3D
extends Node3D

## Feedback local y efímero para una ayuda ya validada (#378).
## Solo crea luz y audio procedural. No tiene colisión ni escribe estado.

const AyudaCatalogo = preload("res://guion/red/ayuda_catalogo.gd")
const AyudaDatos = preload("res://guion/red/ayuda_datos.gd")

const DURACION_SEGUNDOS := 1.8
const FRECUENCIA := 22_050
const DURACION_AUDIO := 0.72
const COLOR_RESONANCIA := Color(0.48, 0.58, 0.92)
const ENERGIA_LEVE := 0.78
const ENERGIA_MEDIA := 1.08
const RANGO_LEVE := 3.8
const RANGO_MEDIA := 5.0

static var _eco_cache: AudioStreamWAV

var _luz: OmniLight3D
var _audio: AudioStreamPlayer3D
var _tiempo := 0.0
var _energia_base := 0.0


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
	var strength := String(datos["strength"])
	set_meta("decorativo", true)
	set_meta("anchor_id", String(datos["anchor_id"]))
	set_meta("event_id", String(normalizado.get("event_id", "")))
	_montar_luz(strength)
	_montar_audio()
	_tiempo = 0.0
	set_process(true)
	return true


func _montar_luz(strength: String) -> void:
	_luz = OmniLight3D.new()
	_luz.name = "PulsoResonancia"
	_luz.light_color = COLOR_RESONANCIA
	_luz.shadow_enabled = false
	_luz.light_energy = ENERGIA_MEDIA if strength == "media" else ENERGIA_LEVE
	_luz.omni_range = RANGO_MEDIA if strength == "media" else RANGO_LEVE
	_energia_base = _luz.light_energy
	add_child(_luz)


func _montar_audio() -> void:
	_audio = AudioStreamPlayer3D.new()
	_audio.name = "EcoResonancia"
	_audio.stream = _eco_breve()
	_audio.volume_db = -9.0
	_audio.unit_size = 4.0
	_audio.max_distance = 14.0
	add_child(_audio)
	_audio.play()


func _process(delta: float) -> void:
	_tiempo += maxf(delta, 0.0)
	if _luz != null:
		var restante := maxf(0.0, 1.0 - _tiempo / DURACION_SEGUNDOS)
		var pulso := 0.72 + 0.28 * sin(_tiempo * TAU * 2.4)
		_luz.light_energy = _energia_base * restante * pulso
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
