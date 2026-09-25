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
	cuerpo.perfil = {
		"apariencia":
		{
			"cuerpo": "robusto",
			"prenda": "jersey",
			"hombros": 1.10,
			"piel": "#6f4936",
			"ropa": "#45566e",
		},
	}
	caminante.add_child(cuerpo)
	for _i in 4:
		await process_frame

	var figura := cuerpo.figura()
	_comprobar(figura != null, "el cuerpo instancia una figura")
	if figura == null:
		_terminar()
		return
	_comprobar(
		String(figura.scene_file_path) == "res://assets/modelos/persona.fbx",
		"es persona.fbx, el rig configurable del protagonista",
	)
	var esqueleto := Modelos._esqueleto(figura)
	_comprobar(esqueleto != null, "la figura conserva su Skeleton3D")
	if esqueleto == null:
		_terminar()
		return

	_comprobar(
		String(esqueleto.get_meta("vestuario_humano_275", "")),
		"jugador_robusto",
		"viste la complexión de la ficha y no un perfil por hash",
	)
	_comprobar(
		String(esqueleto.get_meta("vestuario_identidad_275", "")),
		"jugador",
		"la identidad queda marcada como jugador",
	)
	_comprobar(
		esqueleto.find_child("VestuarioTorso", true, false) is BoneAttachment3D,
		"lleva el torso del vestuario anclado al rig",
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

	var manos := 0
	for nodo in esqueleto.find_children("Piel", "MeshInstance3D", true, false):
		var material := (nodo as MeshInstance3D).material_override as ShaderMaterial
		if material != null:
			var color: Color = material.get_shader_parameter("color_base")
			if color.is_equal_approx(Color("#6f4936")):
				manos += 1
	_comprobar(manos, 2, "las dos manos van en el tono de piel de la ficha")
	_comprobar(not _contiene_colision(cuerpo), "el cuerpo no añade colisiones")

	var reproductor := Modelos._reproductor(figura)
	_comprobar(cuerpo.estado, "reposo", "quieto, respira")
	cuerpo.animar(2.6)
	_comprobar(cuerpo.estado, "andar", "a paso normal, anda")
	_comprobar(String(reproductor.current_animation), "ual/andar", "andar usa Walk_Formal de UAL")
	_comprobar(reproductor.speed_scale > 1.0, "el paso se acelera con la velocidad")
	cuerpo.animar(4.4)
	_comprobar(cuerpo.estado, "correr", "a la carrera, corre")
	_comprobar(String(reproductor.current_animation).ends_with("Run"), "correr usa Run")
	_comprobar(is_equal_approx(reproductor.speed_scale, 1.0), "correr no reescala el clip")
	cuerpo.animar(0.0)
	_comprobar(String(reproductor.current_animation).ends_with("Idle"), "al parar vuelve a Idle")

	cuerpo.aplicar({"apariencia": {"cuerpo": "delgado", "prenda": "camisa"}})
	for _i in 3:
		await process_frame
	_comprobar(cuerpo.get_child_count(), 1, "cambiar la ficha no acumula figuras")
	var nueva := Modelos._esqueleto(cuerpo.figura())
	_comprobar(
		String(nueva.get_meta("vestuario_humano_275", "")),
		"jugador_estrecho",
		"delgado usa el perfil estrecho del vestuario",
	)

	# En la ficha exterior, ninguna superficie que representa piel puede heredar
	# el color de ropa del underlay. Cabeza + cuello + dos manos deben llevar el
	# tono de piel solicitado aunque la ropa tenga un color muy distinto.
	var exterior := CuerpoJugador3D.new()
	exterior.primera_persona = false
	exterior.perfil = {
		"apariencia":
		{
			"piel": "#7a4d36",
			"cabello": "#201913",
			"ropa": "#284f83",
			"peinado": "recogido",
		},
	}
	caminante.add_child(exterior)
	for _i in 3:
		await process_frame
	var esqueleto_exterior := Modelos._esqueleto(exterior.figura())
	_comprobar(esqueleto_exterior != null, "la previsualización conserva su Skeleton3D")
	if esqueleto_exterior != null:
		var piel_visible := 0
		for nombre in ["PielCabeza", "PielCuello", "Piel"]:
			for nodo in esqueleto_exterior.find_children(nombre, "MeshInstance3D", true, false):
				var material := (nodo as MeshInstance3D).material_override as ShaderMaterial
				if material != null:
					var color: Color = material.get_shader_parameter("color_base")
					if color.is_equal_approx(Color("#7a4d36")):
						piel_visible += 1
		_comprobar(piel_visible, 4, "cabeza, cuello y manos usan el tono de piel de la ficha")
		_comprobar(
			esqueleto_exterior.find_child("PielCuelloJugador", true, false) is BoneAttachment3D,
			"el cuello visible tiene una capa de piel separada del underlay",
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
