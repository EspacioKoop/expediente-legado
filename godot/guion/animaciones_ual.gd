## Gestos de oficina de la Universal Animation Library de Quaternius (CC0).
##
## `persona.fbx` solo sabe respirar, andar, correr y teclear. UAL 1 y 2 traen
## lo que una oficina hace de verdad —hablar por teléfono, sentarse, conversar,
## cruzarse de brazos— pero sobre otro esqueleto (el maniquí de Unreal, `pelvis`, `upperarm_l`).
##
## No se reimporta `persona.fbx`: caras (#275) y vestuario cuelgan de sus huesos
## por nombre (`Head`, `HeadTop_End`, `Spine2`), y un retarget de importación los
## renombraría. En su lugar, UAL se importa con el `BoneMap` humanoide de Godot
## —que normaliza ejes y posiciones— y aquí se reescriben las pistas del perfil
## humanoide a los nombres Mixamo de la figura. Los ejes de reposo de ambos
## esqueletos coinciden con el perfil, así que basta con renombrar.
class_name AnimacionesUAL
extends RefCounted

const RUTA := "res://assets/cc0/quaternius_ual/"
const BIBLIOTECA := &"ual"
const RAIZ_PERFIL := "Root"
## Lo que la articulación de la punta del pie queda sobre el suelo.
const ALTO_PUNTERA := 0.03

## Clip propio → [fichero, animación de UAL, en bucle]. El tercer valor falta en
## los gestos continuos; los de un solo paso —levantarse, sentarse, coger algo—
## lo declaran falso para quedarse en su último fotograma. Los nombres no
## terminan en `idle` ni en `work` a propósito: `Modelos._animar` busca por sufijo.
const CLIPS := {
	"telefono": ["UAL2_Standard.glb", "Idle_TalkingPhone"],
	"sentado": ["UAL1_Standard.glb", "Sitting_Idle"],
	"sentado_hablando": ["UAL1_Standard.glb", "Sitting_Talking"],
	"conversar": ["UAL1_Standard.glb", "Idle_Talking"],
	"brazos_cruzados": ["UAL2_Standard.glb", "Idle_FoldArms"],
	"levantarse": ["UAL1_Standard.glb", "Sitting_Exit", false],
	"sentarse": ["UAL1_Standard.glb", "Sitting_Enter", false],
	"andar": ["UAL1_Standard.glb", "Walk_Formal"],
	"andar_cargando": ["UAL2_Standard.glb", "Walk_Carry"],
	"coger": ["UAL1_Standard.glb", "Interact", false],
}

## Perfil humanoide de Godot → hueso de `persona.fbx`. Los dedos corazón, anular
## y meñique no existen en la figura: sus pistas se descartan.
const HUESOS := {
	"Hips": "Hips",
	"Spine": "Spine",
	"Chest": "Spine1",
	"UpperChest": "Spine2",
	"Neck": "Neck",
	"Head": "Head",
	"LeftShoulder": "LeftShoulder",
	"LeftUpperArm": "LeftArm",
	"LeftLowerArm": "LeftForeArm",
	"LeftHand": "LeftHand",
	"LeftThumbMetacarpal": "LeftHandThumb1",
	"LeftThumbProximal": "LeftHandThumb2",
	"LeftThumbDistal": "LeftHandThumb3",
	"LeftIndexProximal": "LeftHandIndex1",
	"LeftIndexIntermediate": "LeftHandIndex2",
	"LeftIndexDistal": "LeftHandIndex3",
	"RightShoulder": "RightShoulder",
	"RightUpperArm": "RightArm",
	"RightLowerArm": "RightForeArm",
	"RightHand": "RightHand",
	"RightThumbMetacarpal": "RightHandThumb1",
	"RightThumbProximal": "RightHandThumb2",
	"RightThumbDistal": "RightHandThumb3",
	"RightIndexProximal": "RightHandIndex1",
	"RightIndexIntermediate": "RightHandIndex2",
	"RightIndexDistal": "RightHandIndex3",
	"LeftUpperLeg": "LeftUpLeg",
	"LeftLowerLeg": "LeftLeg",
	"LeftFoot": "LeftFoot",
	"LeftToes": "LeftToeBase",
	"RightUpperLeg": "RightUpLeg",
	"RightLowerLeg": "RightLeg",
	"RightFoot": "RightFoot",
	"RightToes": "RightToeBase",
}

## Lo que `persona.fbx` trae de serie y un avatar fotorrealista no (#275). Los
## nombres terminan en el sufijo que busca `Modelos._animar`. Teclear de pie no
## existe en UAL: quien trabaja sentado usa `sentado_hablando` y de pie respira.
const CLIPS_BASE := {
	"idle": ["UAL1_Standard.glb", "Idle"],
	"walk": ["UAL1_Standard.glb", "Walk_Formal"],
	"run": ["UAL1_Standard.glb", "Jog_Fwd"],
	"work": ["UAL1_Standard.glb", "Idle"],
}
const BIBLIOTECA_BASE := &"base"

static var _fuentes := {}
static var _convertidas := {}


