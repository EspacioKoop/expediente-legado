extends SceneTree

## Smoke real del cuerpo del protagonista (#701).
##
## Monta `CuerpoJugador3D` dentro de un caminante de prueba —CharacterBody3D con
## su `Camara`— y comprueba el árbol que de verdad se ve en primera persona:
## `persona.fbx` vestida con el perfil configurable de la ficha,
## cabeza oculta bajo la cámara, manos de piel, gestos según la velocidad y
## ninguna colisión nueva.

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var caminante := CharacterBody3D.new()
	root.add_child(caminante)
	var camara := Camera3D.new()
	camara.name = "Camara"
	camara.position.y = 0.65
	caminante.add_child(camara)

	var cuerpo := CuerpoJugador3D.new()
	cuerpo.perfil = {"apariencia": {"avatar": "rocketbox/female_adult_07", "altura": 1.04}}
	caminante.add_child(cuerpo)
	for _i in 4:
		await process_frame

	var figura := cuerpo.figura()
	_comprobar(figura != null, "el cuerpo instancia una figura")
	if figura == null:
		_terminar()
		return
	_comprobar(
		String(figura.scene_file_path).ends_with("rocketbox/female_adult_07.glb"),
		"es el avatar Rocketbox que eligió la ficha",
	)
	var esqueleto := Modelos._esqueleto(figura)
	_comprobar(esqueleto != null, "la figura conserva su Skeleton3D")
	if esqueleto == null:
		_terminar()
		return

	_comprobar(
		String(esqueleto.get_meta("identidad_jugador", "")), "jugador", "marcado como jugador"
	)
	# El modificador actúa dentro de la actualización del esqueleto y Godot
	# restaura la pose después: la escala se lee en `skeleton_updated`.
	var cabeza := esqueleto.find_bone("Neck")
	var escalas_cabeza: Array[float] = []
	var medir := func() -> void: escalas_cabeza.append(esqueleto.get_bone_pose_scale(cabeza).x)
	esqueleto.skeleton_updated.connect(medir)
	for _i in 3:
		await process_frame
	esqueleto.skeleton_updated.disconnect(medir)
	_comprobar(
		not escalas_cabeza.is_empty() and escalas_cabeza.max() < 0.01,
		"cuello y cabeza se ocultan para que la cámara no vea su interior",
	)
	var cuello := esqueleto.find_bone("Neck")
	var cuello_y := (esqueleto.global_transform * esqueleto.get_bone_global_pose(cuello)).origin.y
	_comprobar(cuello_y < camara.global_position.y, "el cuello queda por debajo de la cámara")

	_comprobar(not _contiene_colision(cuerpo), "el cuerpo no añade colisiones")

	var reproductor := Modelos._reproductor(figura)
	_comprobar(cuerpo.estado, "reposo", "quieto, respira")
	cuerpo.animar(2.6)
	_comprobar(cuerpo.estado, "andar", "a paso normal, anda")
	_comprobar(
		String(reproductor.current_animation).ends_with("andar"), "andar usa el clip de andar"
	)
	_comprobar(reproductor.speed_scale > 1.0, "el paso se acelera con la velocidad")
	cuerpo.animar(4.4)
	_comprobar(cuerpo.estado, "correr", "a la carrera, corre")
	_comprobar(String(reproductor.current_animation).ends_with("run"), "correr usa run")
	_comprobar(is_equal_approx(reproductor.speed_scale, 1.0), "correr no reescala el clip")
	cuerpo.animar(0.0)
	_comprobar(String(reproductor.current_animation).ends_with("idle"), "al parar vuelve a idle")

	cuerpo.aplicar({"apariencia": {"avatar": "rocketbox/male_adult_12"}})
	for _i in 3:
		await process_frame
	_comprobar(cuerpo.get_child_count(), 1, "cambiar la ficha no acumula figuras")
	_comprobar(
		String(cuerpo.figura().scene_file_path).ends_with("male_adult_12.glb"),
		"cambiar de avatar cambia el cuerpo",
	)

	# Una ficha de antes de los avatares (complexión, piel...) cae en el primero.
	cuerpo.aplicar({"apariencia": {"cuerpo": "robusto", "piel": "#6f4936"}})
	for _i in 3:
		await process_frame
	_comprobar(
		String(cuerpo.figura().scene_file_path).ends_with(
			"%s.glb" % PerfilJugador.AVATARES[0]["id"]
		),
		"una ficha antigua recibe el primer avatar",
	)

	# El ánimo sale del estrés y de la hora, y cambia qué hace al esperar.
	_comprobar(CuerpoJugador3D.animo_de(0.8, 600), "nervioso", "estrés alto: nervioso")
	_comprobar(CuerpoJugador3D.animo_de(0.1, 19 * 60), "cansado", "de tarde: cansado")
	_comprobar(CuerpoJugador3D.animo_de(0.1, 600), "", "por la mañana, sin más")
	_comprobar(CuerpoJugador3D.variante_reposo("cansado", 0), "bostezar", "cansado bosteza")
	for animo in CuerpoJugador3D.VARIANTES:
		for clip in CuerpoJugador3D.VARIANTES[animo]:
			_comprobar(
				AnimacionesRocketbox.CLIPS.has(clip),
				true,
				"la espera usa un clip que existe: %s" % clip
			)
	# Quieto el rato suficiente, cambia de gesto y luego vuelve a respirar.
	cuerpo.animar(0.0)
	cuerpo._variar_reposo(CuerpoJugador3D.PAUSA_VARIANTE + 0.1, 0.0)
	var gesto := String(Modelos._reproductor(cuerpo.figura()).current_animation)
	_comprobar(not gesto.ends_with("idle"), true, "tras la pausa hace otra cosa (%s)" % gesto)
	cuerpo._variar_reposo(60.0, 0.0)
	cuerpo.animar(0.0)
	_comprobar(
		String(Modelos._reproductor(cuerpo.figura()).current_animation).ends_with("idle"),
		true,
		"y después vuelve a respirar",
	)

	# Todos los avatares de la ficha cargan y ninguno lo usa un compañero.
	for avatar in PerfilJugador.AVATARES:
		_comprobar(
			ResourceLoader.exists("%s%s.glb" % [Modelos.RUTA, avatar["id"]]),
			"%s existe" % avatar["id"],
		)
		_comprobar(
			not Companeros.CUERPOS.values().has(avatar["id"]),
			"%s no es de un compañero" % avatar["id"],
		)
	_terminar()


func _contiene_colision(nodo: Node) -> bool:
	if nodo is CollisionShape3D or nodo is CollisionPolygon3D:
		return true
	for hijo in nodo.get_children():
		if _contiene_colision(hijo):
			return true
	return false


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error(
		"FALLO Cuerpo del jugador #701: %s (actual=%s esperado=%s)" % [nombre, actual, esperado]
	)


func _terminar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)
