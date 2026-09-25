## Gestos de captura de movimiento de Microsoft Rocketbox (MIT) para los avatares
## fotorrealistas de la oficina (#1319).
##
## Los avatares de #275 se animaban con Quaternius UAL, que es un paquete de
## videojuego: su `Idle` es una pose de «preparado» —rodillas flexionadas, puños
## a la cadera, barbilla alta— que sobre un cuerpo realista se lee como alguien a
## punto de pelear. Rocketbox trae ~470 clips de captura hechos para el mismo
## esqueleto Biped que los avatares; aquí se usan los que la oficina necesita, en
## su variante de hombre o de mujer.
##
## Los clips viven en dos bibliotecas, `animaciones_m.glb` y `animaciones_f.glb`,
## que genera `herramientas/convertir_animaciones_rocketbox.gd` y se importan con
## el mismo `BoneMap` que los avatares: sus pistas ya hablan el perfil humanoide.
##
## Lo que no está aquí —cruzarse de brazos, andar cargando— sigue saliendo de
## UAL: `AnimacionesUAL` pregunta primero a este módulo y, si no tiene el clip o
## la figura no es un avatar, usa el suyo. `persona.fbx` no pasa nunca por aquí.
class_name AnimacionesRocketbox
extends RefCounted

const RUTA := "res://assets/modelos/rocketbox/animaciones/animaciones_%s.glb"
const BIBLIOTECA := &"rocketbox"
const RAIZ := "Root"
const CADERA := "Hips"

## Dónde empieza y acaba la cadera de un clip. De pie, la cadera queda sobre el
## origen de la figura; sentada, donde se sentaba con UAL.
const DE_PIE := 0
const SENTADO := 1

## Clip propio → [clip de Rocketbox sin el prefijo de sexo, postura al empezar,
## postura al acabar]. Los nombres propios son los de `AnimacionesUAL.CLIPS` y
## `CLIPS_BASE`, para que quien llama no sepa de dónde sale el gesto.
##
## `work` es trabajar DE PIE: UAL no lo tenía y respiraba; Rocketbox sí trae
## alguien trabajando en una mesa alta. Sentado se trabaja con
## `sentado_hablando`, que aquí es alguien pensando en voz alta a la mesa.
const CLIPS := {
	"idle": ["idle_breathe_01", DE_PIE, DE_PIE],
	"walk": ["walk_neutral_01", DE_PIE, DE_PIE],
	"run": ["run_neutral_01", DE_PIE, DE_PIE],
	"work": ["work_table", DE_PIE, DE_PIE],
	"telefono": ["cell_phone_talk_01", DE_PIE, DE_PIE],
	"conversar": ["gestic_talk_neutral_01", DE_PIE, DE_PIE],
	"sentado": ["sit_table_idle_neutral_01", SENTADO, SENTADO],
	"sentado_hablando": ["sit_table_gestic_thoughtful", SENTADO, SENTADO],
	"levantarse": ["sit_stand_up_chair_01", SENTADO, DE_PIE],
	"sentarse": ["sit_down_chair_01", DE_PIE, SENTADO],
	"andar": ["walk_neutral_01", DE_PIE, DE_PIE],
	"coger": ["documents_take", DE_PIE, DE_PIE],
	# Reposo variado: lo que hace alguien que lleva un rato parado.
	"mirar_alrededor": ["idle_look_around_01", DE_PIE, DE_PIE],
	"rascarse": ["idle_scratch_head_01", DE_PIE, DE_PIE],
	"bostezar": ["idle_yawn_01", DE_PIE, DE_PIE],
	"nervioso": ["idle_nervous_01", DE_PIE, DE_PIE],
	"esperar": ["idle_waiting_01", DE_PIE, DE_PIE],
	"estirarse": ["idle_stretch_arms_01", DE_PIE, DE_PIE],
	# Juicio y careo.
	"enfadado": ["idle_angry_01", DE_PIE, DE_PIE],
	"discutir": ["gestic_talk_angry_01", DE_PIE, DE_PIE],
	"titubear": ["gestic_talk_nervous_01", DE_PIE, DE_PIE],
	"negar": ["gestic_listen_deny_01", DE_PIE, DE_PIE],
	"encajar": ["gestic_listen_angry_01", DE_PIE, DE_PIE],
	"celebrar": ["cheer_01", DE_PIE, DE_PIE],
	"aplaudir": ["claphands_01", DE_PIE, DE_PIE],
}

