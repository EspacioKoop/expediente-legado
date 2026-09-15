## Pase visual no destructivo para las figuras humanas importadas.
##
## `Modelos.persona()` sigue siendo dueño de animación, materiales y rostro. Este
## autoload solo añade una silueta de ropa sobre `persona.fbx`: no cambia huesos,
## colisiones, navegación ni el asset fuente. Así podemos iterar #275 sin volver
## frágil el generador común ni deformar las animaciones existentes.
extends Node

const RUTA_PERSONA := "res://assets/modelos/persona.fbx"
const MARCA := "vestuario_humano_275"


func _ready() -> void:
	get_tree().node_added.connect(_al_agregar_nodo)
	if get_tree().current_scene != null:
		_revisar_arbol(get_tree().current_scene)


func _al_agregar_nodo(nodo: Node) -> void:
	if String(nodo.scene_file_path) == RUTA_PERSONA:
		call_deferred("_vestir_si_persona", nodo)


func _revisar_arbol(nodo: Node) -> void:
	if String(nodo.scene_file_path) == RUTA_PERSONA:
		_vestir_si_persona(nodo)
	for hijo in nodo.get_children():
		_revisar_arbol(hijo)


func _vestir_si_persona(pieza: Node) -> void:
	if not is_instance_valid(pieza) or String(pieza.scene_file_path) != RUTA_PERSONA:
		return
	var esqueleto := _buscar_esqueleto(pieza)
	if esqueleto == null or esqueleto.has_meta(MARCA):
		return

	var cadera := _buscar_hueso(esqueleto, ["Hips", "Pelvis"])
	var pecho := _buscar_hueso(esqueleto, ["Spine2", "Chest", "UpperChest", "Spine1", "Spine"])
	var cabeza := _buscar_hueso(esqueleto, ["Head"])
	if cadera < 0 or pecho < 0 or cabeza < 0:
		return

	# No escalamos ni retorcemos el esqueleto: la variedad corporal se expresa en
	# la silueta exterior. Eso conserva exactamente las animaciones del FBX.
	var clave := String(pieza.get_parent().name if pieza.get_parent() != null else pieza.name)
	var semilla := absi(hash(clave))
	var perfiles := [
		{"nombre": "estrecho", "ancho": 0.92, "fondo": 0.90, "largo": 1.04},
		{"nombre": "medio", "ancho": 1.00, "fondo": 0.96, "largo": 1.03},
		{"nombre": "robusto", "ancho": 1.07, "fondo": 1.03, "largo": 1.01},
	]
	var perfil: Dictionary = perfiles[semilla % perfiles.size()]
	var color_base := _color_base(pieza)
	var color_chaqueta := color_base.darkened(0.24)
	var color_camisa := color_base.lightened(0.22)
	var color_pantalon := color_base.darkened(0.34)

	var alto_torso := _distancia_vertical(esqueleto, cadera, cabeza)
	# Los FBX de este pack pueden traer escalas internas poco intuitivas. La
	# distancia entre huesos mantiene todo en el mismo espacio que el esqueleto.
	alto_torso = maxf(alto_torso, 0.01)
	# La captura de revisión mostraba un bloque corto y ancho, que hacía leer la
	# figura como muñeco cabezón. Se alarga la prenda y se adelgaza el volumen
	# central; los hombros recuperan anchura en una pieza propia, no engordando
	# todo el tronco.
	var ancho := alto_torso * 0.27 * float(perfil["ancho"])
	var fondo := alto_torso * 0.135 * float(perfil["fondo"])
	var largo := alto_torso * 0.47 * float(perfil["largo"])

	# Chaqueta/abrigo: volumen largo y estrecho, más cercano a una silueta humana
	# vestida que al bloque corto de la primera iteración.
	var torso := _enganche(esqueleto, pecho, "VestuarioTorso")
	_caja(
		torso,
		Vector3(ancho, largo, fondo),
		Vector3(0.0, -largo * 0.24, 0.0),
		color_chaqueta
	)

	# La línea de hombros se lee por separado. Así se puede ensanchar arriba sin
	# convertir abdomen y cintura en el mismo prisma grueso.
	var hombros := _enganche(esqueleto, pecho, "VestuarioHombros")
	_caja(
		hombros,
		Vector3(ancho * 1.18, largo * 0.12, fondo * 1.03),
		Vector3(0.0, -largo * 0.02, 0.0),
		color_chaqueta
	)

	# Camisa visible en el centro; una pieza fina rompe el bloque de chaqueta sin
	# recuperar la lectura de maniquí desnudo.
	_caja(
		torso,
		Vector3(ancho * 0.26, largo * 0.70, fondo * 1.035),
		Vector3(0.0, -largo * 0.21, -fondo * 0.025),
		color_camisa
	)

	# Cintura/pantalón: más estrecha que los hombros para recuperar la relación
	# torso-cadera sin tocar escala ni poses del esqueleto.
	var cintura := _enganche(esqueleto, cadera, "VestuarioCintura")
	_caja(
		cintura,
		Vector3(ancho * 0.78, largo * 0.18, fondo * 0.90),
		Vector3(0.0, largo * 0.04, 0.0),
		color_pantalon
	)

	# Mangas independientes cuando el rig expone brazos. Al estar cada una en su
	# hueso siguen el idle y futuras animaciones en lugar de flotar junto al torso.
	_poner_manga(
		esqueleto, ["LeftArm", "UpperArm_L", "upperarm_l"], alto_torso, ancho, color_chaqueta, "L"
	)
	_poner_manga(
		esqueleto, ["RightArm", "UpperArm_R", "upperarm_r"], alto_torso, ancho, color_chaqueta, "R"
	)

	esqueleto.set_meta(MARCA, String(perfil["nombre"]))


