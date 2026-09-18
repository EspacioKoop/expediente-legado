## Ambiente continuo del mundo (#119).
##
## Separado de `Sonido` (efectos puntuales) y `Musica` (momentos dramáticos).
## Mientras no haya assets externos con procedencia completa, las cuatro fases
## usan camas procedurales, deterministas y en bucle. Así el recorrido no queda
## mudo y no se inventan licencias ni hashes para Freesound/Sonniss.
class_name Ambiente
extends RefCounted

const NODO := "AmbienteContinuo"
const FRECUENCIA := 22_050
const DURACION_CORTA := 1.0
const DURACION_LARGA := 4.0
const FUNDIDO_SEGUNDOS := 0.35
const VOLUMEN_SILENCIO_DB := -60.0
const META_FASE := &"fase_ambiente"
const FASES := ["archivo", "trayecto", "casa", "sueño"]

static var _pistas: Dictionary = {}


static func stream(fase: String) -> AudioStream:
	if not FASES.has(fase):
		return null
	if not _pistas.has(fase):
		_pistas[fase] = _crear_pista(fase)
	return _pistas[fase] as AudioStreamWAV


static func zumbido_archivo() -> AudioStreamWAV:
	return stream("archivo") as AudioStreamWAV


static func _crear_pista(fase: String) -> AudioStreamWAV:
	var duracion := DURACION_CORTA if fase == "archivo" else DURACION_LARGA
	var pista := AudioStreamWAV.new()
	pista.format = AudioStreamWAV.FORMAT_16_BITS
	pista.mix_rate = FRECUENCIA
	pista.stereo = false
	pista.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pista.loop_begin = 0

	var muestras := int(FRECUENCIA * duracion)
	pista.loop_end = muestras
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var muestra := _muestra(fase, i, t)
		var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
		if valor < 0:
			valor += 65536
		datos[i * 2] = valor & 0xFF
		datos[i * 2 + 1] = (valor >> 8) & 0xFF
	pista.data = datos
	return pista


static func _muestra(fase: String, indice: int, t: float) -> float:
	match fase:
		"archivo":
			# Red eléctrica + segundo armónico, con ruido determinista muy bajo.
			# Debe llenar el silencio sin competir con documentos, pasos o diálogo.
			return (
				sin(TAU * 50.0 * t) * 0.055
				+ sin(TAU * 100.0 * t) * 0.018
				+ _ruido(indice, 11) * 0.006
			)
		"trayecto":
			# Rumor urbano nocturno: grave lejano, aire y una modulación lenta que
			# evita leerlo como una máquina interior estable.
			var pulso_calle := 0.72 + sin(TAU * 0.5 * t) * 0.18
			return (
				sin(TAU * 31.5 * t) * 0.018
				+ sin(TAU * 63.0 * t) * 0.008
				+ _ruido(indice, 37) * 0.017 * pulso_calle
			)
		"casa":
			# Casa de noche: instalación eléctrica y electrodoméstico lejano. Es
			# deliberadamente más quieta que oficina y calle.
			var compresor := 0.70 + sin(TAU * 0.25 * t) * 0.20
			return (
				sin(TAU * 50.0 * t) * 0.014 * compresor
				+ sin(TAU * 75.0 * t) * 0.004
				+ _ruido(indice, 73) * 0.003
			)
		"sueño":
			# No es silencio digital: dos tonos casi vecinos crean un batido lento
			# y una respiración de ruido apenas audible, extraña pero no musical.
			var respiracion := 0.55 + sin(TAU * 0.25 * t) * 0.25
			return (
				sin(TAU * 41.0 * t) * 0.008
				+ sin(TAU * 41.5 * t) * 0.007
				+ _ruido(indice, 101) * 0.004 * respiracion
			)
		_:
			return 0.0


static func _ruido(indice: int, semilla: int) -> float:
	var valor := ((indice + semilla) * 1103515245 + 12345) & 0x7FFFFFFF
	return float((valor >> 16) & 0x7FFF) / 16384.0 - 1.0


static func reproducir(nodo: Node, fase: String, volumen_db: float = -24.0) -> AudioStreamPlayer:
	if nodo == null:
		return null
	var pista := stream(fase)
	if pista == null:
		detener(nodo)
		return null

	var anterior := nodo.get_node_or_null(NODO) as AudioStreamPlayer
	if anterior != null and String(anterior.get_meta(META_FASE, "")) == fase:
		return anterior
	if anterior != null:
		_fundir_salida(nodo, anterior)

	var voz := AudioStreamPlayer.new()
	voz.name = NODO
	voz.stream = pista
	voz.volume_db = VOLUMEN_SILENCIO_DB
	voz.set_meta(META_FASE, fase)
	nodo.add_child(voz)
	voz.play()

	var entrada := nodo.create_tween()
	entrada.tween_property(voz, "volume_db", volumen_db, FUNDIDO_SEGUNDOS)
	return voz


static func detener(nodo: Node) -> void:
	if nodo == null:
		return
	var voz := nodo.get_node_or_null(NODO) as AudioStreamPlayer
	if voz == null:
		return
	_fundir_salida(nodo, voz)


static func _fundir_salida(nodo: Node, voz: AudioStreamPlayer) -> void:
	voz.name = "%sSaliente" % NODO
	var salida := nodo.create_tween()
	salida.tween_property(voz, "volume_db", VOLUMEN_SILENCIO_DB, FUNDIDO_SEGUNDOS)
	salida.tween_callback(voz.queue_free)
