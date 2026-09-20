## Refuerzo visual y sonoro del clima exterior (#797, #883).
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
const TRANSICION_DURACION := 0.65
const PARAMETROS_CIELO_CLIMA := [
	"cielo_alto",
	"horizonte",
	"ocaso",
	"ocaso_mezcla",
	"resplandor_fuerza",
	"bruma_fuerza",
	"nubes",
	"nube_color",
	"cirros",
	"cirro_color",
	"luz_lunar_nubes",
	"via_lactea",
	"estrellas",
	"estrellas_secundarias",
	"luna_halo",
]

var _mundo_id := 0
var _estado := ""
var _activo := false
var _reduccion_movimiento := false
var _tween_clima: Tween = null


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._ambiente == null:
		return

	var mundo: Node3D = dia._mundo
	var fase := String(dia.jornada.get("fase", ""))
	if mundo == null or fase != "trayecto":
		if _activo:
			_cancelar_transicion()
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
	var cambia_mundo := mundo_id != _mundo_id
	var cambia_estado := estado != _estado
	if cambia_mundo or cambia_estado:
		var transicion := not cambia_mundo and not _estado.is_empty()
		_mundo_id = mundo_id
		_estado = estado
		_activo = true
		_reduccion_movimiento = bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
		_aplicar_estado(dia, estado, transicion and not _reduccion_movimiento)

	_seguir_precipitacion(dia)


func _aplicar_estado(dia: Node, estado: String, transicion: bool) -> void:
	_cancelar_transicion()
	_retirar_suelo_clima(dia)
	_retirar_sonido_clima(dia)
	_asegurar_precipitacion(dia, estado)
	_aplicar_suelo_clima(dia, estado)
	_aplicar_sonido_clima(dia, estado)
	_aplicar_coches_clima(dia, estado)

	var ambiente := dia._ambiente as Environment
	if ambiente == null:
		return
	_aplicar_perfil_ambiente(ambiente, estado, transicion)


