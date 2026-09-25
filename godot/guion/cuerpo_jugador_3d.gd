## Cuerpo visual del protagonista para primera persona y previsualización.
##
## El protagonista conserva temporalmente el rig configurable `persona.fbx`,
## vestido por el pase de #275 y animado con UAL. Los compañeros de oficina ya
## usan Rocketbox desde #1320; aquí se mantiene el rig legacy porque la ficha
## necesita variar complexión, piel, pelo y ropa en vivo. Sigue siendo
## deliberadamente visual: no crea colisiones ni cambia la escala del caminante.
## El perfil lo entrega quien ya tiene la partida cargada (`DiaApp`) o el editor:
## este nodo no lee ni escribe guardados.
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
const SHADER_PSX := preload("res://arte/psx.gdshader")

## En juego se mantiene el recorte específico de primera persona. El creador lo
## pone a `false`: la figura nace apoyada en el suelo, mirando a cámara y con una
## cabeza/pelo procedurales que reflejan la ficha.
@export var primera_persona := true

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
	var objetivo := 0.0
	if primera_persona and _camara != null and _camara.position.y < 0.5:
		objetivo = BAJADA_AGACHADO
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
	var cabello := Color.from_string(String(apariencia["cabello"]), Color("30251f"))
	var ropa := Color.from_string(String(apariencia["ropa"]), Color("59616b"))
	# La malla histórica es solo un underlay: la piel visible se pinta aparte.
	var bajo_ropa := ropa.darkened(0.32)

	var soporte := Node3D.new()
	soporte.name = "Figura"
	# persona.fbx mira a +Z; el caminante, a -Z. En el editor se conserva +Z
	# porque la cámara de ficha está delante del personaje.
	soporte.rotation.y = PI if primera_persona else 0.0
	soporte.position = Vector3(0.0, PIES_Y, RETRASO_Z) if primera_persona else Vector3.ZERO
	var altura := float(apariencia["altura"])
	var escala_modo := ESCALA_BASE if primera_persona else 1.0
	soporte.scale = Vector3.ONE * escala_modo * altura
	add_child(soporte)

	# `persona.fbx` queda como underlay oscuro para pantalón/sombras. La ropa real
	# la aporta VestuarioHumano3D y la piel visible (cabeza, cuello y manos) se
	# pinta explícitamente con `piel`, evitando que el color de ropa llegue a la cara.
	if not Modelos.persona(soporte, "persona", bajo_ropa):
		return
	_figura = soporte.get_child(0) as Node3D
	_reproductor = Modelos._reproductor(_figura)
	var esqueleto := Modelos._esqueleto(_figura)
	if esqueleto == null:
		return

	var vestuario := get_node_or_null("/root/VestuarioHumano3D")
	if vestuario != null:
		vestuario.vestir(_figura, PerfilJugador.perfil_vestuario(apariencia), ropa, IDENTIDAD)
		if primera_persona:
			# La hombrera queda a la altura de la cámara: desde dentro es una losa.
			var hombros := esqueleto.find_child("VestuarioHombros", true, false) as Node3D
			if hombros != null:
				hombros.visible = false
	else:
		# Sin el autoload (una escena suelta) se marca igual: nadie más la viste.
		esqueleto.set_meta("vestuario_identidad_275", IDENTIDAD)

	if primera_persona:
		var oculta := OcultarCabeza.new()
		oculta.name = "OcultarCabeza"
		esqueleto.add_child(oculta)
	else:
		_rostro_exterior(esqueleto, piel, cabello, String(apariencia["peinado"]))

	for hueso in ["LeftHand", "RightHand"]:
		_mano(esqueleto, hueso, piel)
	animar(0.0)


