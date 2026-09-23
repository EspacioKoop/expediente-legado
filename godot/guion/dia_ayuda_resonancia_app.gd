class_name DiaAyudaResonanciaApp
extends Node

## Presenta ayudas asíncronas de #378 dentro del primer sueño.
## Consume solo el contrato online y la geometría ya visible de la escena.

const AyudaServicio = preload("res://guion/red/ayuda_servicio.gd")
const EventoOnline = preload("res://guion/red/evento_online.gd")
const SuenoAyudaResonancia3D = preload("res://guion/sueno_ayuda_resonancia_3d.gd")

const SCENE_KEY := "suenio/primera_noche"
const INTERVALO_CONSULTA := 2.0
const NOMBRE_PREFIJO := "AyudaResonancia"

var _host
var _servicio := AyudaServicio.new()
var _acumulado := 0.0
var _mundo_id := 0
var _vistos: Dictionary = {}


func _ready() -> void:
	_host = get_parent()


func _process(delta: float) -> void:
	if _host == null or not is_instance_valid(_host):
		return
	if String(_host.jornada.get("fase", "")) != "sueño":
		_reiniciar_mundo()
		return
	if int(_host.jornada.get("dia", 0)) != 1:
		_reiniciar_mundo()
		return
	var mundo := _host._mundo as Node3D
	if mundo == null or not is_instance_valid(mundo):
		return

	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_id:
		_mundo_id = mundo_id
		_vistos.clear()
		_acumulado = INTERVALO_CONSULTA

	_acumulado += maxf(delta, 0.0)
	if _acumulado < INTERVALO_CONSULTA:
		return
	_acumulado = 0.0
	mostrar_ayudas_en(mundo, _host._espacio_actual)


func configurar_transporte(transporte: RefCounted = null) -> void:
	var visibles := _servicio.ayudas_visibles()
	_servicio = AyudaServicio.new(transporte)
	_servicio.set_ayudas_visibles(visibles)
	_acumulado = INTERVALO_CONSULTA


func set_ayudas_visibles(activas: bool) -> void:
	_servicio.set_ayudas_visibles(activas)


func mostrar_ayudas_en(mundo: Node3D, espacio: Dictionary, ahora_unix: int = -1) -> Array:
	var conocimiento := _conocimiento_local(espacio)
	var consulta := _servicio.consultar(SCENE_KEY, conocimiento, ahora_unix)
	if not bool(consulta.get("ok", false)):
		return []

	var anchors := _anchors_locales(espacio)
	var creadas: Array = []
	for evento in consulta.get("helps", []):
		var anchor_id := String(evento.get("payload", {}).get("anchor_id", ""))
		if not anchors.has(anchor_id):
			continue
		var huella := EventoOnline.huella(evento)
		if _vistos.has(huella):
			continue

		var resonancia := SuenoAyudaResonancia3D.new()
		resonancia.name = "%s_%d" % [NOMBRE_PREFIJO, creadas.size() + 1]
		resonancia.position = anchors[anchor_id]
		mundo.add_child(resonancia)
		if not resonancia.mostrar(evento, conocimiento, ahora_unix):
			resonancia.queue_free()
			continue
		_vistos[huella] = true
		creadas.append(resonancia)
	return creadas


func _anchors_locales(espacio: Dictionary) -> Dictionary:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var anchors := {
		"suenio_umbral": entrada + Vector3(0.0, 0.55, 0.0),
	}
	var figuras: Array = espacio.get("figuras", [])
	if not figuras.is_empty() and typeof(figuras[0]) == TYPE_DICTIONARY:
		var figura: Dictionary = figuras[0]
		var posicion: Vector3 = figura.get("pos", entrada)
		anchors["suenio_figura"] = posicion + Vector3(0.0, 1.15, 0.0)
	return anchors


func _conocimiento_local(espacio: Dictionary) -> Array:
	var conocimiento: Array = []
	var figuras: Array = espacio.get("figuras", [])
	if not figuras.is_empty():
		conocimiento.append("figura_onirica")
	return conocimiento


func _reiniciar_mundo() -> void:
	_mundo_id = 0
	_vistos.clear()
	_acumulado = 0.0