func _perfil_ambiente(estado: String) -> Dictionary:
	var perfil := {
		"fog_enabled": false,
		"fog_density": 0.01,
		"fog_light_color": Color(0.518, 0.553, 0.608),
		"fog_light_energy": 1.0,
		"fog_height": 0.0,
		"fog_height_density": 0.0,
		"fog_sky_affect": 1.0,
		"fog_aerial_perspective": 0.0,
		"background_energy": 1.0,
		"cielo_alto": CIELO_BASE_ALTO,
		"horizonte": CIELO_BASE_HORIZONTE,
		"ocaso": CIELO_BASE_OCASO,
		"ocaso_mezcla": CIELO_BASE_MEZCLA,
		"resplandor_fuerza": 0.55,
		"bruma_fuerza": 0.32,
		"nubes": 0.28,
		"nube_color": Color(0.12, 0.13, 0.17),
		"cirros": 0.18,
		"cirro_color": Color(0.16, 0.17, 0.20),
		"luz_lunar_nubes": 0.32,
		"via_lactea": 0.08,
		"estrellas": 0.50,
		"estrellas_secundarias": 0.35,
		"luna_halo": 0.09,
	}
	match estado:
		Clima.NUBLADO:
			(
				perfil
				. merge(
					{
						"fog_enabled": true,
						"fog_density": 0.010,
						"fog_light_color": Color(0.43, 0.46, 0.51),
						"fog_light_energy": 0.80,
						"fog_height": 1.5,
						"fog_height_density": 0.010,
						"fog_sky_affect": 0.52,
						"fog_aerial_perspective": 0.12,
						"background_energy": 0.74,
						"cielo_alto": Color(0.040, 0.048, 0.064),
						"horizonte": Color(0.13, 0.14, 0.16),
						"ocaso": Color(0.16, 0.12, 0.115),
						"ocaso_mezcla": 0.07,
						"resplandor_fuerza": 0.62,
						"bruma_fuerza": 0.44,
						"nubes": 0.76,
						"nube_color": Color(0.18, 0.19, 0.22),
						"cirros": 0.56,
						"cirro_color": Color(0.22, 0.23, 0.26),
						"luz_lunar_nubes": 0.18,
						"via_lactea": 0.012,
						"estrellas": 0.08,
						"estrellas_secundarias": 0.04,
						"luna_halo": 0.045,
					},
					true,
				)
			)
		Clima.LLUVIA:
			(
				perfil
				. merge(
					{
						"fog_enabled": true,
						"fog_density": 0.028,
						"fog_light_color": Color(0.28, 0.33, 0.40),
						"fog_light_energy": 0.75,
						"fog_height": 1.35,
						"fog_height_density": 0.023,
						"fog_sky_affect": 0.76,
						"fog_aerial_perspective": 0.08,
						"background_energy": 0.54,
						"cielo_alto": Color(0.016, 0.024, 0.040),
						"horizonte": Color(0.062, 0.078, 0.105),
						"ocaso": Color(0.085, 0.067, 0.074),
						"ocaso_mezcla": 0.025,
						"resplandor_fuerza": 0.72,
						"bruma_fuerza": 0.56,
						"nubes": 0.92,
						"nube_color": Color(0.075, 0.095, 0.135),
						"cirros": 0.68,
						"cirro_color": Color(0.10, 0.12, 0.16),
						"luz_lunar_nubes": 0.10,
						"via_lactea": 0.0,
						"estrellas": 0.015,
						"estrellas_secundarias": 0.005,
						"luna_halo": 0.025,
					},
					true,
				)
			)
		Clima.NIEBLA:
			(
				perfil
				. merge(
					{
						"fog_enabled": true,
						"fog_density": 0.100,
						"fog_light_color": Color(0.57, 0.59, 0.62),
						"fog_light_energy": 0.90,
						"fog_height": 1.1,
						"fog_height_density": 0.070,
						"fog_sky_affect": 1.0,
						"fog_aerial_perspective": 0.0,
						"background_energy": 0.76,
						"cielo_alto": Color(0.23, 0.24, 0.25),
						"horizonte": Color(0.36, 0.37, 0.39),
						"ocaso": Color(0.30, 0.30, 0.31),
						"ocaso_mezcla": 0.0,
						"resplandor_fuerza": 0.46,
						"bruma_fuerza": 0.86,
						"nubes": 0.62,
						"nube_color": Color(0.30, 0.31, 0.33),
						"cirros": 0.44,
						"cirro_color": Color(0.34, 0.35, 0.37),
						"luz_lunar_nubes": 0.06,
						"via_lactea": 0.0,
						"estrellas": 0.0,
						"estrellas_secundarias": 0.0,
						"luna_halo": 0.012,
					},
					true,
				)
			)
		Clima.NIEVE:
			(
				perfil
				. merge(
					{
						"fog_enabled": true,
						"fog_density": 0.040,
						"fog_light_color": Color(0.70, 0.75, 0.82),
						"fog_light_energy": 0.92,
						"fog_height": 1.6,
						"fog_height_density": 0.034,
						"fog_sky_affect": 0.82,
						"fog_aerial_perspective": 0.10,
						"background_energy": 1.14,
						"cielo_alto": Color(0.085, 0.11, 0.15),
						"horizonte": Color(0.30, 0.32, 0.36),
						"ocaso": Color(0.23, 0.20, 0.22),
						"ocaso_mezcla": 0.09,
						"resplandor_fuerza": 0.78,
						"bruma_fuerza": 0.58,
						"nubes": 0.68,
						"nube_color": Color(0.28, 0.34, 0.43),
						"cirros": 0.38,
						"cirro_color": Color(0.38, 0.44, 0.54),
						"luz_lunar_nubes": 0.44,
						"via_lactea": 0.01,
						"estrellas": 0.12,
						"estrellas_secundarias": 0.08,
						"luna_halo": 0.12,
					},
					true,
				)
			)
	return perfil


func _aplicar_perfil_ambiente(ambiente: Environment, estado: String, animar: bool) -> void:
	var perfil := _perfil_ambiente(estado)
	var material := _material_cielo(ambiente)
	var objetivo_niebla := bool(perfil["fog_enabled"])

	if estado == Clima.NIEBLA:
		_configurar_volumetrica_si_disponible(ambiente)
	else:
		ambiente.volumetric_fog_enabled = false

	if not animar:
		_aplicar_perfil_inmediato(ambiente, material, perfil)
		return

	if objetivo_niebla and not ambiente.fog_enabled:
		ambiente.fog_enabled = true
		ambiente.fog_density = 0.0
	elif not objetivo_niebla and not ambiente.fog_enabled:
		_aplicar_perfil_inmediato(ambiente, material, perfil)
		return

	_tween_clima = create_tween()
	_tween_clima.set_parallel(true)
	_tween_clima.tween_property(
		ambiente,
		"background_energy_multiplier",
		float(perfil["background_energy"]),
		TRANSICION_DURACION
	)
	_tween_clima.tween_property(
		ambiente, "fog_density", float(perfil["fog_density"]), TRANSICION_DURACION
	)
	_tween_clima.tween_property(
		ambiente, "fog_light_color", perfil["fog_light_color"], TRANSICION_DURACION
	)
	_tween_clima.tween_property(
		ambiente, "fog_light_energy", float(perfil["fog_light_energy"]), TRANSICION_DURACION
	)
	_tween_clima.tween_property(
		ambiente, "fog_height", float(perfil["fog_height"]), TRANSICION_DURACION
	)
	_tween_clima.tween_property(
		ambiente, "fog_height_density", float(perfil["fog_height_density"]), TRANSICION_DURACION
	)
	_tween_clima.tween_property(
		ambiente, "fog_sky_affect", float(perfil["fog_sky_affect"]), TRANSICION_DURACION
	)
	(
		_tween_clima
		. tween_property(
			ambiente,
			"fog_aerial_perspective",
			float(perfil["fog_aerial_perspective"]),
			TRANSICION_DURACION,
		)
	)
	if material != null:
		for parametro in PARAMETROS_CIELO_CLIMA:
			_transicionar_parametro_cielo(material, parametro, perfil[parametro])
	_tween_clima.finished.connect(
		Callable(self, "_finalizar_transicion").bind(ambiente, objetivo_niebla)
	)