## Cabeza low-poly para la ficha y futuras vistas exteriores. No sustituye al
## rig ni al asset: envuelve la cabeza importada igual que los rostros 3D del
## roster, usa el shader PSX común y sigue el hueso `Head`. Los cuatro peinados
## se distinguen por silueta, de modo que piel/cabello/peinado también son
## legibles en la previsualización y no solo datos persistidos.
func _rostro_exterior(esqueleto: Skeleton3D, piel: Color, cabello: Color, peinado: String) -> void:
	var cabeza := esqueleto.find_bone("Head")
	if cabeza < 0:
		return
	var coronilla := esqueleto.find_bone("HeadTop_End")
	var alto := 0.012
	if coronilla >= 0:
		alto = maxf(
			absf(
				(
					esqueleto.get_bone_global_pose(coronilla).origin.y
					- esqueleto.get_bone_global_pose(cabeza).origin.y
				)
			),
			alto,
		)

	var enganche := BoneAttachment3D.new()
	enganche.name = "RostroJugador"
	enganche.bone_idx = cabeza
	esqueleto.add_child(enganche)

	var radio_x := alto * 0.35
	var radio_y := alto * 0.50
	var radio_z := alto * 0.39
	var centro_y := alto * 0.48

	# La cabeza procedural ya cubría el cráneo, pero el cuello importado seguía
	# heredando el color del underlay. Se añade una pieza de piel independiente
	# anclada al hueso Neck para que la ficha se lea como una persona coherente.
	var cuello := esqueleto.find_bone("Neck")
	if cuello >= 0:
		var enganche_cuello := BoneAttachment3D.new()
		enganche_cuello.name = "PielCuelloJugador"
		enganche_cuello.bone_idx = cuello
		esqueleto.add_child(enganche_cuello)
		_esfera_psx(
			enganche_cuello,
			"PielCuello",
			Vector3(0.0, alto * 0.035, 0.0),
			Vector3(alto * 0.19, alto * 0.18, alto * 0.17),
			piel,
			6,
			4,
		)

	_esfera_psx(
		enganche,
		"PielCabeza",
		Vector3(0.0, centro_y, 0.0),
		Vector3(radio_x, radio_y, radio_z),
		piel,
		8,
		5,
	)

	var pelo_y := centro_y + radio_y * 0.74
	var pelo_escala := Vector3(radio_x * 1.04, alto * 0.15, radio_z * 0.90)
	match peinado:
		"rapado":
			pelo_y = centro_y + radio_y * 0.82
			pelo_escala = Vector3(radio_x * 1.01, alto * 0.055, radio_z * 0.86)
		"medio":
			pelo_y = centro_y + radio_y * 0.69
			pelo_escala = Vector3(radio_x * 1.08, alto * 0.21, radio_z * 0.98)
		"recogido":
			pelo_y = centro_y + radio_y * 0.78
			pelo_escala = Vector3(radio_x * 0.98, alto * 0.11, radio_z * 0.84)
		_:
			pass
	_esfera_psx(
		enganche, "Cabello", Vector3(0.0, pelo_y, -radio_z * 0.04), pelo_escala, cabello, 8, 4
	)
	if peinado == "recogido":
		_esfera_psx(
			enganche,
			"Recogido",
			Vector3(0.0, centro_y + radio_y * 0.55, -radio_z * 0.82),
			Vector3(alto * 0.13, alto * 0.16, alto * 0.13),
			cabello,
			6,
			4,
		)


func _esfera_psx(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	escala: Vector3,
	color: Color,
	segmentos: int,
	anillos: int,
) -> void:
	var instancia := MeshInstance3D.new()
	instancia.name = nombre
	var malla := SphereMesh.new()
	malla.radius = 1.0
	malla.height = 2.0
	malla.radial_segments = segmentos
	malla.rings = anillos
	instancia.mesh = malla
	instancia.position = posicion
	instancia.scale = escala
	var material := ShaderMaterial.new()
	material.shader = SHADER_PSX
	material.set_shader_parameter("color_base", color)
	instancia.material_override = material
	padre.add_child(instancia)


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
	material.shader = SHADER_PSX
	material.set_shader_parameter("color_base", piel)
	instancia.material_override = material
	enganche.add_child(instancia)
