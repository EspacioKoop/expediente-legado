## Un cigarro encendido, con su cenicero.
##
## En 1998 se fumaba en la oficina, y eso no es un adorno: es la diferencia
## entre un sitio de trabajo de entonces y uno de ahora, y se cuenta sin decir
## una palabra. El cenicero lleno dice cuánto llevas ahí.
##
## Son tres cosas: la brasa (que ADEMÁS ilumina un poco, porque una brasa que
## no da luz es un punto naranja pintado), el humo, y el cenicero. El humo va
## en `CPUParticles3D` y no en GPU: el juego corre en el renderizador de
## compatibilidad, que es el que hace que esto se vea en cualquier máquina, y
## ahí lo que siempre funciona es la CPU.
class_name Cigarro
extends RefCounted

const COLOR_BRASA := Color(1.0, 0.42, 0.12)
const COLOR_CENICERO := Color(0.24, 0.23, 0.22)
const COLOR_PAPEL := Color(0.88, 0.86, 0.80)
const COLOR_HUMO := Color(0.72, 0.72, 0.70, 0.16)


static func construir(raiz: Node3D, base: Vector3) -> Node3D:
	var todo := Node3D.new()
	todo.position = base
	raiz.add_child(todo)

	_pieza(todo, Vector3(0, 0.015, 0), Vector3(0.16, 0.03, 0.16), COLOR_CENICERO)
	# El cigarro, apoyado en el borde y saliendo un poco: si estuviera dentro
	# del cenicero sería una colilla, y una colilla no humea.
	_pieza(todo, Vector3(0.05, 0.045, 0), Vector3(0.14, 0.012, 0.012), COLOR_PAPEL)

	var brasa := _pieza(todo, Vector3(0.115, 0.045, 0), Vector3(0.016, 0.016, 0.016), COLOR_BRASA)
	var material: StandardMaterial3D = brasa.material_override
	material.emission_enabled = true
	material.emission = COLOR_BRASA
	material.emission_energy_multiplier = 2.5

	var luz := OmniLight3D.new()
	luz.position = Vector3(0.115, 0.05, 0)
	luz.light_color = COLOR_BRASA
	luz.light_energy = 0.35
	luz.omni_range = 1.1
	luz.shadow_enabled = false
	todo.add_child(luz)

	todo.add_child(_humo(Vector3(0.115, 0.06, 0)))
	return todo


static func _pieza(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	malla.material_override = material
	raiz.add_child(malla)
	return malla


## El humo. Poco, lento y transparente: una columna espesa se lee como fuego, y
## lo que se busca es el hilo que sube de un cigarro olvidado en el borde.
static func _humo(pos: Vector3) -> CPUParticles3D:
	var humo := CPUParticles3D.new()
	humo.position = pos
	humo.amount = 14
	humo.lifetime = 3.4
	humo.explosiveness = 0.0
	humo.direction = Vector3.UP
	humo.spread = 6.0
	humo.initial_velocity_min = 0.12
	humo.initial_velocity_max = 0.22
	humo.gravity = Vector3(0.02, 0.05, 0)
	humo.scale_amount_min = 0.5
	humo.scale_amount_max = 2.2
	humo.color = COLOR_HUMO

	var malla := QuadMesh.new()
	malla.size = Vector2(0.16, 0.16)

	# El material va en la MALLA y no en `material_override` del emisor: puesto
	# en el emisor, Godot pinta el cuadro con el material por defecto y lo que
	# se ve es un cartón negro de medio metro apoyado en la mesa. Es el fallo
	# que enseñó la primera captura.
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = COLOR_HUMO
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	malla.material = material

	humo.mesh = malla
	return humo
