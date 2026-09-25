extends SceneTree

## Convierte las animaciones de captura de movimiento de Microsoft Rocketbox
## (MIT) a las dos bibliotecas de `assets/modelos/rocketbox/animaciones/` (#1319).
##
## Cada clip original es un `.max.fbx` de 1-7 MB con el esqueleto Biped entero.
## Aquí se juntan los clips de cada sexo en un solo `.glb` sin malla: esqueleto
## y pistas de hueso, nada más. Se descartan el `MotionExtractionHelper` y las
## huellas (`Bip01 Footsteps`), que el juego no usa.
##
## Rocketbox reparte los clips en tres carpetas: `static` viene en el sitio, y
## `xy`/`xyz` conservan el desplazamiento del cuerpo —andar avanza un metro por
## ciclo, sentarse retrocede hasta la silla—. Andar, correr, sentarse y levantarse
## solo existen ahí; ese desplazamiento lo quita `AnimacionesRocketbox` al
## convertir, no esta herramienta, para que el `.glb` siga siendo la captura tal
## cual. El nombre de la animación es el del fichero sin el prefijo de sexo ni
## `.max.fbx`, que es lo que busca `AnimacionesRocketbox`.
##
## Uso, con un clon de https://github.com/microsoft/Microsoft-Rocketbox:
## godot4 --headless --path godot \
##     --script res://herramientas/convertir_animaciones_rocketbox.gd -- \
##     /ruta/Microsoft-Rocketbox/Assets/Animations /ruta/godot/assets/modelos/rocketbox/animaciones
##
## El `.import` de cada `.glb` lleva el mismo `BoneMap` Biped → perfil humanoide
## con `fix_silhouette` que los avatares: sin él, los brazos salen retorcidos.

const ESTATICAS := "all_animations_max_motextr_static"
const CON_XY := "all_animations_max_motextr_xy"
const CON_XYZ := "all_animations_max_motextr_xyz"

## Clip de Rocketbox → carpeta, por sexo. La misma entrada puede venir de otra
## carpeta en cada sexo: la mujer solo habla por teléfono en `xyz`.
const CLIPS := {
	"m":
	{
		"idle_breathe_01": ESTATICAS,
		"walk_neutral_01": CON_XY,
		"run_neutral_01": CON_XY,
		"cell_phone_talk_01": ESTATICAS,
		"gestic_talk_neutral_01": ESTATICAS,
		"sit_table_idle_neutral_01": ESTATICAS,
		"work_table": ESTATICAS,
		"sit_stand_up_chair_01": CON_XYZ,
		"sit_down_chair_01": CON_XYZ,
		"documents_take": ESTATICAS,
		"sit_table_gestic_thoughtful": ESTATICAS,
		# Reposo variado del protagonista (#1319, segunda tanda).
		"idle_look_around_01": ESTATICAS,
		"idle_scratch_head_01": ESTATICAS,
		"idle_yawn_01": ESTATICAS,
		"idle_nervous_01": ESTATICAS,
		"idle_waiting_01": ESTATICAS,
		"idle_stretch_arms_01": ESTATICAS,
		# Juicio y careo: atacar, encajar, perder los nervios y ganar.
		"idle_angry_01": ESTATICAS,
		"gestic_talk_nervous_01": ESTATICAS,
		"gestic_listen_deny_01": ESTATICAS,
		"gestic_listen_angry_01": ESTATICAS,
		"cheer_01": ESTATICAS,
		"claphands_01": ESTATICAS,
		# El hombre solo discute furioso en `xyz`.
		"gestic_talk_angry_01": CON_XYZ,
	},
	"f":
	{
		"idle_breathe_01": ESTATICAS,
		"walk_neutral_01": CON_XY,
		"run_neutral_01": CON_XY,
		"cell_phone_talk_01": CON_XYZ,
		"gestic_talk_neutral_01": ESTATICAS,
		"sit_table_idle_neutral_01": ESTATICAS,
		"work_table": ESTATICAS,
		"sit_stand_up_chair_01": CON_XYZ,
		"sit_down_chair_01": CON_XYZ,
		"documents_take": ESTATICAS,
		"sit_table_gestic_thoughtful": ESTATICAS,
		# Reposo variado del protagonista (#1319, segunda tanda).
		"idle_look_around_01": ESTATICAS,
		"idle_scratch_head_01": ESTATICAS,
		"idle_yawn_01": ESTATICAS,
		"idle_nervous_01": ESTATICAS,
		"idle_waiting_01": ESTATICAS,
		"idle_stretch_arms_01": ESTATICAS,
		# Juicio y careo: atacar, encajar, perder los nervios y ganar.
		"idle_angry_01": ESTATICAS,
		"gestic_talk_nervous_01": ESTATICAS,
		"gestic_listen_deny_01": ESTATICAS,
		"gestic_listen_angry_01": ESTATICAS,
		"cheer_01": ESTATICAS,
		"claphands_01": ESTATICAS,
		"gestic_talk_angry_01": ESTATICAS,
	},
}

