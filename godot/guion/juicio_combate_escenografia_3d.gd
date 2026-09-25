## Escenografía del Juicio por Combate: luz, suelo, archivo y aire.
##
## Solo viste lo que `JuicioCombateArena3D` monta; no crea colisiones, no mueve
## actores y no toca ninguna regla. El juicio ocurre en el archivo soñado, así
## que la arena es un claro entre archivadores bajo un flexo de interrogatorio:
##
## - Luz: un foco cenital sobre el centro (el interrogatorio), contraluces del
##   color del mito a los lados y niebla de profundidad que se come el fondo.
## - Suelo: losa de piedra con el círculo ritual grabado (`suelo_juicio`).
## - Archivo: los archivadores tienen cajones, y algunos están abiertos con
##   papeles asomando; un par están torcidos, que es lo que los hace de sueño.
## - Aire: papeles y polvo flotando, fuera con reducción de movimiento.
## - Cuerpos: el jugador es el suyo, el de la ficha (`CuerpoJugador3D`), y no
##   un maniquí. El rival sigue sin cara a propósito (ver `Espacio3D`: a quien
##   acusas no se le ve), pero ahora es un cuerpo humano de verdad —traje de
##   oficina, pelo, manos— pintado de negro entero, con un halo del color del
##   mito que lo despega del fondo. Una sombra con forma de persona asusta más
##   que un muñeco de cápsulas.
class_name JuicioCombateEscenografia3D
extends RefCounted

const SHADER_SUELO := "res://arte/suelo_juicio.gdshader"
const SHADER_HALO := "res://arte/halo_silueta.gdshader"
const COLOR_NEUTRO := Color(0.62, 0.55, 0.38)
## Trajes de oficina: el acusado es un comité, una empresa o un cargo.
const CUERPOS_RIVAL := [
	"rocketbox/business_male_02",
	"rocketbox/business_male_03",
	"rocketbox/business_male_04",
	"rocketbox/business_female_02",
]
const NEGRO_SILUETA := Color(0.018, 0.018, 0.022)
const PAPELES := 18
const POLVO := 40


## Color del mito del juicio, o uno neutro de latón si no tiene descriptor.
static func color_mito(mito_id: String) -> Color:
	var descriptor := JuicioSimbolico.descriptor_mito(mito_id)
	if descriptor.is_empty():
		return COLOR_NEUTRO
	return descriptor["color"]


static func vestir_entorno(entorno: Environment, color: Color) -> void:
	entorno.background_color = Color(0.012, 0.012, 0.018)
	entorno.ambient_light_color = color.lerp(Color(0.4, 0.42, 0.5), 0.6)
	entorno.ambient_light_energy = 0.32
	entorno.fog_enabled = true
	entorno.fog_light_color = Color(0.05, 0.05, 0.07)
	entorno.fog_density = 0.035
	entorno.glow_enabled = true
	entorno.glow_intensity = 0.7
	entorno.glow_bloom = 0.08


static func montar_luces(anfitrion: Node3D, color: Color) -> void:
	var foco := SpotLight3D.new()
	foco.name = "FocoInterrogatorio"
	foco.position = Vector3(0.0, 7.5, 0.0)
	foco.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	foco.light_color = Color(1.0, 0.92, 0.78)
	foco.light_energy = 3.2
	foco.spot_range = 11.0
	foco.spot_angle = 34.0
	foco.spot_attenuation = 0.8
	foco.shadow_enabled = true
	anfitrion.add_child(foco)
	for lado in [-1.0, 1.0]:
		var contraluz := OmniLight3D.new()
		contraluz.name = "Contraluz%s" % ("Izq" if lado < 0.0 else "Der")
		contraluz.position = Vector3(lado * 4.6, 1.6, -3.4)
		contraluz.light_color = color
		contraluz.light_energy = 1.6
		contraluz.omni_range = 6.5
		anfitrion.add_child(contraluz)


static func material_suelo(color: Color, radio: float, radio_ritual: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_SUELO)
	material.set_shader_parameter("grabado", color)
	material.set_shader_parameter("radio", radio)
	material.set_shader_parameter("radio_ritual", radio_ritual)
	return material