## Reproduce [param clip] en bucle sobre una figura de `persona.fbx`, desde
## [param desfase] (0–1 del clip). Devuelve falso si la figura no tiene
## reproductor o esqueleto, o el clip no existe: quien llama conserva su gesto.
static func reproducir(pieza: Node3D, clip: String, desfase: float = 0.0) -> bool:
	# Un avatar fotorrealista usa la captura de Rocketbox si la tiene (#1319).
	if AnimacionesRocketbox.reproducir(pieza, clip, desfase):
		return true
	var reproductor := Modelos._reproductor(pieza)
	var esqueleto := Modelos._esqueleto(pieza)
	if reproductor == null or esqueleto == null or not CLIPS.has(clip):
		return false
	var animacion := _animacion(
		clip, _ruta_esqueleto(reproductor, esqueleto), _altura_cadera(esqueleto), esqueleto
	)
	if animacion == null:
		return false
	if not reproductor.has_animation_library(BIBLIOTECA):
		reproductor.add_animation_library(BIBLIOTECA, AnimationLibrary.new())
	var biblioteca := reproductor.get_animation_library(BIBLIOTECA)
	if not biblioteca.has_animation(clip):
		biblioteca.add_animation(clip, animacion)
	var nombre := "%s/%s" % [BIBLIOTECA, clip]
	reproductor.play(nombre)
	reproductor.seek(clampf(desfase, 0.0, 1.0) * animacion.length, true)
	return true


## La animación ya convertida para una ruta de esqueleto. Se cachea por ruta:
## todas las figuras de `persona.fbx` comparten la misma y reutilizan el recurso.
static func en_bucle(clip: String) -> bool:
	var datos: Array = CLIPS.get(clip, [])
	return datos.size() < 3 or bool(datos[2])


## Cuánto dura [param clip] en segundos, o 0 si no existe. Con [param pieza],
## la duración del clip que esa figura reproduce de verdad (Rocketbox o UAL).
static func duracion(clip: String, pieza: Node3D = null) -> float:
	if pieza != null and AnimacionesRocketbox.tiene(pieza, clip):
		return AnimacionesRocketbox.duracion(pieza, clip)
	if not CLIPS.has(clip):
		return 0.0
	var fuente := _fuente(CLIPS[clip][0], CLIPS[clip][1])
	return fuente.length if fuente != null else 0.0


## Da a un avatar con esqueleto del perfil humanoide los clips que `persona.fbx`
## trae de fábrica, en su propia biblioteca, para que `Modelos._animar` los
## encuentre por sufijo igual que en el maniquí.
static func preparar_base(pieza: Node3D) -> bool:
	var esqueleto := Modelos._esqueleto(pieza)
	if esqueleto == null:
		return false
	var reproductor := Modelos._reproductor(pieza)
	if reproductor == null:
		# El avatar llega sin animaciones propias y el importador no le crea
		# reproductor. Colgado de la raíz, sus pistas apuntan igual que en
		# `persona.fbx`: ruta relativa al modelo.
		reproductor = AnimationPlayer.new()
		reproductor.name = "AnimationPlayer"
		pieza.add_child(reproductor)
	if reproductor.has_animation_library(BIBLIOTECA_BASE):
		return true
	var biblioteca := AnimationLibrary.new()
	var ruta := _ruta_esqueleto(reproductor, esqueleto)
	var altura := _altura_cadera(esqueleto)
	for nombre in CLIPS_BASE:
		# La respiración, el paso y el trabajo de un avatar salen de Rocketbox
		# (#1319); UAL queda como respaldo si falta la biblioteca o el clip.
		var propia := AnimacionesRocketbox.animacion_para(pieza, nombre)
		if propia != null:
			biblioteca.add_animation(nombre, propia)
			continue
		var datos: Array = CLIPS_BASE[nombre]
		var fuente := _fuente(datos[0], datos[1])
		if fuente == null:
			continue
		var clave := "base:%s|%s|%.4f|perfil" % [nombre, ruta, altura]
		if not _convertidas.has(clave):
			_convertidas[clave] = convertir(fuente, ruta, altura, true, _huesos_de(esqueleto))
		biblioteca.add_animation(nombre, _convertidas[clave])
	reproductor.add_animation_library(BIBLIOTECA_BASE, biblioteca)
	return not biblioteca.get_animation_list().is_empty()


static func _animacion(
	clip: String, ruta_esqueleto: String, altura: float, esqueleto: Skeleton3D
) -> Animation:
	var huesos := _huesos_de(esqueleto)
	var clave := "%s|%s|%.4f|%s" % [clip, ruta_esqueleto, altura, huesos != HUESOS]
	if _convertidas.has(clave):
		return _convertidas[clave]
	var fuente := _fuente(CLIPS[clip][0], CLIPS[clip][1])
	if fuente == null:
		return null
	var animacion := convertir(fuente, ruta_esqueleto, altura, en_bucle(clip), huesos)
	_convertidas[clave] = animacion
	return animacion