## Avatares de mujer, por el nombre de su `.glb` (#275).
const PREFIJOS_MUJER := ["female_", "business_female_"]

static var _fuentes := {}
static var _convertidas := {}
static var _cadera_sentada_ual: Variant = null


## "m" o "f" si [param pieza] es un avatar de Rocketbox; vacío si no lo es.
static func sexo(pieza: Node3D) -> String:
	var ruta := String(pieza.scene_file_path)
	if not ruta.begins_with(Modelos.RUTA + Modelos.CARPETA_REALISTAS):
		return ""
	var archivo := ruta.get_file()
	for prefijo in PREFIJOS_MUJER:
		if archivo.begins_with(prefijo):
			return "f"
	return "m"


## Si hay versión Rocketbox de [param clip] para [param pieza].
static func tiene(pieza: Node3D, clip: String) -> bool:
	var cual := sexo(pieza)
	return not cual.is_empty() and _fuente(cual, clip) != null


## Reproduce [param clip] sobre un avatar desde [param desfase] (0–1 del clip).
## Falso si la figura no es un avatar o no hay clip: quien llama usa UAL.
static func reproducir(pieza: Node3D, clip: String, desfase: float = 0.0) -> bool:
	var animacion := animacion_para(pieza, clip)
	if animacion == null:
		return false
	var reproductor := Modelos._reproductor(pieza)
	if not reproductor.has_animation_library(BIBLIOTECA):
		reproductor.add_animation_library(BIBLIOTECA, AnimationLibrary.new())
	var biblioteca := reproductor.get_animation_library(BIBLIOTECA)
	if not biblioteca.has_animation(clip):
		biblioteca.add_animation(clip, animacion)
	reproductor.play("%s/%s" % [BIBLIOTECA, clip])
	reproductor.seek(clampf(desfase, 0.0, 1.0) * animacion.length, true)
	return true


## La animación ya convertida para esta figura, o nulo si no hay versión
## Rocketbox. Se cachea por sexo, clip, ruta de esqueleto y altura de cadera.
static func animacion_para(pieza: Node3D, clip: String) -> Animation:
	var cual := sexo(pieza)
	if cual.is_empty():
		return null
	var reproductor := Modelos._reproductor(pieza)
	var esqueleto := Modelos._esqueleto(pieza)
	if reproductor == null or esqueleto == null:
		return null
	var fuente := _fuente(cual, clip)
	if fuente == null:
		return null
	var ruta := AnimacionesUAL._ruta_esqueleto(reproductor, esqueleto)
	var altura := AnimacionesUAL._altura_cadera(esqueleto)
	var clave := "%s|%s|%s|%.4f" % [cual, clip, ruta, altura]
	if not _convertidas.has(clave):
		_convertidas[clave] = convertir(
			fuente,
			ruta,
			altura,
			AnimacionesUAL.en_bucle(clip),
			_huesos_de(esqueleto),
			CLIPS[clip][1],
			CLIPS[clip][2]
		)
	return _convertidas[clave]


## Cuánto dura [param clip] en la versión de [param pieza], o 0 si no la hay.
static func duracion(pieza: Node3D, clip: String) -> float:
	var cual := sexo(pieza)
	if cual.is_empty():
		return 0.0
	var fuente := _fuente(cual, clip)
	return fuente.length if fuente != null else 0.0


static func _fuente(cual: String, clip: String) -> Animation:
	if not CLIPS.has(clip):
		return null
	if not _fuentes.has(cual):
		_fuentes[cual] = null
		var ruta := RUTA % cual
		if ResourceLoader.exists(ruta):
			var instancia := (load(ruta) as PackedScene).instantiate()
			var reproductor := Modelos._reproductor(instancia)
			if reproductor != null:
				_fuentes[cual] = reproductor.get_animation_library(&"")
			instancia.free()
	var biblioteca: AnimationLibrary = _fuentes[cual]
	var nombre := StringName(CLIPS[clip][0])
	if biblioteca == null or not biblioteca.has_animation(nombre):
		return null
	return biblioteca.get_animation(nombre)