const DESCARTADOS := ["MotionExtractionHelper", "Bip01 Footsteps"]

## Los huesos Biped que el `BoneMap` de los avatares lleva al perfil humanoide.
## El resto —cara, coleta, dedos que el perfil no tiene— no llega al avatar, así
## que sus pistas solo pesan. Solo `Bip01` (raíz) y la pelvis conservan posición:
## los demás huesos se mueven por rotación, como en `AnimacionesUAL.convertir`.
const RAIZ := "Bip01"
const PELVIS := "Bip01 Pelvis"
const PREFIJOS_MAPEADOS := [
	"Bip01 Pelvis",
	"Bip01 Spine",
	"Bip01 Neck",
	"Bip01 Head",
	"Bip01 L Clavicle",
	"Bip01 L UpperArm",
	"Bip01 L Forearm",
	"Bip01 L Hand",
	"Bip01 L Finger",
	"Bip01 R Clavicle",
	"Bip01 R UpperArm",
	"Bip01 R Forearm",
	"Bip01 R Hand",
	"Bip01 R Finger",
	"Bip01 L Thigh",
	"Bip01 L Calf",
	"Bip01 L Foot",
	"Bip01 L Toe0",
	"Bip01 R Thigh",
	"Bip01 R Calf",
	"Bip01 R Foot",
	"Bip01 R Toe0",
]
## Tolerancia de `Animation.optimize`: por debajo de estas diferencias una clave
## intermedia se da por interpolable y se quita. La captura llega a 30 fps con
## casi todo quieto entre claves; el gesto no cambia a la vista.
const OPTIMIZAR_VELOCIDAD := 0.01
const OPTIMIZAR_ANGULO := 0.01
const OPTIMIZAR_PRECISION := 3


func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.size() < 2:
		push_error("Uso: -- <Assets/Animations> <salida>")
		quit(2)
		return
	var fallos := 0
	for sexo in CLIPS:
		if not _convertir(argumentos[0], argumentos[1], String(sexo)):
			fallos += 1
	quit(1 if fallos else 0)


