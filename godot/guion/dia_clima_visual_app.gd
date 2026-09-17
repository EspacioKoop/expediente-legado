## Refuerzo visual y sonoro del clima exterior (#797).
##
## `dia_clima_app.gd` sigue siendo dueño del estado y de la luz. Este controller
## se limita a hacer visibles y audibles sus consecuencias: niebla real del
## Environment, cielo diferenciado, precipitación centrada en el jugador,
## lectura húmeda/nevada del suelo y una cama procedural por clima. Se mantiene
## como hijo para no añadir otra capa a la cadena histórica del día.
extends Node

const CIELO_BASE_ALTO := Color(0.055, 0.075, 0.11)
const CIELO_BASE_HORIZONTE := Color(0.18, 0.17, 0.17)
const CIELO_BASE_OCASO := Color(0.30, 0.16, 0.10)
const CIELO_BASE_MEZCLA := 0.18
const NODO_SUELO_CLIMA := "ClimaSueloVisual"
const NODO_AUDIO_CLIMA := "ClimaAmbiente"
const AUDIO_FRECUENCIA := 11_025
const AUDIO_DURACION := 1.0

var _mundo_id := 0
var _estado := ""
var _activo := false


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._ambiente == null:
		return

	var mundo: Node3D = dia._mundo
	var fase := String(dia.jornada.get("fase", ""))
	if mundo == null or fase != "trayecto":
		if _activo:
			_restaurar_ambiente(dia)
			_retirar_suelo_clima(dia)
			_retirar_sonido_clima(dia)
		_mundo_id = 0
		_estado = ""
		_activo = false
		return

	var forzado := String(dia.jornada.get("clima_forzado", ""))
	var estado := (
		forzado if not forzado.is_empty() else Clima.estado(int(dia.jornada.get("dia", 1)))
	)
	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_id or estado != _estado:
		_mundo_id = mundo_id
		_estado = estado
		_activo = true
		_aplicar_estado(dia, estado)

	_seguir_precipitacion(dia)


func _aplicar_estado(dia: Node, estado: String) -> void:
	_restaurar_ambiente(dia)
	_retirar_suelo_clima(dia)
	_retirar_sonido_clima(dia)
	_asegurar_precipitacion(dia, estado)
	_aplicar_suelo_clima(dia, estado)
	_aplicar_sonido_clima(dia, estado)

	var ambiente := dia._ambiente as Environment
	if ambiente == null:
		return

	match estado:
		Clima.NUBLADO:
			_configurar_niebla(ambiente, 0.012, Color(0.42, 0.45, 0.50), 0.012, 0.55)
			ambiente.background_energy_multiplier = 0.78
			_aplicar_cielo(
				ambiente,
				Color(0.045, 0.052, 0.068),
				Color(0.13, 0.14, 0.16),
				Color(0.17, 0.13, 0.12),
				0.08
			)
		Clima.LLUVIA:
			_configurar_niebla(ambiente, 0.022, Color(0.30, 0.34, 0.40), 0.020, 0.72)
			ambiente.background_energy_multiplier = 0.62
			_aplicar_cielo(
				ambiente,
				Color(0.022, 0.030, 0.046),
				Color(0.075, 0.09, 0.115),
				Color(0.10, 0.08, 0.08),
				0.04
			)
		Clima.NIEBLA:
			_configurar_niebla(ambiente, 0.085, Color(0.55, 0.57, 0.60), 0.060, 1.0)
			ambiente.background_energy_multiplier = 0.70
			_aplicar_cielo(
				ambiente,
				Color(0.22, 0.23, 0.24),
				Color(0.34, 0.35, 0.37),
				Color(0.29, 0.29, 0.30),
				0.0
			)
			_configurar_volumetrica_si_disponible(ambiente)
		Clima.NIEVE:
			_configurar_niebla(ambiente, 0.030, Color(0.68, 0.72, 0.78), 0.030, 0.78)
			ambiente.background_energy_multiplier = 1.08
			_aplicar_cielo(
				ambiente,
				Color(0.085, 0.105, 0.14),
				Color(0.27, 0.29, 0.32),
				Color(0.22, 0.19, 0.20),
				0.10
			)
		_:
			pass


func _configurar_niebla(
	ambiente: Environment,
	densidad: float,
	color: Color,
	densidad_altura: float,
	afecta_cielo: float,
) -> void:
	ambiente.fog_enabled = true
	ambiente.fog_density = densidad
	ambiente.fog_light_color = color
	ambiente.fog_light_energy = 0.82
	ambiente.fog_height = 1.4
	ambiente.fog_height_density = densidad_altura
	ambiente.fog_sky_affect = afecta_cielo
	ambiente.fog_aerial_perspective = 0.12 if densidad < 0.05 else 0.0