## Copia de [param fuente] con las pistas apuntando a [param ruta_esqueleto].
##
## En el Biped, `Bip01` es un hueso a la altura de la pelvis que lleva la
## traslación y el giro del cuerpo; tras el `BoneMap` es `Root`, y la pelvis
## (`Hips`) cuelga de él. En el avatar, en cambio, `Bip01` es un nodo y la pelvis
## es el hueso raíz. Así que aquí se COMPONEN las dos: la pista de `Hips` lleva
## la posición y el giro de `Root` aplicados a los suyos, y `Root` desaparece.
## Copiar solo la cadera, como hace `AnimacionesUAL.convertir` —UAL no anima la
## raíz—, deja el cuerpo tumbado o flotando.
##
## El importador normaliza la posición a altura de cadera 1; [param altura_cadera]
## la devuelve a la escala de la figura, igual que con UAL. [param inicio] y
## [param fin] son las posturas `DE_PIE` o `SENTADO` en que el clip empieza y
## acaba: ver `_anclar`.
static func convertir(
	fuente: Animation,
	ruta_esqueleto: String,
	altura_cadera: float,
	bucle: bool,
	huesos: Dictionary,
	inicio: int = DE_PIE,
	fin: int = DE_PIE
) -> Animation:
	var animacion := Animation.new()
	animacion.length = fuente.length
	animacion.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	var pistas := {}
	for pista in fuente.get_track_count():
		var hueso := String(fuente.track_get_path(pista).get_concatenated_subnames())
		var tipo := fuente.track_get_type(pista)
		pistas["%s|%d" % [hueso, tipo]] = pista
		if hueso == RAIZ or hueso == CADERA or not huesos.has(hueso):
			continue
		if tipo != Animation.TYPE_ROTATION_3D:
			continue
		var nueva := animacion.add_track(tipo)
		animacion.track_set_path(nueva, NodePath("%s:%s" % [ruta_esqueleto, huesos[hueso]]))
		animacion.track_set_interpolation_type(nueva, fuente.track_get_interpolation_type(pista))
		for clave in fuente.track_get_key_count(pista):
			animacion.track_insert_key(
				nueva,
				fuente.track_get_key_time(pista, clave),
				fuente.track_get_key_value(pista, clave)
			)
	if huesos.has(CADERA):
		var cadera := _cadera_compuesta(fuente, pistas)
		_anclar(cadera, fuente.length, inicio, fin)
		var ruta := NodePath("%s:%s" % [ruta_esqueleto, huesos[CADERA]])
		var posicion := animacion.add_track(Animation.TYPE_POSITION_3D)
		var rotacion := animacion.add_track(Animation.TYPE_ROTATION_3D)
		animacion.track_set_path(posicion, ruta)
		animacion.track_set_path(rotacion, ruta)
		for clave in cadera:
			animacion.position_track_insert_key(posicion, clave[0], clave[1] * altura_cadera)
			animacion.rotation_track_insert_key(rotacion, clave[0], clave[2])
	return animacion


## [tiempo, posición, giro] de la cadera con `Root` aplicado, en la escala
## normalizada del importador.
static func _cadera_compuesta(fuente: Animation, pistas: Dictionary) -> Array:
	var raiz_pos: int = pistas.get("%s|%d" % [RAIZ, Animation.TYPE_POSITION_3D], -1)
	var raiz_rot: int = pistas.get("%s|%d" % [RAIZ, Animation.TYPE_ROTATION_3D], -1)
	var cadera_pos: int = pistas.get("%s|%d" % [CADERA, Animation.TYPE_POSITION_3D], -1)
	var cadera_rot: int = pistas.get("%s|%d" % [CADERA, Animation.TYPE_ROTATION_3D], -1)
	# Las cuatro pistas vienen horneadas a la misma cadencia, pero el optimizador
	# del conversor puede haber quitado claves de una y no de otra: se muestrea
	# en la unión de sus tiempos.
	var tiempos := {0.0: true}
	for pista in [raiz_pos, raiz_rot, cadera_pos, cadera_rot]:
		if pista >= 0:
			for clave in fuente.track_get_key_count(pista):
				tiempos[snappedf(fuente.track_get_key_time(pista, clave), 0.0001)] = true
	var ordenados := tiempos.keys()
	ordenados.sort()
	var claves := []
	for t in ordenados:
		var giro_raiz := Quaternion.IDENTITY
		if raiz_rot >= 0:
			giro_raiz = fuente.rotation_track_interpolate(raiz_rot, t)
		var pos_raiz := Vector3.ZERO
		if raiz_pos >= 0:
			pos_raiz = fuente.position_track_interpolate(raiz_pos, t)
		var giro_cadera := Quaternion.IDENTITY
		if cadera_rot >= 0:
			giro_cadera = fuente.rotation_track_interpolate(cadera_rot, t)
		var pos_cadera := Vector3.ZERO
		if cadera_pos >= 0:
			pos_cadera = fuente.position_track_interpolate(cadera_pos, t)
		claves.append(
			[t, pos_raiz + giro_raiz * pos_cadera, (giro_raiz * giro_cadera).normalized()]
		)
	return claves


