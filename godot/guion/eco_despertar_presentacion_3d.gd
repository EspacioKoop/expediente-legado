## Presentación efímera de un eco sueño → vigilia (#1775).
##
## Solo dibuja o reproduce material sensorial ya validado por EcosDespertar.
## No crea colisiones, pistas, texto, progreso ni estado persistente.
class_name EcoDespertarPresentacion3D
extends Node3D

const NOMBRE := "EcoDespertar1775"
const DURACION_CRT := 2.8
const ESCALA_CELDA := 1.35

var _material_crt: StandardMaterial3D
var _tiempo_crt := 0.0
var _animar_crt := false


static func montar(
	mundo: Node3D, presentacion: Dictionary, espacio: Dictionary
) -> EcoDespertarPresentacion3D:
	if mundo == null or presentacion.is_empty():
		return null
	var eco_id := String(presentacion.get("id", "")).strip_edges()
	var tipo := String(presentacion.get("tipo", ""))
	if eco_id.is_empty() or not EcosDespertar.TIPOS.has(tipo):
		return null

	var existente := mundo.get_node_or_null(NOMBRE)
	if existente is EcoDespertarPresentacion3D:
		return existente as EcoDespertarPresentacion3D

	var capa := EcoDespertarPresentacion3D.new()
	capa.name = NOMBRE
	capa.set_meta("eco_id", eco_id)
	capa.set_meta("tipo", tipo)
	capa.set_meta("origen_id", String(presentacion.get("origen_id", "")))
	capa.set_meta("solo_visual", true)
	capa.set_meta("sin_progreso", true)
	capa.set_meta("afecta_navegacion", false)
	var reducida := String(presentacion.get("estilo", "")) == "corte"
	capa.set_meta("reduccion_movimiento", reducida)
	mundo.add_child(capa)

	var base := _entrada(espacio)
	match tipo:
		EcosDespertar.HUMEDAD:
			capa._montar_humedad(base)
		EcosDespertar.CRT:
			capa._montar_crt(base, not reducida)
		EcosDespertar.OBJETO_DESPLAZADO:
			capa._montar_objeto(base, String(presentacion.get("origen_id", "")))
		EcosDespertar.SONIDO_RESIDUAL:
			capa._montar_sonido(base)
		_:
			capa.queue_free()
			return null
	return capa


func _process(delta: float) -> void:
	if not _animar_crt or _material_crt == null:
		set_process(false)
		return
	_tiempo_crt += delta
	var progreso := clampf(_tiempo_crt / DURACION_CRT, 0.0, 1.0)
	_material_crt.emission_energy_multiplier = lerpf(1.1, 0.12, progreso)
	if progreso >= 1.0:
		_animar_crt = false
		set_process(false)


func _montar_humedad(base: Vector3) -> void:
	var charco := MeshInstance3D.new()
	charco.name = "HumedadResidual"
	var malla := CylinderMesh.new()
	malla.top_radius = 0.48
	malla.bottom_radius = 0.48
	malla.height = 0.012
	charco.mesh = malla
	charco.position = base + Vector3(0.65, 0.018, 0.35)
	charco.scale.z = 0.64
	charco.material_override = _material(Color(0.12, 0.20, 0.28, 0.50), false)
	charco.set_meta("solo_visual", true)
	add_child(charco)


func _montar_crt(base: Vector3, animar: bool) -> void:
	var pantalla := MeshInstance3D.new()
	pantalla.name = "EstaticaCRTResidual"
	var malla := BoxMesh.new()
	malla.size = Vector3(0.72, 0.46, 0.025)
	pantalla.mesh = malla
	pantalla.position = base + Vector3(-0.72, 1.05, 0.38)
	_material_crt = _material(Color(0.62, 0.70, 0.66, 0.42), true)
	_material_crt.emission_energy_multiplier = 1.1 if animar else 0.18
	pantalla.material_override = _material_crt
	pantalla.set_meta("solo_visual", true)
	add_child(pantalla)
	_animar_crt = animar
	set_meta("animacion", animar)
	set_process(animar)


func _montar_objeto(base: Vector3, origen_id: String) -> void:
	var eco := MeshInstance3D.new()
	eco.name = "ObjetoDesplazadoResidual"
	var malla := BoxMesh.new()
	malla.size = _tam_objeto(origen_id)
	eco.mesh = malla
	eco.position = base + Vector3(0.78, malla.size.y * 0.5, -0.48)
	eco.rotation.y = 0.14
	eco.material_override = _material(Color(0.40, 0.37, 0.34, 0.34), false)
	eco.set_meta("origen_id", origen_id)
	eco.set_meta("solo_visual", true)
	add_child(eco)


func _montar_sonido(base: Vector3) -> void:
	var voz := AudioStreamPlayer3D.new()
	voz.name = "SonidoResidual"
	voz.position = base + Vector3(0.0, 1.0, 0.0)
	voz.unit_size = 3.0
	voz.stream = _pulso_sintetico()
	add_child(voz)
	voz.play()


static func _entrada(espacio: Dictionary) -> Vector3:
	var valor: Variant = espacio.get("entrada", Vector3.ZERO)
	if valor is Vector3:
		return valor as Vector3
	if valor is Vector2i:
		return Vector3(float(valor.x) * ESCALA_CELDA, 0.0, float(valor.y) * ESCALA_CELDA)
	return Vector3.ZERO


static func _tam_objeto(origen_id: String) -> Vector3:
	if origen_id.ends_with("silla"):
		return Vector3(0.48, 0.82, 0.48)
	if origen_id.ends_with("archivador"):
		return Vector3(0.72, 1.05, 0.42)
	return Vector3(0.86, 1.18, 0.50)


static func _material(color: Color, emisivo: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.35
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emisivo:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b, 1.0)
	return material


## Mismo pulso procedimental usado por DESFASE en la noche: no introduce una
## muestra nueva ni información que el jugador no haya oído.
static func _pulso_sintetico() -> AudioStreamWAV:
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
