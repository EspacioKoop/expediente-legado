## Ambiente continuo del mundo (#119).
##
## Separado de Sonido (efectos puntuales) y Musica (momentos dramaticos).
## Mientras no haya assets externos con procedencia completa, las cuatro fases
## usan camas procedurales, deterministas y en bucle. Asi el recorrido no queda
## mudo y no se inventan licencias ni hashes para Freesound/Sonniss.
##
## #966 anade una capa adaptativa opt-in. El contexto llega desde fuera: este
## modulo no inventa un reloj, estres ni meticulosidad mientras #963/#952/#961
## no tengan una fuente de verdad. Sin contexto se conserva la cama de #119.
class_name Ambiente
extends RefCounted

const NODO := "AmbienteContinuo"
const FRECUENCIA := 22_050
const DURACION_CORTA := 1.0
const DURACION_LARGA := 4.0
const FUNDIDO_SEGUNDOS := 0.35
const VOLUMEN_SILENCIO_DB := -60.0
const META_FASE := &"fase_ambiente"
const META_PERFIL := &"perfil_ambiente"
const FASES := ["archivo", "trayecto", "casa", "sueño"]

const FRANJA_BASE := "base"
const FRANJA_MANANA := "manana"
const FRANJA_MEDIODIA := "mediodia"
const FRANJA_TARDE := "tarde"
const FRANJA_NOCHE := "noche"

static var _pistas: Dictionary = {}
static var _pistas_adaptativas: Dictionary = {}


static func stream(fase: String) -> AudioStream:
	if not FASES.has(fase):
		return null
	if not _pistas.has(fase):
		_pistas[fase] = _crear_pista(fase)
	return _pistas[fase] as AudioStreamWAV


## Variante discretizada de la cama continua.
##
## Claves opcionales de contexto:
## - hora: hora interna 0..24; solo el archivo cambia actividad por franja;
## - estres: 0..1; anade una tension muy leve, nunca informacion;
## - meticulosidad: 0..1; hace audibles microdetalles no esenciales;
## - vigilia_fase: fase cuya huella se filtra dentro de sueño.
##
## Los valores continuos se convierten en bandas para acotar cache y evitar
## reconstruir audio por fluctuaciones minimas. Un contexto neutro reutiliza
## exactamente stream(fase), de modo que #119 conserva su comportamiento.
static func stream_adaptativo(fase: String, contexto: Dictionary = {}) -> AudioStream:
	if not FASES.has(fase):
		return null
	if contexto.is_empty():
		return stream(fase)

	var perfil := perfil_adaptativo(fase, contexto)
	if perfil.is_empty() or _perfil_es_base(perfil):
		return stream(fase)

	var firma := _firma_perfil(perfil)
	if not _pistas_adaptativas.has(firma):
		_pistas_adaptativas[firma] = _crear_pista_con_perfil(fase, perfil)
	return _pistas_adaptativas[firma] as AudioStreamWAV


## Contrato puro para que #963/#952/#961 puedan alimentar el audio sin que
## Ambiente lea Jornada, Partida, reloj real ni otras fuentes paralelas.
static func perfil_adaptativo(fase: String, contexto: Dictionary = {}) -> Dictionary:
	if not FASES.has(fase):
		return {}

	var franja := FRANJA_BASE
	if fase == "archivo" and contexto.has("hora"):
		franja = _franja_horaria(clampf(float(contexto.get("hora", 12.0)), 0.0, 23.999))

	var nivel_estres := 0
	if contexto.has("estres"):
		nivel_estres = _nivel(clampf(float(contexto.get("estres", 0.0)), 0.0, 1.0))

	var nivel_detalle := 0
	if contexto.has("meticulosidad"):
		nivel_detalle = _nivel(clampf(float(contexto.get("meticulosidad", 0.0)), 0.0, 1.0))

	var vigilia := String(contexto.get("vigilia_fase", ""))
	if fase != "sueño" or not FASES.has(vigilia) or vigilia == "sueño":
		vigilia = ""

	return {
		"fase": fase,
		"franja": franja,
		"estres": nivel_estres,
		"detalle": nivel_detalle,
		"vigilia": vigilia,
	}


static func zumbido_archivo() -> AudioStreamWAV:
	return stream("archivo") as AudioStreamWAV


static func _franja_horaria(hora: float) -> String:
	if hora < 7.0 or hora >= 19.0:
		return FRANJA_NOCHE
	if hora < 11.0:
		return FRANJA_MANANA
	if hora < 15.0:
		return FRANJA_MEDIODIA
	return FRANJA_TARDE


static func _nivel(valor: float) -> int:
	if valor < 0.34:
		return 0
	if valor < 0.67:
		return 1
	return 2


static func _perfil_es_base(perfil: Dictionary) -> bool:
	return (
		String(perfil.get("franja", FRANJA_BASE)) == FRANJA_BASE
		and int(perfil.get("estres", 0)) == 0
		and int(perfil.get("detalle", 0)) == 0
		and String(perfil.get("vigilia", "")).is_empty()
	)


static func _firma_perfil(perfil: Dictionary) -> String:
	return "%s|%s|e%d|d%d|v%s" % [
		String(perfil.get("fase", "")),
		String(perfil.get("franja", FRANJA_BASE)),
		int(perfil.get("estres", 0)),
		int(perfil.get("detalle", 0)),
		String(perfil.get("vigilia", "")),
	]


static func _crear_pista(fase: String) -> AudioStreamWAV:
	return _crear_pista_con_perfil(fase, {})


