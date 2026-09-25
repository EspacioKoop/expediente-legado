## Partículas y líquidos ligeros de ambiente: vapor del café, polvo en la luz,
## charcos con ondas y gotas en las ventanas.
##
## Todos con presupuesto cerrado —un puñado de partículas por fuente y un tope
## de fuentes por espacio, o un shader sin partículas— porque su trabajo es que
## el sitio respire, no llevarse el fotograma: la lluvia exterior ya gasta hasta
## 1450 partículas y esto no puede ser otra lluvia.
##
## No se cuelga de cada escena: recorre el espacio YA montado y busca lo que
## tiene sentido adornar (las tazas `TazaPuesto` y `TazaServida`, las luces de
## interior, el cristal `CristalVista3D`, el suelo de la calle). El vapor va
## colgado de su taza —aparece y desaparece con ella— y las gotas de su cristal,
## que en casa se monta un fotograma después de entrar: por eso se buscan un
## rato más con un temporizador. Así un espacio nuevo gana los efectos
## sin tocar este módulo, y este módulo no conoce ninguna sala por su nombre.
##
## Con reducción de movimiento el polvo y el vapor no se montan y las ondas y
## gotas se quedan quietas: el charco y el cristal mojado siguen diciendo que
## llueve.
class_name EfectosLigeros
extends RefCounted

const NOMBRE := "EfectosLigeros"
const SHADER_CHARCO := "res://arte/charco_ondas.gdshader"
const SHADER_GOTAS := "res://arte/gotas_cristal.gdshader"

const PARTICULAS_VAPOR := 10
const MAX_TAZAS := 8
const PARTICULAS_POLVO := 24
const MAX_LUCES_POLVO := 3
## Por debajo de esta energía una luz no «dibuja» haz en el aire.
const ENERGIA_MINIMA_POLVO := 0.6
const CHARCOS := 7
## Suelo jugable de la calle (9 x 34, #399): los charcos no salen de él.
const SUELO_CALLE := Rect2(-4.0, -16.0, 8.0, 32.0)
const ALTURA_CHARCO := 0.035
const NOMBRE_VAPOR := "VaporLigero"
## Cuántas veces y cada cuánto se vuelve a buscar un cristal que aún no está.
const REINTENTOS_CRISTAL := 20
const PAUSA_CRISTAL := 0.5


## Monta los efectos que tocan en [param mundo] para [param fase] con el tiempo
## [param clima]. Devuelve el nodo que los agrupa (o nulo si no hay ninguno);
## rehacer la fase lo sustituye.
static func montar(
	mundo: Node3D, fase: String, clima: String, reducir: bool, exterior: bool = false
) -> Node3D:
	if mundo == null:
		return null
	var previo := mundo.get_node_or_null(NOMBRE)
	if previo != null:
		previo.free()
	var raiz := Node3D.new()
	raiz.name = NOMBRE
	mundo.add_child(raiz)
	var llueve := clima == Clima.LLUVIA
	if not reducir:
		_vapor(mundo)
		# El polvo flota en el aire quieto de un interior; fuera, con lluvia o
		# viento, sería otra precipitación.
		if not exterior:
			_polvo(mundo, raiz)
	if llueve and fase == "trayecto":
		_charcos(raiz, reducir)
	if llueve:
		mojar_cristales(mundo, reducir)
		_seguir_mojando(mundo, raiz, reducir)
	if raiz.get_child_count() == 0:
		raiz.free()
		return null
	return raiz


## Cuántas partículas vivas hay como mucho bajo [param raiz]: el presupuesto
## que las pruebas vigilan.
static func particulas_totales(raiz: Node) -> int:
	var total := 0
	if raiz == null:
		return 0
	for nodo in raiz.find_children("*", "GPUParticles3D", true, false):
		total += (nodo as GPUParticles3D).amount
	return total


# --- Vapor -------------------------------------------------------------------