func _configurar_volumetrica_si_disponible(ambiente: Environment) -> void:
	# El proyecto usa GL Compatibility. Godot solo soporta niebla volumétrica en
	# Forward+, de modo que aquí se activa únicamente si el renderer cambia.
	if String(RenderingServer.get_current_rendering_method()) != "forward_plus":
		ambiente.volumetric_fog_enabled = false
		return
	ambiente.volumetric_fog_enabled = true
	ambiente.volumetric_fog_density = 0.045
	ambiente.volumetric_fog_length = 36.0
	ambiente.volumetric_fog_detail_spread = 1.6
	ambiente.volumetric_fog_albedo = Color(0.74, 0.76, 0.80)
	ambiente.volumetric_fog_sky_affect = 0.9


func _asegurar_precipitacion(dia: Node, estado: String) -> void:
	var quiere := Clima.precipitacion(estado)
	var nieve := estado == Clima.NIEVE
	var nodo := dia._clima_nodo as Node3D

	if not quiere:
		if is_instance_valid(nodo):
			nodo.queue_free()
		dia._clima_nodo = null
		return

	var nombre := "Nieve" if nieve else "Lluvia"
	var correcta := is_instance_valid(nodo) and nodo.get_node_or_null(nombre) != null
	if not correcta:
		if is_instance_valid(nodo):
			nodo.queue_free()
		dia._clima_nodo = null
		dia._montar_precipitacion(nieve)
		nodo = dia._clima_nodo as Node3D

	_reforzar_precipitacion(nodo, nieve)


func _reforzar_precipitacion(nodo: Node3D, nieve: bool) -> void:
	if not is_instance_valid(nodo):
		return
	var nombre := "Nieve" if nieve else "Lluvia"
	var particulas := nodo.get_node_or_null(nombre) as GPUParticles3D
	if particulas == null:
		return

	particulas.amount = 760 if nieve else 1100
	particulas.position = Vector3(0.0, 5.6, -1.5)
	particulas.visibility_aabb = AABB(
		Vector3(-10.0, -7.0, -17.0), Vector3(20.0, 16.0, 34.0)
	)

	var malla := particulas.draw_pass_1 as QuadMesh
	if malla == null:
		return
	malla.size = Vector2(0.060, 0.060) if nieve else Vector2(0.032, 0.46)
	var material := malla.material as StandardMaterial3D
	if material != null:
		material.albedo_color = (
			Color(0.94, 0.96, 1.0, 0.92) if nieve else Color(0.64, 0.78, 0.96, 0.78)
		)


func _seguir_precipitacion(dia: Node) -> void:
	var nodo := dia._clima_nodo as Node3D
	var caminante := dia._caminante as Node3D
	if not is_instance_valid(nodo) or not is_instance_valid(caminante):
		return
	# El emisor vive en el mundo para conservar la lógica histórica, pero su
	# centro acompaña al jugador: nunca queda atrás al recorrer la calle.
	nodo.global_position = caminante.global_position


func _aplicar_suelo_clima(dia: Node, estado: String) -> void:
	if estado != Clima.LLUVIA and estado != Clima.NIEVE:
		return
	var mundo := dia._mundo as Node3D
	if mundo == null:
		return

	# Capa puramente visual sobre los 9x34 m del suelo jugable. No añade cuerpo,
	# colisión ni navegación y queda por encima de las pieles PBR de #399.
	var superficie := MeshInstance3D.new()
	superficie.name = NODO_SUELO_CLIMA
	superficie.position = Vector3(0.0, 0.028, 0.0)
	var caja := BoxMesh.new()
	caja.size = Vector3(9.0, 0.012, 34.0)
	superficie.mesh = caja
	superficie.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if estado == Clima.NIEVE:
		material.albedo_color = Color(0.80, 0.84, 0.90, 0.72)
		material.roughness = 0.88
	else:
		# Película oscura y brillante: deja leer el asfalto/acera de debajo y
		# aporta reflejo especular suficiente para distinguir lluvia de nublado.
		material.albedo_color = Color(0.08, 0.12, 0.17, 0.26)
		material.roughness = 0.14
		material.metallic = 0.08
	superficie.material_override = material
	mundo.add_child(superficie)


func _retirar_suelo_clima(dia: Node) -> void:
	var mundo := dia._mundo as Node3D
	if mundo == null:
		return
	var superficie := mundo.get_node_or_null(NODO_SUELO_CLIMA)
	if superficie != null:
		# El cambio forzado puede ocurrir dentro del mismo frame. `free()` evita
		# que el nodo siguiente tenga que renombrarse por una baja aún en cola.
		superficie.free()