func _aplicar_perfil_inmediato(
	ambiente: Environment, material: ShaderMaterial, perfil: Dictionary
) -> void:
	ambiente.fog_enabled = bool(perfil["fog_enabled"])
	ambiente.fog_density = float(perfil["fog_density"])
	ambiente.fog_light_color = perfil["fog_light_color"]
	ambiente.fog_light_energy = float(perfil["fog_light_energy"])
	ambiente.fog_height = float(perfil["fog_height"])
	ambiente.fog_height_density = float(perfil["fog_height_density"])
	ambiente.fog_sky_affect = float(perfil["fog_sky_affect"])
	ambiente.fog_aerial_perspective = float(perfil["fog_aerial_perspective"])
	ambiente.background_energy_multiplier = float(perfil["background_energy"])
	if material == null:
		return
	for parametro in PARAMETROS_CIELO_CLIMA:
		material.set_shader_parameter(parametro, perfil[parametro])


func _transicionar_parametro_cielo(
	material: ShaderMaterial, parametro: String, objetivo: Variant
) -> void:
	var actual = material.get_shader_parameter(parametro)
	(
		_tween_clima
		. tween_method(
			Callable(self, "_poner_parametro_cielo").bind(material, parametro),
			actual,
			objetivo,
			TRANSICION_DURACION,
		)
	)


func _poner_parametro_cielo(valor: Variant, material: ShaderMaterial, parametro: String) -> void:
	material.set_shader_parameter(parametro, valor)


func _finalizar_transicion(ambiente: Environment, objetivo_niebla: bool) -> void:
	if is_instance_valid(ambiente):
		ambiente.fog_enabled = objetivo_niebla
	_tween_clima = null


func _cancelar_transicion() -> void:
	if _tween_clima != null and _tween_clima.is_valid():
		_tween_clima.kill()
	_tween_clima = null


func _configurar_volumetrica_si_disponible(ambiente: Environment) -> void:
	# Godot solo soporta niebla volumétrica en Forward+. Se pregunta por el
	# renderer en ejecución y no por el ajuste del proyecto: desde #275 es
	# Forward+, pero una exportación puede caer a Compatibility y entonces
	# encenderla sería pedirle al motor algo que no sabe dibujar.
	if String(RenderingServer.get_current_rendering_method()) != "forward_plus":
		ambiente.volumetric_fog_enabled = false
		return
	ambiente.volumetric_fog_enabled = true
	ambiente.volumetric_fog_density = 0.050
	ambiente.volumetric_fog_length = 38.0
	ambiente.volumetric_fog_detail_spread = 1.6
	ambiente.volumetric_fog_albedo = Color(0.74, 0.76, 0.80)
	ambiente.volumetric_fog_sky_affect = 0.92


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

	if _reduccion_movimiento:
		particulas.amount = 360 if nieve else 620
	else:
		particulas.amount = 900 if nieve else 1450
	particulas.randomness = 0.62 if nieve else 0.38
	particulas.position = Vector3(0.0, 5.8, -1.8)
	particulas.visibility_aabb = AABB(Vector3(-11.0, -8.0, -19.0), Vector3(22.0, 18.0, 38.0))

	var viento := 0.35 if _reduccion_movimiento else 1.0
	var proceso := particulas.process_material as ParticleProcessMaterial
	if proceso != null:
		proceso.direction = (
			Vector3(0.28 * viento, -1.0, -0.12 * viento).normalized()
			if nieve
			else Vector3(0.16 * viento, -1.0, 0.045 * viento).normalized()
		)
		proceso.spread = 15.0 if nieve else 4.0
		proceso.initial_velocity_min = 0.9 if nieve else 8.5
		proceso.initial_velocity_max = 2.5 if nieve else 13.0
		proceso.gravity = (
			Vector3(0.55 * viento, -0.55, -0.20 * viento)
			if nieve
			else Vector3(1.80 * viento, -3.0, 0.35 * viento)
		)

	var malla := particulas.draw_pass_1 as QuadMesh
	if malla == null:
		return
	malla.size = Vector2(0.070, 0.070) if nieve else Vector2(0.034, 0.54)
	var material := malla.material as StandardMaterial3D
	if material != null:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color = (
			Color(0.95, 0.97, 1.0, 0.94) if nieve else Color(0.62, 0.78, 0.98, 0.82)
		)