static func _crear_pista_con_perfil(fase: String, perfil: Dictionary) -> AudioStreamWAV:
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
		var muestra := (
			_muestra(fase, i, t)
			if perfil.is_empty()
			else _muestra_adaptativa(fase, i, t, perfil)
		)
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
			# Red electrica + segundo armonico, con ruido determinista muy bajo.
			# Debe llenar el silencio sin competir con documentos, pasos o dialogo.
			return (
				sin(TAU * 50.0 * t) * 0.055
				+ sin(TAU * 100.0 * t) * 0.018
				+ _ruido(indice, 11) * 0.006
			)
		"trayecto":
			# Rumor urbano nocturno: grave lejano, aire y una modulacion lenta que
			# evita leerlo como una maquina interior estable.
			var pulso_calle := 0.72 + sin(TAU * 0.5 * t) * 0.18
			return (
				sin(TAU * 31.5 * t) * 0.018
				+ sin(TAU * 63.0 * t) * 0.008
				+ _ruido(indice, 37) * 0.017 * pulso_calle
			)
		"casa":
			# Casa de noche: instalacion electrica y electrodomestico lejano. Es
			# deliberadamente mas quieta que oficina y calle.
			var compresor := 0.70 + sin(TAU * 0.25 * t) * 0.20
			return (
				sin(TAU * 50.0 * t) * 0.014 * compresor
				+ sin(TAU * 75.0 * t) * 0.004
				+ _ruido(indice, 73) * 0.003
			)
		"sueño":
			# No es silencio digital: dos tonos casi vecinos crean un batido lento
			# y una respiracion de ruido apenas audible, extrana pero no musical.
			var respiracion := 0.55 + sin(TAU * 0.25 * t) * 0.25
			return (
				sin(TAU * 41.0 * t) * 0.008
				+ sin(TAU * 41.5 * t) * 0.007
				+ _ruido(indice, 101) * 0.004 * respiracion
			)
		_:
			return 0.0


static func _muestra_adaptativa(
	fase: String, indice: int, t: float, perfil: Dictionary
) -> float:
	var muestra := _muestra(fase, indice, t)

	if fase == "archivo":
		var franja := String(perfil.get("franja", FRANJA_BASE))
		muestra *= _factor_archivo(franja)
		muestra += _actividad_archivo(franja, indice, t)

	muestra += _capa_estres(fase, int(perfil.get("estres", 0)), t)
	muestra += _capa_detalle(int(perfil.get("detalle", 0)), indice, t)

	var vigilia := String(perfil.get("vigilia", ""))
	if fase == "sueño" and not vigilia.is_empty():
		# Recuerdo debilitado y ralentizado: reconocible como textura, nunca como
		# una fuente diegetica que indique un objeto o salida inexistentes.
		muestra += _muestra(vigilia, indice, t * 0.71) * 0.11

	return muestra


static func _factor_archivo(franja: String) -> float:
	match franja:
		FRANJA_MANANA:
			return 1.02
		FRANJA_MEDIODIA:
			return 0.86
		FRANJA_TARDE:
			return 1.05
		FRANJA_NOCHE:
			return 0.72
		_:
			return 1.0


static func _actividad_archivo(franja: String, indice: int, t: float) -> float:
	var amplitud := 0.0
	match franja:
		FRANJA_MANANA:
			amplitud = 0.0045
		FRANJA_MEDIODIA:
			amplitud = 0.0015
		FRANJA_TARDE:
			amplitud = 0.0055
		FRANJA_NOCHE:
			amplitud = 0.0008
		_:
			return 0.0

	var pulso := 0.35 + pow(maxf(0.0, sin(TAU * 2.0 * t)), 6.0) * 0.65
	return (
		_ruido(indice, 149) * amplitud * 0.65
		+ sin(TAU * 187.0 * t) * amplitud * 0.35 * pulso
	)


static func _capa_estres(fase: String, nivel: int, t: float) -> float:
	if nivel <= 0:
		return 0.0
	var intensidad := 0.0018 if nivel == 1 else 0.0042
	if fase == "sueño":
		intensidad *= 1.15
	var pulso := pow(maxf(0.0, sin(TAU * 1.1 * t)), 10.0)
	return sin(TAU * 48.0 * t) * intensidad * pulso


static func _capa_detalle(nivel: int, indice: int, t: float) -> float:
	if nivel <= 0:
		return 0.0
	var intensidad := 0.0010 if nivel == 1 else 0.0022
	return (
		_ruido(indice * 3 + 17, 233) * intensidad
		+ sin(TAU * 997.0 * t) * intensidad * 0.25
	)


static func _ruido(indice: int, semilla: int) -> float:
	var valor := ((indice + semilla) * 1103515245 + 12345) & 0x7FFFFFFF
	return float((valor >> 16) & 0x7FFF) / 16384.0 - 1.0


static func reproducir(
	nodo: Node,
	fase: String,
	volumen_db: float = -24.0,
	contexto: Dictionary = {},
) -> AudioStreamPlayer:
	if nodo == null:
		return null
	var pista := stream_adaptativo(fase, contexto)
	if pista == null:
		detener(nodo)
		return null

	var perfil := perfil_adaptativo(fase, contexto)
	var firma := "%s|base" % fase if _perfil_es_base(perfil) else _firma_perfil(perfil)
	var anterior := nodo.get_node_or_null(NODO) as AudioStreamPlayer
	if (
		anterior != null
		and String(anterior.get_meta(META_FASE, "")) == fase
		and String(anterior.get_meta(META_PERFIL, "")) == firma
	):
		return anterior
	if anterior != null:
		_fundir_salida(nodo, anterior)

	var voz := AudioStreamPlayer.new()
	voz.name = NODO
	voz.stream = pista
	voz.volume_db = VOLUMEN_SILENCIO_DB
	voz.set_meta(META_FASE, fase)
	voz.set_meta(META_PERFIL, firma)
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