## Un archivador de verdad: cuerpo, cuatro cajones con tirador, y en algunos el
## cajón de arriba abierto con papeles. [param indice] decide cuál, siempre
## igual para la misma posición.
static func archivador(indice: int, color: Color) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Archivador%d" % indice
	var metal := color
	_caja(raiz, Vector3(0.9, 1.8, 0.55), Vector3(0.0, 0.0, 0.0), metal)
	var abierto := indice % 3 == 1
	for cajon in 4:
		var y := 0.62 - float(cajon) * 0.42
		var sale := 0.22 if abierto and cajon == 0 else 0.0
		_caja(raiz, Vector3(0.8, 0.36, 0.04), Vector3(0.0, y, 0.29 + sale), metal.lightened(0.08))
		_caja(
			raiz,
			Vector3(0.22, 0.04, 0.05),
			Vector3(0.0, y + 0.08, 0.33 + sale),
			Color(0.62, 0.58, 0.48)
		)
		if sale > 0.0:
			for hoja in 3:
				_caja(
					raiz,
					Vector3(0.66, 0.012, 0.3),
					Vector3(0.0, y + 0.12 + float(hoja) * 0.03, 0.2 + float(hoja) * 0.02),
					Color(0.80, 0.77, 0.68)
				)
	# Dos de cada ocho, torcidos: el archivo del sueño no está en regla.
	if indice % 4 == 3:
		raiz.rotation.z = deg_to_rad(6.0 if indice % 8 == 3 else -5.0)
	return raiz


## Papeles y polvo flotando sobre la arena. Nada con reducción de movimiento.
static func montar_aire(anfitrion: Node3D, reducir: bool) -> void:
	if reducir:
		return
	var papeles := EfectosLigeros._emisor(PAPELES, 9.0, Vector2(0.16, 0.12))
	papeles.name = "PapelesJuicio"
	papeles.position = Vector3(0.0, 2.2, 0.0)
	var proceso := papeles.process_material as ParticleProcessMaterial
	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proceso.emission_box_extents = Vector3(5.5, 1.6, 5.5)
	proceso.direction = Vector3(0.2, -1.0, 0.1)
	proceso.spread = 35.0
	proceso.initial_velocity_min = 0.08
	proceso.initial_velocity_max = 0.22
	proceso.gravity = Vector3(0.0, -0.06, 0.0)
	proceso.angular_velocity_min = -40.0
	proceso.angular_velocity_max = 40.0
	proceso.turbulence_enabled = true
	proceso.turbulence_noise_strength = 0.5
	proceso.alpha_curve = EfectosLigeros._curva_aparece_y_se_va()
	EfectosLigeros._color(papeles, Color(0.86, 0.83, 0.74, 0.85))
	(papeles.draw_pass_1 as QuadMesh).material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	(papeles.draw_pass_1 as QuadMesh).material.cull_mode = BaseMaterial3D.CULL_DISABLED
	papeles.visibility_aabb = AABB(Vector3(-7, -3, -7), Vector3(14, 6, 14))
	anfitrion.add_child(papeles)

	var polvo := EfectosLigeros._emisor(POLVO, 7.0, Vector2(0.03, 0.03))
	polvo.name = "PolvoJuicio"
	polvo.position = Vector3(0.0, 2.4, 0.0)
	var proceso_polvo := polvo.process_material as ParticleProcessMaterial
	proceso_polvo.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proceso_polvo.emission_sphere_radius = 2.4
	proceso_polvo.gravity = Vector3(0.0, 0.01, 0.0)
	proceso_polvo.initial_velocity_min = 0.02
	proceso_polvo.initial_velocity_max = 0.06
	proceso_polvo.turbulence_enabled = true
	proceso_polvo.turbulence_noise_strength = 0.25
	proceso_polvo.alpha_curve = EfectosLigeros._curva_aparece_y_se_va()
	EfectosLigeros._color(polvo, Color(1.0, 0.93, 0.78, 0.5), true)
	polvo.visibility_aabb = AABB(Vector3(-4, -3, -4), Vector3(8, 6, 8))
	anfitrion.add_child(polvo)


## Halo del color del mito sobre las mallas de la silueta del rival, como
## segunda pasada: la silueta sigue sin cara y sin textura.
static func aplicar_halo(figura: Node3D, color: Color) -> int:
	var halo := ShaderMaterial.new()
	halo.shader = load(SHADER_HALO)
	halo.set_shader_parameter("color", color)
	var puestas := 0
	for nodo in figura.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		var base := malla.material_override
		if base != null:
			var copia := base.duplicate() as Material
			copia.next_pass = halo
			malla.material_override = copia
			puestas += 1
			continue
		for superficie in malla.mesh.get_surface_count():
			var propio := malla.get_surface_override_material(superficie)
			if propio != null and propio.next_pass == null:
				propio.next_pass = halo
				puestas += 1
	return puestas


## El cuerpo del jugador en la arena: el de su ficha, con los pies en el
## origen de [param padre] y mirando a +Z como el resto de figuras.
static func cuerpo_jugador(padre: Node3D, perfil: Dictionary) -> Node3D:
	var cuerpo := CuerpoJugador3D.new()
	cuerpo.name = "CuerpoJugador"
	cuerpo.primera_persona = false
	cuerpo.variar_reposo = false
	# En la arena lo mueve el Juicio por posición, sin velocidad física: si se
	# animara solo, cada fotograma volvería a respirar y pisaría andar y gestos.
	cuerpo.auto_animar = false
	cuerpo.perfil = PerfilJugador.completar(perfil)
	padre.add_child(cuerpo)
	return cuerpo