func _poner_manga(
	esqueleto: Skeleton3D,
	candidatos: Array[String],
	alto: float,
	ancho_torso: float,
	color: Color,
	sufijo: String
) -> void:
	var hueso := _buscar_hueso(esqueleto, candidatos)
	if hueso < 0:
		return
	var brazo := _enganche(esqueleto, hueso, "VestuarioManga" + sufijo)
	var malla := CapsuleMesh.new()
	malla.radius = ancho_torso * 0.085
	malla.height = maxf(alto * 0.27, malla.radius * 2.05)
	malla.radial_segments = 6
	malla.rings = 3
	var instancia := MeshInstance3D.new()
	instancia.mesh = malla
	instancia.position.y = -malla.height * 0.26
	instancia.material_override = _material(color)
	brazo.add_child(instancia)


func _enganche(esqueleto: Skeleton3D, hueso: int, nombre: String) -> BoneAttachment3D:
	var enganche := BoneAttachment3D.new()
	enganche.name = nombre
	enganche.bone_idx = hueso
	esqueleto.add_child(enganche)
	return enganche


func _caja(padre: Node3D, tam: Vector3, posicion: Vector3, color: Color) -> void:
	var malla := BoxMesh.new()
	malla.size = tam
	var instancia := MeshInstance3D.new()
	instancia.mesh = malla
	instancia.position = posicion
	instancia.material_override = _material(color)
	padre.add_child(instancia)


func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	return material


func _color_base(nodo: Node) -> Color:
	if nodo is MeshInstance3D:
		var material := nodo.material_override
		if material is ShaderMaterial:
			var parametro: Variant = material.get_shader_parameter("color_base")
			if parametro is Color:
				return parametro
	for hijo in nodo.get_children():
		var encontrado := _color_base_opcional(hijo)
		if encontrado != null:
			return encontrado
	return Color(0.36, 0.39, 0.42)


func _color_base_opcional(nodo: Node) -> Variant:
	if nodo is MeshInstance3D:
		var material := nodo.material_override
		if material is ShaderMaterial:
			var parametro: Variant = material.get_shader_parameter("color_base")
			if parametro is Color:
				return parametro
	for hijo in nodo.get_children():
		var encontrado: Variant = _color_base_opcional(hijo)
		if encontrado != null:
			return encontrado
	return null


func _buscar_esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null


func _buscar_hueso(esqueleto: Skeleton3D, candidatos: Array[String]) -> int:
	for candidato in candidatos:
		var exacto := esqueleto.find_bone(candidato)
		if exacto >= 0:
			return exacto
	for i in range(esqueleto.get_bone_count()):
		var nombre := String(esqueleto.get_bone_name(i)).to_lower()
		for candidato in candidatos:
			var buscado := candidato.to_lower()
			if nombre.ends_with(":" + buscado) or nombre.ends_with("_" + buscado):
				return i
	return -1


func _distancia_vertical(esqueleto: Skeleton3D, a: int, b: int) -> float:
	return absf(
		esqueleto.get_bone_global_pose(b).origin.y - esqueleto.get_bone_global_pose(a).origin.y
	)
