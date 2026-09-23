## Representación física, procedural y opcional de la impresora de #1054.
##
## El nodo solo visualiza el controlador local: carcasa, LED, salida de papel y
## sonido mecánico. No persiste tiras ni las convierte en inventario/recompensa.
class_name ImpresoraTermicaPortatil3D
extends Interactuable3D

const FRECUENCIA_AUDIO := 22050
const DURACION_AUDIO := 0.38

var _controlador := ImpresoraTermicaPortatil.new()
var _material_led: StandardMaterial3D
var _papel_visual: MeshInstance3D
var _malla_papel: BoxMesh
var _material_papel: StandardMaterial3D
var _audio: AudioStreamPlayer3D
var _sonido_habilitado := true
var _animacion_habilitada := true


func configurar() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	verbo = Verbo.ENCENDER
	nombre_objeto = "impresora térmica"
	sonido = SIN_SONIDO
	_montar_colision()
	_montar_carcasa()
	_montar_papel()
	_preparar_audio()

	_controlador.estado_cambiado.connect(_al_cambiar_estado)
	_controlador.impresion_iniciada.connect(_al_iniciar_impresion)
	_controlador.progreso_cambiado.connect(_al_cambiar_progreso)
	_controlador.papel_listo.connect(_al_estar_papel_listo)
	_controlador.papel_recogido.connect(_al_recoger_papel)
	activado.connect(_activar)
	_refrescar_estado()


func controlador() -> ImpresoraTermicaPortatil:
	return _controlador


func establecer_sonido_habilitado(habilitado: bool) -> void:
	_sonido_habilitado = habilitado
	if not habilitado and _audio != null:
		_audio.stop()


func establecer_animacion_habilitada(habilitada: bool) -> void:
	_animacion_habilitada = habilitada
	_refrescar_papel()


func texto_accion() -> String:
	match _controlador.estado():
		ImpresoraTermicaPortatil.Estado.APAGADA:
			return "Encender impresora térmica"
		ImpresoraTermicaPortatil.Estado.LISTA:
			return "Apagar impresora térmica"
		ImpresoraTermicaPortatil.Estado.IMPRIMIENDO:
			return "Impresora térmica · imprimiendo"
		ImpresoraTermicaPortatil.Estado.PAPEL_DISPONIBLE:
			return "Recoger tira térmica"
	return super.texto_accion()


func _process(delta: float) -> void:
	_controlador.avanzar(delta)


func _activar(_actor: Node) -> void:
	match _controlador.estado():
		ImpresoraTermicaPortatil.Estado.APAGADA:
			_controlador.encender()
		ImpresoraTermicaPortatil.Estado.LISTA:
			_controlador.apagar()
		ImpresoraTermicaPortatil.Estado.PAPEL_DISPONIBLE:
			_controlador.recoger_papel()


func _montar_colision() -> void:
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.30, 0.24, 0.32)
	colision.position = Vector3(0, 0.12, 0)
	colision.shape = forma
	add_child(colision)


func _montar_carcasa() -> void:
	var carcasa := MeshInstance3D.new()
	carcasa.name = "CarcasaImpresoraOriginal98"
	carcasa.mesh = load(
		"res://assets/modelos/props_originales_98/impresora_termica_98.obj"
	) as Mesh
	add_child(carcasa)

	var led := MeshInstance3D.new()
	led.name = "LedImpresoraTermica"
	var esfera := SphereMesh.new()
	esfera.radius = 0.010
	esfera.height = 0.020
	led.mesh = esfera
	led.position = Vector3(0.095, 0.205, -0.095)
	_material_led = StandardMaterial3D.new()
	_material_led.albedo_color = Color(0.16, 0.03, 0.02)
	_material_led.emission_enabled = true
	led.material_override = _material_led
	add_child(led)