## El rival: un cuerpo humano sin cara, negro entero, con halo. Si el avatar no
## carga, vuelve la silueta de siempre: nunca un juicio sin rival.
static func rival_sin_cara(padre: Node3D, clave: String, color: Color) -> Node3D:
	var soporte := Node3D.new()
	soporte.name = "RivalSinCara"
	padre.add_child(soporte)
	var avatar := String(CUERPOS_RIVAL[absi(hash(clave)) % CUERPOS_RIVAL.size()])
	if not Modelos.persona(soporte, avatar, Color.WHITE, ""):
		soporte.free()
		var silueta := FiguraSilueta.construir(padre, Vector3.ZERO, Color(0.1, 0.1, 0.13))
		aplicar_halo(silueta, color)
		return silueta
	for nodo in soporte.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		for superficie in malla.mesh.get_surface_count():
			malla.set_surface_override_material(
				superficie, _material_silueta(malla.get_active_material(superficie))
			)
		malla.material_override = null
	aplicar_halo(soporte, color)
	return soporte


## Anda o se queda quieto según se mueva. Solo cambia el clip al cambiar de
## estado, no en cada fotograma.
static func andar(figura: Node3D, andando: bool) -> void:
	if figura == null:
		return
	# Un gesto de combate en curso manda; al acabar se vuelve a andar o respirar.
	if Time.get_ticks_msec() < int(figura.get_meta("gesto_hasta", 0)):
		return
	if figura.has_meta("gesto_hasta"):
		figura.remove_meta("gesto_hasta")
		figura.remove_meta("andando")
		if figura is CuerpoJugador3D:
			(figura as CuerpoJugador3D).estado = ""
	if figura.has_meta("andando") and bool(figura.get_meta("andando")) == andando:
		return
	figura.set_meta("andando", andando)
	if figura is CuerpoJugador3D:
		(figura as CuerpoJugador3D).animar(2.0 if andando else 0.0)
		return
	var pieza := _pieza(figura)
	if pieza != null:
		AnimacionesUAL.reproducir(pieza, "walk" if andando else "idle")


## Un gesto de combate (`discutir`, `encajar`, `celebrar`...) sobre la figura
## del jugador o del rival. Dura lo que dura el clip; mientras, `andar` no lo
## pisa. Devuelve cuántos segundos dura de verdad (0 si no había clip).
##
## El reproductor puede venir acelerado de andar (`CuerpoJugador3D.animar`
## escala el paso a la velocidad): el gesto va a su ritmo, y el bloqueo se mide
## con la velocidad efectiva, no con la duración nominal, o se quedaría
## congelado en su última pose hasta que venciera el bloqueo.
static func gesto(figura: Node3D, clip: String) -> float:
	var pieza := _pieza(figura)
	if pieza == null or not AnimacionesUAL.reproducir(pieza, clip):
		return 0.0
	var reproductor := Modelos._reproductor(pieza)
	var segundos := 1.0
	if reproductor != null:
		reproductor.speed_scale = 1.0
		segundos = (
			reproductor.current_animation_length / maxf(absf(reproductor.get_playing_speed()), 0.01)
		)
	figura.set_meta("gesto_hasta", Time.get_ticks_msec() + int(segundos * 1000.0))
	return segundos


static func _pieza(figura: Node3D) -> Node3D:
	if figura is CuerpoJugador3D:
		return (figura as CuerpoJugador3D).figura()
	if figura != null and figura.get_child_count() > 0 and figura.get_child(0) is Node3D:
		return figura.get_child(0)
	return null


## Negro mate y sin textura, salvo el recorte de las superficies con opacidad
## (pelo, pestañas): sin él, el pelo serían tarjetas negras cuadradas.
static func _material_silueta(original: Material) -> Material:
	var negro := StandardMaterial3D.new()
	negro.albedo_color = NEGRO_SILUETA
	negro.roughness = 1.0
	negro.metallic_specular = 0.0
	var base := original as BaseMaterial3D
	if base != null and base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		negro.albedo_texture = base.albedo_texture
		negro.albedo_color = Color(0.0, 0.0, 0.0, 1.0)
		negro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		negro.alpha_scissor_threshold = 0.5
	return negro


static func _caja(
	padre: Node3D, tamano: Vector3, posicion: Vector3, color: Color
) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	pieza.mesh = malla
	pieza.position = posicion
	pieza.material_override = JuicioCombateFeedback3D.material(color)
	padre.add_child(pieza)
	return pieza
