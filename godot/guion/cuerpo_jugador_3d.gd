## Cuerpo visual del protagonista para primera persona y previsualización.
##
## Es el avatar Rocketbox que elige la ficha (`PerfilJugador.AVATARES`), con
## los mismos clips de captura que la oficina (#1319). Hasta aquí era el rig
## configurable `persona.fbx` vestido por código, con cabeza y manos de
## esferas: el único personaje del juego con peor aspecto que cualquier NPC.
## Sigue siendo deliberadamente visual: no crea colisiones ni cambia la escala
## del caminante. El perfil lo entrega quien ya tiene la partida cargada
## (`DiaApp`) o el editor: este nodo no lee ni escribe guardados.
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
## Tras este rato quieto, un gesto de alguien que espera: mirar alrededor,
## rascarse, estirarse... Sin ellos, respirar en bucle delata al maniquí.
const PAUSA_VARIANTE := 9.0
## Con estrés alto se nota en el cuerpo; al final del día, el cansancio.
const UMBRAL_NERVIOSO := 0.6
const HORA_CANSADO := 18 * 60
const VARIANTES := {
	"": ["mirar_alrededor", "esperar", "rascarse", "estirarse"],
	"nervioso": ["nervioso", "mirar_alrededor", "nervioso", "rascarse"],
	"cansado": ["bostezar", "estirarse", "esperar", "bostezar"],
}

## En juego se mantiene el recorte específico de primera persona. El creador lo
## pone a `false`: la figura nace apoyada en el suelo, mirando a cámara y con una
## cabeza/pelo procedurales que reflejan la ficha.
@export var primera_persona := true
## El Juicio lo apaga: ahí los gestos son del combate, no de la espera.
@export var variar_reposo := true
## Si se anima solo con la velocidad del CharacterBody3D padre. El Juicio lo
## apaga porque mueve al jugador por posición y decide él cuándo anda.
@export var auto_animar := true

var perfil: Dictionary = {}
var estado := ""
## "", "nervioso" o "cansado": lo fija quien conoce la jornada (`DiaApp`).
var animo := ""

var _camara: Camera3D
var _figura: Node3D
var _reproductor: AnimationPlayer
var _quieto := 0.0
var _variante_restante := 0.0
var _variantes_hechas := 0


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
	if not auto_animar:
		return
	var velocidad := Vector2(cuerpo.velocity.x, cuerpo.velocity.z).length() if cuerpo else 0.0
	_variar_reposo(delta, velocidad)
	animar(velocidad)


## El ánimo que se le ve al cuerpo con este estrés (0-1) y esta hora del día.
static func animo_de(estres: float, hora_minutos: int) -> String:
	if estres >= UMBRAL_NERVIOSO:
		return "nervioso"
	if hora_minutos >= HORA_CANSADO:
		return "cansado"
	return ""


## El gesto número [param n] de la espera con este [param animo_actual].
static func variante_reposo(animo_actual: String, n: int) -> String:
	var lista: Array = VARIANTES.get(animo_actual, VARIANTES[""])
	return String(lista[n % lista.size()])


func _variar_reposo(delta: float, velocidad: float) -> void:
	if not variar_reposo or _figura == null or velocidad >= UMBRAL_ANDAR:
		_quieto = 0.0
		_variante_restante = 0.0
		return
	if _variante_restante > 0.0:
		_variante_restante -= delta
		if _variante_restante <= 0.0:
			# Vacío fuerza a `animar` a volver a respirar.
			estado = ""
		return
	_quieto += delta
	if _quieto < PAUSA_VARIANTE:
		return
	_quieto = 0.0
	var clip := variante_reposo(animo, _variantes_hechas)
	_variantes_hechas += 1
	if AnimacionesUAL.reproducir(_figura, clip) and _reproductor != null:
		_variante_restante = _reproductor.current_animation_length


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
				if not AnimacionesUAL.reproducir(_figura, "run"):
					Modelos._animar(_figura, "run")
			_:
				if not AnimacionesUAL.reproducir(_figura, "idle"):
					Modelos._animar(_figura, "idle")
	if _reproductor != null:
		_reproductor.speed_scale = (
			clampf(velocidad / PASO_ANDAR, 0.6, 2.0) if estado == "andar" else 1.0
		)


func _construir() -> void:
	var apariencia: Dictionary = perfil["apariencia"]
	var soporte := Node3D.new()
	soporte.name = "Figura"
	# Los avatares miran a +Z; el caminante, a -Z. En el editor se conserva +Z
	# porque la cámara de ficha está delante del personaje.
	soporte.rotation.y = PI if primera_persona else 0.0
	soporte.position = Vector3(0.0, PIES_Y, RETRASO_Z) if primera_persona else Vector3.ZERO
	var altura := float(apariencia["altura"])
	var escala_modo := ESCALA_BASE if primera_persona else 1.0
	soporte.scale = Vector3.ONE * escala_modo * altura
	add_child(soporte)

	if not Modelos.persona(soporte, String(apariencia["avatar"]), Color.WHITE, ""):
		return
	_figura = soporte.get_child(0) as Node3D
	_reproductor = Modelos._reproductor(_figura)
	var esqueleto := Modelos._esqueleto(_figura)
	if esqueleto == null:
		return
	esqueleto.set_meta("identidad_jugador", IDENTIDAD)
	if primera_persona:
		var oculta := OcultarCabeza.new()
		oculta.name = "OcultarCabeza"
		esqueleto.add_child(oculta)
	animar(0.0)
