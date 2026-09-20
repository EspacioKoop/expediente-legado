## Corrección visual posterior al montaje de `persona.fbx` para #275.
##
## El playtest del 17/09/2026 detectó dos problemas que las regresiones de nodos
## no veían: la cabeza procedural tomaba como altura la distancia `Head` →
## `HeadTop_End` del FBX (2–3 veces demasiado grande en este rig) y el cuerpo
## base seguía leyendo como un maniquí uniforme bajo las piezas de vestuario.
##
## Este pase no toca el Skeleton3D ni la física. Espera un frame a que
## `Modelos.persona()` y `VestuarioHumano3D` terminen, y después:
##
## - limita la cabeza procedural usando la distancia Hips → Head del mismo rig;
## - crea una cabeza low-poly de piel para humanos sin retrato específico;
## - convierte la malla importada en una capa oscura de pantalón/underlay, de
##   modo que torso, camisa, chaqueta y mangas se lean como ropa encima.
##
## Todo lo añadido son MeshInstance3D visuales; no se crean colisiones ni se
## reescala la figura completa.
extends Node

const RUTA_PERSONA := "res://assets/modelos/persona.fbx"
const MARCA := "correccion_visual_275"
const MARCA_IDENTIDAD := "vestuario_identidad_275"
const RATIO_CABEZA_TORSO := 0.34
const PIEL_CLARA := Color(0.80, 0.65, 0.52)
const PIEL_OSCURA := Color(0.52, 0.36, 0.27)


func _ready() -> void:
	get_tree().node_added.connect(_al_agregar_nodo)
	if get_tree().current_scene != null:
		_revisar_arbol(get_tree().current_scene)


func _al_agregar_nodo(nodo: Node) -> void:
	if String(nodo.scene_file_path) == RUTA_PERSONA:
		_corregir_diferido.call_deferred(nodo.get_instance_id())


func _revisar_arbol(nodo: Node) -> void:
	if String(nodo.scene_file_path) == RUTA_PERSONA:
		_corregir_diferido.call_deferred(nodo.get_instance_id())
	for hijo in nodo.get_children():
		_revisar_arbol(hijo)


## Igual que en el pase de vestuario: entre el aviso y el volcado la figura
## puede haberse liberado, y `MessageQueue` rechaza el argumento con un error
## antes de que la comprobación de validez pueda evitarlo.
func _corregir_diferido(id: int) -> void:
	var pieza := instance_from_id(id)
	if pieza is Node:
		await _corregir_despues(pieza)


func _corregir_despues(pieza: Node) -> void:
	await get_tree().process_frame
	if not is_instance_valid(pieza) or String(pieza.scene_file_path) != RUTA_PERSONA:
		return
	_corregir(pieza)


func _corregir(pieza: Node) -> void:
	var esqueleto := _buscar_esqueleto(pieza)
	if esqueleto == null or esqueleto.has_meta(MARCA):
		return

	var cadera := _buscar_hueso(esqueleto, ["Hips", "Pelvis"])
	var cabeza := _buscar_hueso(esqueleto, ["Head"])
	if cadera < 0 or cabeza < 0:
		return

	var alto_torso := absf(
		(
			esqueleto.get_bone_global_pose(cabeza).origin.y
			- esqueleto.get_bone_global_pose(cadera).origin.y
		)
	)
	alto_torso = maxf(alto_torso, 0.01)
	var alto_cabeza_objetivo := alto_torso * RATIO_CABEZA_TORSO

	var identidad := String(esqueleto.get_meta(MARCA_IDENTIDAD, ""))
	var color_base := _color_importado(pieza)
	var piel := _piel_para(identidad)
	var cara := _cara_procedural(esqueleto, cabeza)
	if cara != null:
		_ajustar_cara(cara, alto_cabeza_objetivo)
	else:
		_cabeza_generica(esqueleto, cabeza, alto_cabeza_objetivo, piel, identidad)

	# El FBX deja de hacer de «piel/ropa todo a la vez»: pasa a ser una capa
	# inferior oscura. El vestuario procedural que ya monta #589/#642 queda por
	# encima y la zona inferior se lee como pantalón, no como maniquí desnudo.
	_pintar_importado(pieza, color_base.darkened(0.38))
	esqueleto.set_meta(MARCA, true)


func _cara_procedural(esqueleto: Skeleton3D, hueso_cabeza: int) -> BoneAttachment3D:
	for hijo in esqueleto.get_children():
		if not hijo is BoneAttachment3D:
			continue
		var enganche := hijo as BoneAttachment3D
		if enganche.bone_idx != hueso_cabeza:
			continue
		for pieza in enganche.get_children():
			if pieza is MeshInstance3D and (pieza as MeshInstance3D).mesh is SphereMesh:
				return enganche
	return null