func _seguir_precipitacion(dia: Node) -> void:
	var nodo := dia._clima_nodo as Node3D
	var caminante := dia._caminante as Node3D
	if not is_instance_valid(nodo) or not is_instance_valid(caminante):
		return
	# El emisor vive en el mundo para conservar la lógica histórica, pero su
	# centro acompaña al jugador: nunca queda atrás al recorrer la calle.
	nodo.global_position = caminante.global_position


func _aplicar_coches_clima(dia: Node, estado: String) -> void:
	var mundo := dia._mundo as Node3D
	if mundo == null:
		return
	var lote := mundo.get_node_or_null("CochesPsxCC0") as Node3D
	CochesPsxCC0.aplicar_clima(lote, estado)


func _aplicar_suelo_clima(dia: Node, estado: String) -> void:
	if estado != Clima.LLUVIA and estado != Clima.NIEVE:
		return
	var mundo := dia._mundo as Node3D
	if mundo == null:
		return

	# En #797 era una única placa. Se conserva una película muy tenue y se
	# añaden manchas deterministas para que humedad/nieve no lean como overlay.
	var raiz := Node3D.new()
	raiz.name = NODO_SUELO_CLIMA
	mundo.add_child(raiz)
	_crear_pelicula_suelo(raiz, estado)
	_crear_parches_suelo(raiz, estado)


func _crear_pelicula_suelo(raiz: Node3D, estado: String) -> void:
	var superficie := MeshInstance3D.new()
	superficie.name = "Pelicula"
	superficie.position = Vector3(0.0, 0.028, 0.0)
	var caja := BoxMesh.new()
	caja.size = Vector3(9.0, 0.010, 34.0)
	superficie.mesh = caja
	superficie.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if estado == Clima.NIEVE:
		material.albedo_color = Color(0.78, 0.84, 0.92, 0.34)
		material.roughness = 0.94
	else:
		material.albedo_color = Color(0.04, 0.075, 0.12, 0.08)
		material.roughness = 0.16
		material.metallic = 0.06
	superficie.material_override = material
	raiz.add_child(superficie)


func _crear_parches_suelo(raiz: Node3D, estado: String) -> void:
	var nieve := estado == Clima.NIEVE
	var cantidad := 24 if nieve else 12
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if nieve:
		material.albedo_color = Color(0.86, 0.90, 0.96, 0.28)
		material.roughness = 0.96
	else:
		material.albedo_color = Color(0.025, 0.055, 0.09, 0.18)
		material.roughness = 0.08
		material.metallic = 0.10

	for indice in cantidad:
		var parche := MeshInstance3D.new()
		parche.name = "Acumulacion%02d" % indice
		parche.position = Vector3(
			-3.4 + float((indice * 37) % 68) / 10.0,
			0.040,
			-15.2 + float((indice * 53) % 304) / 10.0,
		)
		parche.rotation.y = deg_to_rad(float((indice * 29) % 180))
		parche.scale = Vector3(
			0.42 + float((indice * 17) % 10) / 20.0,
			1.0,
			0.36 + float((indice * 23) % 12) / 20.0,
		)
		parche.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var disco := CylinderMesh.new()
		disco.top_radius = 0.36
		disco.bottom_radius = 0.36
		disco.height = 0.008
		disco.radial_segments = 12
		parche.mesh = disco
		parche.material_override = material
		raiz.add_child(parche)


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
			voz.volume_db = -18.0
		Clima.NIEVE:
			voz.volume_db = -28.0
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
			var rafaga := sin(TAU * 0.17 * t) * 0.035
			return _ruido(indice, 47) * 0.34 * pulso + sin(TAU * 92.0 * t) * 0.018 + rafaga
		Clima.NIEVE:
			var viento_nieve := 0.55 + sin(TAU * 0.22 * t) * 0.20
			return _ruido(indice, 83) * 0.080 * viento_nieve + sin(TAU * 34.0 * t) * 0.014
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


func _restaurar_ambiente(dia: Node) -> void:
	var ambiente := dia._ambiente as Environment
	if ambiente == null:
		return
	ambiente.volumetric_fog_enabled = false
	_aplicar_perfil_inmediato(
		ambiente, _material_cielo(ambiente), _perfil_ambiente(Clima.DESPEJADO)
	)


func _material_cielo(ambiente: Environment) -> ShaderMaterial:
	if ambiente.sky == null:
		return null
	return ambiente.sky.sky_material as ShaderMaterial
