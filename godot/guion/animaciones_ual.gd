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

static var _fuentes := {}
static var _convertidas := {}


## Reproduce [param clip] en bucle sobre una figura de `persona.fbx`, desde
## [param desfase] (0–1 del clip). Devuelve falso si la figura no tiene
## reproductor o esqueleto, o el clip no existe: quien llama conserva su gesto.
static func reproducir(pieza: Node3D, clip: String, desfase: float = 0.0) -> bool:
	var reproductor := Modelos._reproductor(pieza)
	var esqueleto := Modelos._esqueleto(pieza)
	if reproductor == null or esqueleto == null or not CLIPS.has(clip):
		return false
	var animacion := _animacion(
		clip, _ruta_esqueleto(reproductor, esqueleto), _altura_cadera(esqueleto)
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


## Cuánto dura [param clip] en segundos, o 0 si no existe.
static func duracion(clip: String) -> float:
	if not CLIPS.has(clip):
		return 0.0
	var fuente := _fuente(CLIPS[clip][0], CLIPS[clip][1])
	return fuente.length if fuente != null else 0.0


static func _animacion(clip: String, ruta_esqueleto: String, altura: float) -> Animation:
	var clave := "%s|%s|%.4f" % [clip, ruta_esqueleto, altura]
	if _convertidas.has(clave):
		return _convertidas[clave]
	var fuente := _fuente(CLIPS[clip][0], CLIPS[clip][1])
	if fuente == null:
		return null
	var animacion := convertir(fuente, ruta_esqueleto, altura, en_bucle(clip))
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
static func convertir(
	fuente: Animation, ruta_esqueleto: String, altura_cadera: float, bucle: bool = true
) -> Animation:
	var animacion := Animation.new()
	animacion.length = fuente.length
	animacion.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	for pista in fuente.get_track_count():
		var hueso := String(fuente.track_get_path(pista).get_concatenated_subnames())
		if not HUESOS.has(hueso):
			continue
		var tipo := fuente.track_get_type(pista)
		var es_rotacion := tipo == Animation.TYPE_ROTATION_3D
		var es_cadera := tipo == Animation.TYPE_POSITION_3D and hueso == "Hips"
		if not es_rotacion and not es_cadera:
			continue
		var nueva := animacion.add_track(tipo)
		animacion.track_set_path(nueva, NodePath("%s:%s" % [ruta_esqueleto, HUESOS[hueso]]))
		animacion.track_set_interpolation_type(nueva, fuente.track_get_interpolation_type(pista))
		for clave in fuente.track_get_key_count(pista):
			var valor = fuente.track_get_key_value(pista, clave)
			if es_cadera:
				valor = valor * altura_cadera
			animacion.track_insert_key(nueva, fuente.track_get_key_time(pista, clave), valor)
	return animacion


static func _altura_cadera(esqueleto: Skeleton3D) -> float:
	var cadera := esqueleto.find_bone("Hips")
	if cadera < 0:
		return 1.0
	return esqueleto.get_bone_global_rest(cadera).origin.y


static func _ruta_esqueleto(reproductor: AnimationPlayer, esqueleto: Skeleton3D) -> String:
	var raiz := reproductor.get_node_or_null(reproductor.root_node)
	if raiz == null:
		raiz = reproductor.get_parent()
	return String(raiz.get_path_to(esqueleto))