func _ajustar_cara(cara: BoneAttachment3D, alto_objetivo: float) -> void:
	var alto_actual := 0.0
	for hijo in cara.get_children():
		if not hijo is MeshInstance3D:
			continue
		var malla := hijo as MeshInstance3D
		if malla.mesh is SphereMesh:
			var esfera := malla.mesh as SphereMesh
			alto_actual = maxf(alto_actual, absf(malla.scale.y) * esfera.height)
	if alto_actual <= 0.0001:
		return
	# El objetivo ya está expresado en la escala real del rig. El mínimo 0.25
	# previo impedía alcanzarlo justo en las caras históricas grandes que motivan
	# este pase: si necesitan reducirse más, deben poder hacerlo.
	var factor := minf(alto_objetivo / alto_actual, 1.0)
	# Se encogen los rasgos, NO el enganche. Un `BoneAttachment3D` reescribe su
	# propia transformación desde la pose del hueso en cada fotograma, así que
	# la escala que se le ponía aquí desaparecía al siguiente y la cabeza de las
	# caras con retrato seguía midiendo media persona. Escalar posición y tamaño
	# de cada rasgo encoge el conjunto alrededor del mismo origen, que es lo que
	# la escala del enganche pretendía hacer.
	for rasgo in cara.get_children():
		if not rasgo is Node3D:
			continue
		var pieza := rasgo as Node3D
		pieza.position = pieza.position * factor
		pieza.scale = pieza.scale * factor
	cara.set_meta("ratio_cabeza_275", factor)


func _cabeza_generica(
	esqueleto: Skeleton3D, hueso_cabeza: int, alto: float, piel: Color, identidad: String
) -> void:
	var enganche := BoneAttachment3D.new()
	enganche.name = "CabezaHumana275"
	enganche.bone_idx = hueso_cabeza
	esqueleto.add_child(enganche)

	var cabeza := MeshInstance3D.new()
	cabeza.name = "PielCabeza275"
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 8
	esfera.rings = 5
	cabeza.mesh = esfera
	cabeza.position = Vector3(0.0, alto * 0.48, 0.0)
	cabeza.scale = Vector3(alto * 0.34, alto * 0.50, alto * 0.38)
	cabeza.material_override = _material(piel)
	enganche.add_child(cabeza)

	var cabello := MeshInstance3D.new()
	cabello.name = "Cabello275"
	var pelo := SphereMesh.new()
	pelo.radius = 1.0
	pelo.height = 2.0
	pelo.radial_segments = 8
	pelo.rings = 4
	cabello.mesh = pelo
	cabello.position = Vector3(0.0, alto * 0.82, -alto * 0.015)
	cabello.scale = Vector3(alto * 0.35, alto * 0.13, alto * 0.34)
	cabello.material_override = _material(_cabello_para(identidad))
	enganche.add_child(cabello)


func _piel_para(identidad: String) -> Color:
	if Modelos.PERFILES_FACIALES.has(identidad):
		return Modelos.PERFILES_FACIALES[identidad].get("piel", PIEL_CLARA)
	var semilla := absi(hash(identidad))
	return PIEL_OSCURA.lerp(PIEL_CLARA, float(semilla % 7) / 6.0)


func _cabello_para(identidad: String) -> Color:
	if Modelos.PERFILES_FACIALES.has(identidad):
		return Modelos.PERFILES_FACIALES[identidad].get("cabello", Color(0.08, 0.07, 0.06))
	var tono := 0.05 + float(absi(hash(identidad)) % 5) * 0.025
	return Color(tono, tono * 0.88, tono * 0.76)


func _color_importado(pieza: Node) -> Color:
	for malla in _mallas_importadas(pieza):
		var material := (malla as MeshInstance3D).material_override
		if material is ShaderMaterial:
			var valor = (material as ShaderMaterial).get_shader_parameter("color_base")
			if typeof(valor) == TYPE_COLOR:
				return valor
	return Color(0.42, 0.45, 0.50)


func _pintar_importado(pieza: Node, color: Color) -> void:
	var material := _material(color)
	for malla in _mallas_importadas(pieza):
		(malla as MeshInstance3D).material_override = material


func _mallas_importadas(nodo: Node) -> Array:
	var encontradas := []
	if nodo is MeshInstance3D and nodo.owner != null:
		encontradas.append(nodo)
	for hijo in nodo.get_children():
		encontradas.append_array(_mallas_importadas(hijo))
	return encontradas


func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	return material


func _buscar_esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null


func _buscar_hueso(esqueleto: Skeleton3D, nombres: Array) -> int:
	for nombre in nombres:
		var indice := esqueleto.find_bone(String(nombre))
		if indice >= 0:
			return indice
	return -1
