## Cuerpo visual del protagonista para primera persona.
##
## Es la misma figura que los compañeros —`persona.fbx`, vestida por el pase de
## #275 y animada con UAL— para que mirar hacia abajo revele a una persona del
## mismo mundo y no a un maniquí de cajas. Sigue siendo deliberadamente visual:
## no crea colisiones ni cambia la escala del caminante. El perfil lo entrega
## quien ya tiene la partida cargada (`DiaApp`): este nodo no lee ni escribe
## guardados.
class_name CuerpoJugador3D
extends Node3D

## Por encima, se corre (VELOCIDAD 2.6 anda; VELOCIDAD_CORRER 4.4 corre).
const UMBRAL_ANDAR := 0.25
const UMBRAL_CORRER := 3.4
## Velocidad a la que `Walk_Formal` de UAL pisa sin patinar.
const PASO_ANDAR := 1.4
## Los pies van al suelo de la cápsula (alto 1.7 centrada en el origen). El
## cuello queda bajo la cámara (1.50 m): cuello y cabeza se ocultan y el cuerpo
## se retrasa para que, al mirar abajo, se vean brazos, manos y piernas y no la
## parte alta de los hombros desde dentro. Se comparó en captura con ocultar
## todo el torso: dejaba un muñón puntiagudo bajo la cámara.
const PIES_Y := -0.85
const RETRASO_Z := 0.26
## A escala 1 el cuello queda 12 cm bajo la cámara y los hombros llenan la vista
## al mirar abajo. Un 6 % menos deja aire sin que los pies se separen del suelo.
const ESCALA_BASE := 0.94
## La cámara agachada baja 0.35 m: el cuerpo baja lo mismo para no atravesarla.
const BAJADA_AGACHADO := -0.35
const IDENTIDAD := "jugador"

var perfil: Dictionary = {}
var estado := ""

var _camara: Camera3D
var _figura: Node3D
var _reproductor: AnimationPlayer


## Encoge el hueso `Neck` (y con él la cabeza) después de cada animación. La
## cámara vive donde estaría la cabeza: sin esto, el interior del cráneo y el
## cuello tapan la vista al girar.
class OcultarCabeza:
	extends SkeletonModifier3D

	func _process_modification() -> void:
		var esqueleto := get_skeleton()
		var cuello := esqueleto.find_bone("Neck") if esqueleto != null else -1
		if cuello >= 0:
			esqueleto.set_bone_pose_scale(cuello, Vector3.ONE * 0.001)


func _ready() -> void:
	_camara = get_parent().get_node_or_null("Camara") as Camera3D
	# Sin perfil previo se monta el cuerpo por defecto de PerfilJugador.
	aplicar(perfil)


func aplicar(valor: Dictionary) -> void:
	perfil = PerfilJugador.completar(valor)
	for hijo in get_children():
		remove_child(hijo)
		hijo.queue_free()
	_figura = null
	_reproductor = null
	estado = ""
	_construir()


func figura() -> Node3D:
	return _figura


func _process(delta: float) -> void:
	if _figura == null:
		return
	var objetivo := BAJADA_AGACHADO if _camara != null and _camara.position.y < 0.5 else 0.0
	position.y = lerpf(position.y, objetivo, minf(1.0, delta * 12.0))
	var cuerpo := get_parent() as CharacterBody3D
	var velocidad := Vector2(cuerpo.velocity.x, cuerpo.velocity.z).length() if cuerpo else 0.0
	animar(velocidad)


## Elige el gesto según la velocidad horizontal. Solo reinicia la animación
## cuando cambia de estado; al andar, ajusta el ritmo para que no patine.
func animar(velocidad: float) -> void:
	var nuevo := "reposo"
	if velocidad >= UMBRAL_CORRER:
		nuevo = "correr"
	elif velocidad >= UMBRAL_ANDAR:
		nuevo = "andar"
	if nuevo != estado:
		estado = nuevo
		match nuevo:
			"andar":
				if not AnimacionesUAL.reproducir(_figura, "andar"):
					Modelos._animar(_figura, "walk")
			"correr":
				Modelos._animar(_figura, "run")
			_:
				Modelos._animar(_figura, "idle")
	if _reproductor != null:
		_reproductor.speed_scale = (
			clampf(velocidad / PASO_ANDAR, 0.6, 2.0) if estado == "andar" else 1.0
		)


func _construir() -> void:
	var apariencia: Dictionary = perfil["apariencia"]
	var piel := Color.from_string(String(apariencia["piel"]), Color("c9916b"))
	var ropa := Color.from_string(String(apariencia["ropa"]), Color("59616b"))

	var soporte := Node3D.new()
	soporte.name = "Figura"
	# persona.fbx mira a +Z; el caminante, a -Z.
	soporte.rotation.y = PI
	soporte.position = Vector3(0.0, PIES_Y, RETRASO_Z)
	var altura := float(apariencia["altura"])
	soporte.scale = Vector3.ONE * ESCALA_BASE * altura
	add_child(soporte)

	# Como en la oficina, el maniquí se tiñe del color de la ropa y el vestuario
	# pone encima chaqueta más oscura y camisa más clara.
	if not Modelos.persona(soporte, "persona", ropa):
		return
	_figura = soporte.get_child(0) as Node3D
	_reproductor = Modelos._reproductor(_figura)
	var esqueleto := Modelos._esqueleto(_figura)
	if esqueleto == null:
		return

	var vestuario := get_node_or_null("/root/VestuarioHumano3D")
	if vestuario != null:
		vestuario.vestir(_figura, PerfilJugador.perfil_vestuario(apariencia), ropa, IDENTIDAD)
		# La hombrera queda a la altura de la cámara: desde dentro es una losa.
		var hombros := esqueleto.find_child("VestuarioHombros", true, false) as Node3D
		if hombros != null:
			hombros.visible = false
	else:
		# Sin el autoload (una escena suelta) se marca igual: nadie más la viste.
		esqueleto.set_meta("vestuario_identidad_275", IDENTIDAD)

	var oculta := OcultarCabeza.new()
	oculta.name = "OcultarCabeza"
	esqueleto.add_child(oculta)

	for hueso in ["LeftHand", "RightHand"]:
		_mano(esqueleto, hueso, piel)
	animar(0.0)


## Las manos son lo que más se ve en primera persona: van en su tono de piel.
func _mano(esqueleto: Skeleton3D, hueso: String, piel: Color) -> void:
	var indice := esqueleto.find_bone(hueso)
	if indice < 0:
		return
	var enganche := BoneAttachment3D.new()
	enganche.name = "Mano" + hueso
	enganche.bone_name = hueso
	esqueleto.add_child(enganche)
	var malla := BoxMesh.new()
	# El esqueleto va escalado dentro del fbx: el tamaño se expresa en metros
	# del mundo y se deshace la escala acumulada del hueso.
	var escala := esqueleto.global_transform.basis.get_scale().x
	malla.size = Vector3(0.085, 0.11, 0.04) / maxf(escala, 0.0001)
	var instancia := MeshInstance3D.new()
	instancia.name = "Piel"
	instancia.mesh = malla
	instancia.position = Vector3(0.0, 0.05, 0.0) / maxf(escala, 0.0001)
	var material := ShaderMaterial.new()
	material.shader = load("res://arte/psx.gdshader")
	material.set_shader_parameter("color_base", piel)
	instancia.material_override = material
	enganche.add_child(instancia)