static func _vapor(mundo: Node3D) -> void:
	var tazas := mundo.find_children("TazaPuesto", "MeshInstance3D", true, false)
	tazas.append_array(mundo.find_children("TazaServida", "MeshInstance3D", true, false))
	for i in mini(tazas.size(), MAX_TAZAS):
		var taza: MeshInstance3D = tazas[i]
		var previo := taza.get_node_or_null(NOMBRE_VAPOR)
		if previo != null:
			previo.free()
		var vapor := _emisor(PARTICULAS_VAPOR, 2.4, Vector2(0.05, 0.05))
		vapor.name = NOMBRE_VAPOR
		vapor.position = Vector3(0, 0.14, 0)
		var proceso := vapor.process_material as ParticleProcessMaterial
		proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		proceso.emission_sphere_radius = 0.025
		proceso.direction = Vector3.UP
		proceso.spread = 12.0
		proceso.initial_velocity_min = 0.05
		proceso.initial_velocity_max = 0.09
		proceso.gravity = Vector3(0.0, 0.015, 0.0)
		proceso.scale_min = 0.8
		proceso.scale_max = 2.2
		proceso.turbulence_enabled = true
		proceso.turbulence_noise_strength = 0.4
		proceso.turbulence_noise_scale = 3.0
		proceso.alpha_curve = _curva_aparece_y_se_va()
		_color(vapor, Color(0.95, 0.95, 0.92, 0.22))
		vapor.visibility_aabb = AABB(Vector3(-0.2, 0.0, -0.2), Vector3(0.4, 0.5, 0.4))
		taza.add_child(vapor)


# --- Polvo ---------------------------------------------------------------------


static func _polvo(mundo: Node3D, raiz: Node3D) -> void:
	var luces := []
	for nodo in mundo.find_children("*", "Light3D", true, false):
		if nodo is DirectionalLight3D or raiz.is_ancestor_of(nodo):
			continue
		if (nodo as Light3D).light_energy >= ENERGIA_MINIMA_POLVO:
			luces.append(nodo)
	# Los focos primero: son los que dibujan un haz; después las puntuales.
	luces.sort_custom(func(a, b): return a is SpotLight3D and not b is SpotLight3D)
	for i in mini(luces.size(), MAX_LUCES_POLVO):
		var luz: Light3D = luces[i]
		var polvo := _emisor(PARTICULAS_POLVO, 9.0, Vector2(0.012, 0.012))
		polvo.name = "Polvo%d" % i
		polvo.position = raiz.to_local(luz.global_position) + Vector3(0, -0.9, 0)
		var proceso := polvo.process_material as ParticleProcessMaterial
		proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		proceso.emission_box_extents = Vector3(0.7, 0.6, 0.7)
		proceso.direction = Vector3.UP
		proceso.spread = 180.0
		proceso.initial_velocity_min = 0.005
		proceso.initial_velocity_max = 0.02
		proceso.gravity = Vector3(0.0, -0.003, 0.0)
		proceso.turbulence_enabled = true
		proceso.turbulence_noise_strength = 0.15
		proceso.alpha_curve = _curva_aparece_y_se_va()
		_color(polvo, Color(1.0, 0.95, 0.82, 0.55), true)
		polvo.visibility_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
		raiz.add_child(polvo)


# --- Charcos y gotas: shader, sin partículas ------------------------------------


## Posiciones y tamaños deterministas: la misma calle moja igual cada día de
## lluvia, que es lo que hace que un charco se reconozca.
static func sitios_charcos() -> Array:
	var sitios := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1998
	for i in CHARCOS:
		var centro := Vector2(
			rng.randf_range(SUELO_CALLE.position.x + 0.6, SUELO_CALLE.end.x - 0.6),
			rng.randf_range(SUELO_CALLE.position.y + 1.0, SUELO_CALLE.end.y - 1.0)
		)
		var tamano := Vector2(rng.randf_range(0.7, 1.6), rng.randf_range(0.5, 1.1))
		sitios.append({"centro": centro, "tamano": tamano, "fase": rng.randf() * TAU})
	return sitios