static func _fuente(fichero: String, nombre: String) -> Animation:
	if not _fuentes.has(fichero):
		var escena: PackedScene = load(RUTA + fichero)
		var reproductor: AnimationPlayer = null
		if escena != null:
			var instancia := escena.instantiate()
			reproductor = Modelos._reproductor(instancia)
			_fuentes[fichero] = reproductor.get_animation_library(&"") if reproductor else null
			instancia.free()
		else:
			_fuentes[fichero] = null
	var biblioteca: AnimationLibrary = _fuentes[fichero]
	if biblioteca == null or not biblioteca.has_animation(nombre):
		return null
	return biblioteca.get_animation(nombre)


## Copia de [param fuente] con las pistas de hueso apuntando a
## [param ruta_esqueleto] y a los nombres de `persona.fbx`. Solo la cadera
## conserva posición: el resto de huesos se mueven por rotación, y trasladarlos
## con las proporciones del maniquí deformaría la figura.
##
## El importador de UAL deja la posición de cadera normalizada a altura 1.
## [param altura_cadera] la devuelve a la escala de la figura dentro de las
## propias claves, y no con `Skeleton3D.motion_scale`: eso escalaría también las
## pistas de `Idle` y `Working` y la figura se hundiría al volver a ellas.
##
## [param huesos] traduce del perfil a la figura: `HUESOS` para `persona.fbx`, o
## la identidad para un esqueleto importado ya con el perfil humanoide.
static func convertir(
	fuente: Animation,
	ruta_esqueleto: String,
	altura_cadera: float,
	bucle: bool = true,
	huesos: Dictionary = HUESOS
) -> Animation:
	var animacion := Animation.new()
	animacion.length = fuente.length
	animacion.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	for pista in fuente.get_track_count():
		var hueso := String(fuente.track_get_path(pista).get_concatenated_subnames())
		if not huesos.has(hueso):
			continue
		var tipo := fuente.track_get_type(pista)
		var es_rotacion := tipo == Animation.TYPE_ROTATION_3D
		var es_cadera := tipo == Animation.TYPE_POSITION_3D and hueso == "Hips"
		if not es_rotacion and not es_cadera:
			continue
		var nueva := animacion.add_track(tipo)
		animacion.track_set_path(nueva, NodePath("%s:%s" % [ruta_esqueleto, huesos[hueso]]))
		animacion.track_set_interpolation_type(nueva, fuente.track_get_interpolation_type(pista))
		for clave in fuente.track_get_key_count(pista):
			var valor = fuente.track_get_key_value(pista, clave)
			if es_cadera:
				valor = valor * altura_cadera
			animacion.track_insert_key(nueva, fuente.track_get_key_time(pista, clave), valor)
	if huesos.has(RAIZ_PERFIL):
		# UAL deja la raíz en el suelo y no la anima; un Biped la tiene a la
		# altura de la pelvis. Sin fijarla, la cadera del clip se suma a esa
		# altura y la figura flota un metro.
		var raiz := animacion.add_track(Animation.TYPE_POSITION_3D)
		animacion.track_set_path(raiz, NodePath("%s:%s" % [ruta_esqueleto, RAIZ_PERFIL]))
		animacion.position_track_insert_key(raiz, 0.0, Vector3.ZERO)
	return animacion


## Qué huesos de UAL mueve un clip en esta figura y cómo se llaman en ella. Un
## esqueleto importado con `BoneMap` ya usa los nombres del perfil: se mapea
## cada hueso a sí mismo, incluidos los dedos que `persona.fbx` no tiene.
static func _huesos_de(esqueleto: Skeleton3D) -> Dictionary:
	if esqueleto.find_bone("UpperChest") < 0:
		return HUESOS
	var propios := {}
	for i in esqueleto.get_bone_count():
		var nombre := esqueleto.get_bone_name(i)
		propios[nombre] = nombre
	return propios


static func _altura_cadera(esqueleto: Skeleton3D) -> float:
	var cadera := esqueleto.find_bone("Hips")
	if cadera < 0:
		return 1.0
	var altura := esqueleto.get_bone_global_rest(cadera).origin.y
	if esqueleto.find_bone("UpperChest") < 0:
		return altura
	# Un avatar convertido a glTF deja la pelvis como hueso raíz en el origen:
	# lo que UAL normaliza es su altura sobre el suelo, no sobre ese origen. El
	# AABB de la malla no sirve de suela porque conserva los ejes del FBX
	# original; la punta del pie sí, a un par de centímetros del suelo.
	var suela := INF
	for pie in ["LeftToes", "RightToes"]:
		var hueso := esqueleto.find_bone(pie)
		if hueso >= 0:
			suela = minf(suela, esqueleto.get_bone_global_rest(hueso).origin.y)
	return altura - suela + ALTO_PUNTERA if suela < altura else altura


static func _ruta_esqueleto(reproductor: AnimationPlayer, esqueleto: Skeleton3D) -> String:
	var raiz := reproductor.get_node_or_null(reproductor.root_node)
	if raiz == null:
		raiz = reproductor.get_parent()
	return String(raiz.get_path_to(esqueleto))