func _convertir(origen: String, salida: String, sexo: String) -> bool:
	var escena: Node3D = null
	var biblioteca := AnimationLibrary.new()
	for clip in CLIPS[sexo]:
		var ruta := origen.path_join(CLIPS[sexo][clip]).path_join("%s_%s.max.fbx" % [sexo, clip])
		var fbx := FBXDocument.new()
		var estado := FBXState.new()
		if fbx.append_from_file(ruta, estado) != OK:
			push_error("No se pudo leer %s" % ruta)
			return false
		var cargada := fbx.generate_scene(estado) as Node3D
		var animacion := _animacion_limpia(cargada)
		if animacion == null:
			push_error("%s no trae animación" % ruta)
			cargada.free()
			return false
		biblioteca.add_animation(clip, animacion)
		if escena == null:
			escena = cargada
		else:
			cargada.free()
	root.add_child(escena)
	for nodo in escena.find_children("*", "", true, false):
		# Las huellas son un nodo con otro dentro del mismo nombre: al soltar
		# el de fuera, el de dentro ya no existe.
		if is_instance_valid(nodo) and String(nodo.name) in DESCARTADOS:
			nodo.get_parent().remove_child(nodo)
			nodo.free()
	var reproductor: AnimationPlayer = escena.find_children("*", "AnimationPlayer", true, false)[0]
	for nombre in reproductor.get_animation_library_list():
		reproductor.remove_animation_library(nombre)
	reproductor.add_animation_library(&"", biblioteca)
	_anclar_piel(escena.find_children("*", "Skeleton3D", true, false)[0])

	var gltf := GLTFDocument.new()
	var estado_gltf := GLTFState.new()
	var destino := salida.path_join("animaciones_%s.glb" % sexo)
	var error := gltf.append_from_scene(escena, estado_gltf)
	if error == OK:
		error = gltf.write_to_filesystem(estado_gltf, destino)
	escena.free()
	print("%s -> %s (%s)" % [sexo, destino, error_string(error)])
	return error == OK


## Un esqueleto sin malla sale del glTF como nodos sueltos: sin `skin` no hay
## `Skeleton3D` al importar, y el `BoneMap` no tiene a quién aplicarse. Un
## triángulo degenerado pesado a la pelvis basta para que el exportador escriba
## la piel con todos los huesos, igual que en los avatares. No se ve: nadie
## instancia esta escena, solo se leen sus animaciones.
func _anclar_piel(esqueleto: Skeleton3D) -> void:
	var pelvis := esqueleto.find_bone(PELVIS)
	var datos := []
	datos.resize(Mesh.ARRAY_MAX)
	datos[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
	datos[Mesh.ARRAY_BONES] = PackedInt32Array([pelvis, 0, 0, 0, pelvis, 0, 0, 0, pelvis, 0, 0, 0])
	datos[Mesh.ARRAY_WEIGHTS] = PackedFloat32Array([1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0])
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, datos)
	var ancla := MeshInstance3D.new()
	ancla.name = "Ancla"
	ancla.mesh = malla
	esqueleto.add_child(ancla)
	ancla.skeleton = ancla.get_path_to(esqueleto)
	ancla.skin = esqueleto.create_skin_from_rest_transforms()


## La única toma del FBX, sin las pistas de los nodos que se descartan.
func _animacion_limpia(escena: Node3D) -> Animation:
	var reproductor: AnimationPlayer = escena.find_children("*", "AnimationPlayer", true, false)[0]
	var nombres := reproductor.get_animation_list()
	if nombres.is_empty():
		return null
	var animacion: Animation = reproductor.get_animation(nombres[0]).duplicate()
	for pista in range(animacion.get_track_count() - 1, -1, -1):
		if not _se_conserva(animacion, pista):
			animacion.remove_track(pista)
	animacion.optimize(OPTIMIZAR_VELOCIDAD, OPTIMIZAR_ANGULO, OPTIMIZAR_PRECISION)
	return animacion


func _se_conserva(animacion: Animation, pista: int) -> bool:
	var ruta := animacion.track_get_path(pista)
	if ruta.get_subname_count() == 0:
		return false
	var hueso := String(ruta.get_concatenated_subnames())
	match animacion.track_get_type(pista):
		Animation.TYPE_POSITION_3D:
			return hueso == RAIZ or hueso == PELVIS
		Animation.TYPE_ROTATION_3D:
			if hueso == RAIZ:
				return true
			for prefijo in PREFIJOS_MAPEADOS:
				if hueso.begins_with(prefijo):
					return true
	return false