static func _charcos(raiz: Node3D, reducir: bool) -> void:
	var shader: Shader = load(SHADER_CHARCO)
	for i in CHARCOS:
		var sitio: Dictionary = sitios_charcos()[i]
		var charco := MeshInstance3D.new()
		charco.name = "Charco%d" % i
		var plano := PlaneMesh.new()
		plano.size = sitio["tamano"]
		charco.mesh = plano
		charco.position = Vector3(sitio["centro"].x, ALTURA_CHARCO, sitio["centro"].y)
		charco.rotation.y = float(sitio["fase"])
		charco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("desfase", float(sitio["fase"]))
		material.set_shader_parameter("velocidad", 0.0 if reducir else 1.0)
		charco.material_override = material
		raiz.add_child(charco)


## Moja los cristales de [param mundo] que aún no lo estén. Devuelve cuántos.
static func mojar_cristales(mundo: Node3D, reducir: bool) -> int:
	if not is_instance_valid(mundo):
		return 0
	var shader: Shader = load(SHADER_GOTAS)
	var mojados := 0
	var cristales := mundo.find_children("CristalVista3D", "MeshInstance3D", true, false)
	for i in cristales.size():
		var cristal: MeshInstance3D = cristales[i]
		if not (cristal.mesh is QuadMesh) or cristal.get_node_or_null("Gotas") != null:
			continue
		mojados += 1
		var gotas := MeshInstance3D.new()
		gotas.name = "Gotas"
		var quad := QuadMesh.new()
		quad.size = (cristal.mesh as QuadMesh).size
		gotas.mesh = quad
		gotas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("velocidad", 0.0 if reducir else 1.0)
		gotas.material_override = material
		# Va con el cristal, unos milímetros por delante, para heredar su giro y
		# desaparecer con él cuando la fase se desmonta.
		cristal.add_child(gotas)
		gotas.position = Vector3(0, 0, 0.004)
	return mojados


## La ventana de casa monta su cristal después de entrar en la fase: se vuelve a
## mirar unas pocas veces y se deja de mirar. Diez segundos, nunca un bucle.
static func _seguir_mojando(mundo: Node3D, raiz: Node3D, reducir: bool) -> void:
	var reloj := Timer.new()
	reloj.name = "MojarCristales"
	reloj.wait_time = PAUSA_CRISTAL
	raiz.add_child(reloj)
	var intentos := [0]
	reloj.timeout.connect(
		func():
			mojar_cristales(mundo, reducir)
			intentos[0] += 1
			if intentos[0] >= REINTENTOS_CRISTAL:
				reloj.stop()
	)
	if reloj.is_inside_tree():
		reloj.start()
	else:
		reloj.autostart = true


# --- Comunes -------------------------------------------------------------------


static func _emisor(cantidad: int, vida: float, tamano: Vector2) -> GPUParticles3D:
	var emisor := GPUParticles3D.new()
	emisor.amount = cantidad
	emisor.lifetime = vida
	emisor.preprocess = vida
	emisor.local_coords = false
	emisor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emisor.process_material = ParticleProcessMaterial.new()
	var malla := QuadMesh.new()
	malla.size = tamano
	emisor.draw_pass_1 = malla
	return emisor


static func _color(emisor: GPUParticles3D, color: Color, aditivo: bool = false) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	if aditivo:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	(emisor.draw_pass_1 as QuadMesh).material = material


static func _curva_aparece_y_se_va() -> CurveTexture:
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.0))
	curva.add_point(Vector2(0.25, 1.0))
	curva.add_point(Vector2(0.7, 0.8))
	curva.add_point(Vector2(1.0, 0.0))
	var textura := CurveTexture.new()
	textura.curve = curva
	return textura