## Lleva la cadera de [param claves] a donde el juego espera el cuerpo.
##
## Andar, correr, sentarse y levantarse solo existen en Rocketbox con el
## desplazamiento dentro: andar avanza un metro por ciclo y sentarse retrocede
## hasta la silla. Aquí el cuerpo lo mueve el juego —`RecadoCompanero3D` lo
## lleva por la ruta y hasta la silla—, así que ese viaje sobra: de pie, la
## cadera se queda sobre el origen de la figura en horizontal.
##
## Sentada, la cadera va donde la dejaba el `Sitting_Idle` de UAL, porque es a
## esa postura a la que están medidos `ALTURA_ASIENTO` y `ADELANTO_SENTADO` de
## `CompaneroIdle3D`: si no, el compañero se sienta a un palmo de su silla. La
## captura se hizo en otra silla, así que también cambia la altura.
##
## La corrección de cada extremo se reparte en línea por el clip: en un bucle de
## pie a pie quita la deriva sin tocar el vaivén, y en sentarse lleva de la
## postura de pie a la sentada al ritmo del propio gesto.
static func _anclar(claves: Array, duracion: float, inicio: int, fin: int) -> void:
	if claves.is_empty():
		return
	var primera: Vector3 = claves[0][1]
	var ultima: Vector3 = claves[-1][1]
	var al_empezar := _destino(inicio, primera) - primera
	var al_acabar := _destino(fin, ultima) - ultima
	var ultimo_tiempo: float = claves[-1][0]
	var tramo := ultimo_tiempo if ultimo_tiempo > 0.0 else maxf(duracion, 0.001)
	for clave in claves:
		clave[1] += al_empezar.lerp(al_acabar, clampf(clave[0] / tramo, 0.0, 1.0))


static func _destino(postura: int, cadera: Vector3) -> Vector3:
	if postura == SENTADO:
		var asiento: Variant = cadera_sentada_ual()
		if asiento != null:
			return asiento
	return Vector3(0.0, cadera.y, 0.0)


## Dónde deja la cadera el `Sitting_Idle` de UAL, en la escala normalizada del
## importador; nulo si UAL no está. Se lee del clip en vez de copiarse aquí para
## que la silla siga cuadrando si algún día cambia ese clip.
static func cadera_sentada_ual() -> Variant:
	if _cadera_sentada_ual == null:
		var datos: Array = AnimacionesUAL.CLIPS["sentado"]
		var fuente := AnimacionesUAL._fuente(datos[0], datos[1])
		if fuente == null:
			return null
		for pista in fuente.get_track_count():
			if (
				fuente.track_get_type(pista) == Animation.TYPE_POSITION_3D
				and String(fuente.track_get_path(pista).get_concatenated_subnames()) == CADERA
			):
				_cadera_sentada_ual = fuente.position_track_interpolate(pista, 0.0)
				break
	return _cadera_sentada_ual


## Un avatar importado con el `BoneMap` ya usa los nombres del perfil.
static func _huesos_de(esqueleto: Skeleton3D) -> Dictionary:
	var propios := {}
	for i in esqueleto.get_bone_count():
		var nombre := esqueleto.get_bone_name(i)
		propios[nombre] = nombre
	return propios