func _aplicar_sonido_clima(dia: Node, estado: String) -> void:
	if estado == Clima.DESPEJADO:
		return
	var voz := AudioStreamPlayer.new()
	voz.name = NODO_AUDIO_CLIMA
	voz.stream = _crear_pista_clima(estado)
	match estado:
		Clima.LLUVIA:
			voz.volume_db = -19.0
		Clima.NIEVE:
			voz.volume_db = -29.0
		Clima.NIEBLA:
			voz.volume_db = -31.0
		_:
			voz.volume_db = -34.0
	dia.add_child(voz)
	voz.play()


func _retirar_sonido_clima(dia: Node) -> void:
	var voz := dia.get_node_or_null(NODO_AUDIO_CLIMA) as AudioStreamPlayer
	if voz == null:
		return
	voz.stop()
	# Igual que el suelo: el mismo `_process` puede sustituir la cama sonora.
	voz.free()


func _crear_pista_clima(estado: String) -> AudioStreamWAV:
	# Cama procedural y determinista: evita sumar binarios/licencias solo para
	# dar feedback de clima. La base urbana de Ambiente sigue sonando por debajo.
	var pista := AudioStreamWAV.new()
	pista.format = AudioStreamWAV.FORMAT_16_BITS
	pista.mix_rate = AUDIO_FRECUENCIA
	pista.stereo = false
	pista.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pista.loop_begin = 0

	var muestras := int(AUDIO_FRECUENCIA * AUDIO_DURACION)
	pista.loop_end = muestras
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / AUDIO_FRECUENCIA
		var muestra := _muestra_audio(estado, i, t)
		var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
		if valor < 0:
			valor += 65536
		datos[i * 2] = valor & 0xFF
		datos[i * 2 + 1] = (valor >> 8) & 0xFF
	pista.data = datos
	return pista


func _muestra_audio(estado: String, indice: int, t: float) -> float:
	match estado:
		Clima.LLUVIA:
			var pulso := 0.74 + sin(TAU * 0.7 * t) * 0.12
			return _ruido(indice, 47) * 0.32 * pulso + sin(TAU * 92.0 * t) * 0.018
		Clima.NIEVE:
			var viento_nieve := 0.55 + sin(TAU * 0.22 * t) * 0.20
			return _ruido(indice, 83) * 0.075 * viento_nieve + sin(TAU * 34.0 * t) * 0.014
		Clima.NIEBLA:
			var deriva := 0.62 + sin(TAU * 0.18 * t) * 0.16
			return _ruido(indice, 113) * 0.055 * deriva + sin(TAU * 27.0 * t) * 0.016
		Clima.NUBLADO:
			return _ruido(indice, 137) * 0.040 + sin(TAU * 41.0 * t) * 0.012
		_:
			return 0.0


func _ruido(indice: int, semilla: int) -> float:
	var valor := ((indice + semilla) * 1103515245 + 12345) & 0x7FFFFFFF
	return float((valor >> 16) & 0x7FFF) / 16384.0 - 1.0


func _aplicar_cielo(
	ambiente: Environment,
	alto: Color,
	horizonte: Color,
	ocaso: Color,
	mezcla: float,
) -> void:
	var material := _material_cielo(ambiente)
	if material == null:
		return
	material.set_shader_parameter("cielo_alto", alto)
	material.set_shader_parameter("horizonte", horizonte)
	material.set_shader_parameter("ocaso", ocaso)
	material.set_shader_parameter("ocaso_mezcla", mezcla)


func _restaurar_ambiente(dia: Node) -> void:
	var ambiente := dia._ambiente as Environment
	if ambiente == null:
		return
	ambiente.fog_enabled = false
	ambiente.fog_density = 0.01
	ambiente.fog_height = 0.0
	ambiente.fog_height_density = 0.0
	ambiente.fog_light_color = Color(0.518, 0.553, 0.608)
	ambiente.fog_light_energy = 1.0
	ambiente.fog_sky_affect = 1.0
	ambiente.fog_aerial_perspective = 0.0
	ambiente.volumetric_fog_enabled = false
	ambiente.background_energy_multiplier = 1.0
	_aplicar_cielo(
		ambiente,
		CIELO_BASE_ALTO,
		CIELO_BASE_HORIZONTE,
		CIELO_BASE_OCASO,
		CIELO_BASE_MEZCLA,
	)


func _material_cielo(ambiente: Environment) -> ShaderMaterial:
	if ambiente.sky == null:
		return null
	return ambiente.sky.sky_material as ShaderMaterial