func _montar_papel() -> void:
	_papel_visual = MeshInstance3D.new()
	_papel_visual.name = "TiraPapelTermico"
	_malla_papel = BoxMesh.new()
	_malla_papel.size = Vector3(0.16, 0.003, 0.02)
	_papel_visual.mesh = _malla_papel
	_papel_visual.position = Vector3(0, 0.155, -0.18)
	_material_papel = StandardMaterial3D.new()
	_material_papel.albedo_color = Color(0.96, 0.94, 0.86)
	_material_papel.roughness = 0.96
	_papel_visual.material_override = _material_papel
	add_child(_papel_visual)
	_papel_visual.visible = false


func _preparar_audio() -> void:
	_audio = AudioStreamPlayer3D.new()
	_audio.name = "AudioImpresoraTermica"
	_audio.stream = _crear_sonido_mecanico()
	_audio.volume_db = -13.0
	_audio.max_distance = 4.5
	add_child(_audio)


func _al_cambiar_estado(_estado: int) -> void:
	_refrescar_estado()


func _al_iniciar_impresion() -> void:
	if _sonido_habilitado and _audio != null:
		_audio.play()
	_refrescar_papel()


func _al_cambiar_progreso(_progreso: float) -> void:
	_refrescar_papel()


func _al_estar_papel_listo(imagen: Image) -> void:
	if _material_papel != null:
		_material_papel.albedo_texture = ImageTexture.create_from_image(imagen)
	_refrescar_papel()


func _al_recoger_papel() -> void:
	if _material_papel != null:
		_material_papel.albedo_texture = null
	_refrescar_papel()


func _refrescar_estado() -> void:
	if _material_led == null:
		return
	match _controlador.estado():
		ImpresoraTermicaPortatil.Estado.APAGADA:
			_material_led.emission = Color(0.08, 0.0, 0.0)
			_material_led.emission_energy_multiplier = 0.08
		ImpresoraTermicaPortatil.Estado.LISTA:
			_material_led.emission = Color(0.05, 0.48, 0.09)
			_material_led.emission_energy_multiplier = 0.65
		ImpresoraTermicaPortatil.Estado.IMPRIMIENDO:
			_material_led.emission = Color(0.76, 0.42, 0.03)
			_material_led.emission_energy_multiplier = 1.0
		ImpresoraTermicaPortatil.Estado.PAPEL_DISPONIBLE:
			_material_led.emission = Color(0.07, 0.62, 0.14)
			_material_led.emission_energy_multiplier = 1.2
	_refrescar_papel()


func _refrescar_papel() -> void:
	if _papel_visual == null or _malla_papel == null:
		return
	var estado := _controlador.estado()
	if estado == ImpresoraTermicaPortatil.Estado.PAPEL_DISPONIBLE:
		_malla_papel.size = Vector3(0.16, 0.003, 0.18)
		_papel_visual.position.z = -0.26
		_papel_visual.visible = true
		return
	if estado != ImpresoraTermicaPortatil.Estado.IMPRIMIENDO or not _animacion_habilitada:
		_papel_visual.visible = false
		return
	var longitud := lerpf(0.02, 0.16, _controlador.progreso())
	_malla_papel.size = Vector3(0.16, 0.003, longitud)
	_papel_visual.position.z = -0.17 - longitud * 0.5
	_papel_visual.visible = true


func _agregar_caja(pos: Vector3, tam: Vector3, color: Color) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	malla.material_override = material
	add_child(malla)
	return malla


static func _crear_sonido_mecanico() -> AudioStreamWAV:
	var muestras := int(round(DURACION_AUDIO * FRECUENCIA_AUDIO))
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for indice in range(muestras):
		var t := float(indice) / float(FRECUENCIA_AUDIO)
		var avance := float(indice) / float(maxi(1, muestras - 1))
		var envolvente := sin(PI * avance)
		var traqueteo := 1.0 if int(indice / 88) % 2 == 0 else -1.0
		var onda := sin(TAU * 118.0 * t) * 0.16 + sin(TAU * 690.0 * t) * 0.10 + traqueteo * 0.07
		var muestra := int(clampf(onda * envolvente, -1.0, 1.0) * 32767.0)
		datos.encode_s16(indice * 2, muestra)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = FRECUENCIA_AUDIO
	stream.stereo = false
	stream.data = datos
	return stream
