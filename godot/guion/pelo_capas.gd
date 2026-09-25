## Pelo por capas sobre la cabeza de un avatar Rocketbox (#275).
##
## Una barba hecha con esferas se lee como un parche pegado. Esta es la técnica
## de los juegos de pocos polígonos: se copia la parte de la piel que lleva
## pelo, se empuja hacia fuera por su normal en varias capas y el shader
## (`arte/pelo_capas.gdshader`) recorta en cada capa los mechones. Como las
## capas son la misma piel, con los mismos huesos y pesos, siguen a la cara
## cuando habla, gira o se inclina, y la barba nace exactamente donde acaba la
## piel en vez de flotar delante.
##
## Qué piel lleva pelo lo decide una máscara en el espacio del hueso Head: una
## función de la posición en reposo que devuelve 0 (piel) a 1 (pelo pleno).
## Cuánto sobresale lo da `largo` por la máscara, y `caida` lo inclina hacia
## abajo, que es lo que separa una barba de un felpudo.
extends RefCounted

const SHADER := "res://arte/pelo_capas.gdshader"


## Construye las capas y las cuelga junto a la malla de la cabeza. Devuelve la
## malla creada, o null si el avatar no tiene cabeza reconocible o la máscara
## no cubre nada.
static func crear(
	esqueleto: Skeleton3D, nombre: String, mascara: Callable, opciones: Dictionary
) -> MeshInstance3D:
	var cabeza := _superficie_cabeza(esqueleto)
	if cabeza.is_empty():
		return null
	var malla: MeshInstance3D = cabeza["malla"]
	var superficie: int = cabeza["superficie"]
	var hueso_cabeza := esqueleto.find_bone("Head")
	if hueso_cabeza < 0 or malla.skin == null:
		return null

	var datos: Array = malla.mesh.surface_get_arrays(superficie)
	var formato: int = malla.mesh.surface_get_format(superficie)
	var por_vertice := 8 if formato & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS else 4
	var posiciones: PackedVector3Array = datos[Mesh.ARRAY_VERTEX]
	var normales: PackedVector3Array = datos[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = datos[Mesh.ARRAY_TEX_UV]
	var huesos: PackedInt32Array = datos[Mesh.ARRAY_BONES]
	var pesos: PackedFloat32Array = datos[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = datos[Mesh.ARRAY_INDEX]

	var a_cabeza := esqueleto.get_bone_global_rest(hueso_cabeza).affine_inverse()
	var reposo := reposo_de_vinculos(esqueleto, malla.skin)
	var valores := PackedFloat32Array()
	valores.resize(posiciones.size())
	var abajo := PackedVector3Array()
	abajo.resize(posiciones.size())
	for i in posiciones.size():
		var t := _mezcla(reposo, huesos, pesos, i, por_vertice)
		var en_cabeza := a_cabeza * t * posiciones[i]
		valores[i] = clampf(float(mascara.call(en_cabeza)), 0.0, 1.0)
		# «Abajo» del mundo en reposo, traído al espacio de la malla del vértice.
		abajo[i] = (t.basis.inverse() * Vector3.DOWN).normalized()

	var triangulos := PackedInt32Array()
	for t in range(0, indices.size(), 3):
		var a := indices[t]
		var b := indices[t + 1]
		var c := indices[t + 2]
		# Basta un vértice dentro: en zonas estrechas (el bigote) los triángulos
		# son más grandes que la región, y exigir los tres la dejaba con agujeros.
		# Los vértices de fuera no se mueven y el shader recorta por la máscara.
		if valores[a] > 0.0 or valores[b] > 0.0 or valores[c] > 0.0:
			triangulos.append_array([a, b, c])
	if triangulos.is_empty():
		return null

	var capas: int = opciones.get("capas", 8)
	var largo: float = opciones.get("largo", 0.008)
	var caida: float = opciones.get("caida", 0.0)
	var n_v := PackedVector3Array()
	var n_n := PackedVector3Array()
	var n_uv := PackedVector2Array()
	var n_color := PackedColorArray()
	var n_huesos := PackedInt32Array()
	var n_pesos := PackedFloat32Array()
	var n_indices := PackedInt32Array()
	var usados := {}
	for i in triangulos:
		usados[i] = true
	var orden: Array = usados.keys()
	# La capa 0 es la base: la sombra cerrada sobre la que salen los pelos. Va a
	# milímetro y medio de la piel; con menos, a distancia de juego la piel gana
	# en profundidad y asoma a parches.
	for capa in range(0, capas + 1):
		var h := float(capa) / float(capas)
		var base := n_v.size()
		var nuevo := {}
		for j in orden.size():
			var i: int = orden[j]
			nuevo[i] = base + j
			var empuje := maxf(largo * h, 0.0015) * valores[i]
			var direccion := (normales[i] + abajo[i] * caida * h).normalized()
			# Los huesos de Rocketbox llevan la malla en centímetros o metros según
			# el avatar: el desplazamiento se mide en metros del esqueleto.
			var escala := _escala(reposo, huesos, pesos, i, por_vertice)
			n_v.append(posiciones[i] + direccion * empuje / escala)
			n_n.append(normales[i])
			n_uv.append(uvs[i])
			n_color.append(Color(h, valores[i], 0.0, 1.0))
			for k in por_vertice:
				n_huesos.append(huesos[i * por_vertice + k])
				n_pesos.append(pesos[i * por_vertice + k])
		for i in triangulos:
			n_indices.append(nuevo[i])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = n_v
	arrays[Mesh.ARRAY_NORMAL] = n_n
	arrays[Mesh.ARRAY_TEX_UV] = n_uv
	arrays[Mesh.ARRAY_COLOR] = n_color
	arrays[Mesh.ARRAY_BONES] = n_huesos
	arrays[Mesh.ARRAY_WEIGHTS] = n_pesos
	arrays[Mesh.ARRAY_INDEX] = n_indices
	var nueva := ArrayMesh.new()
	var bandera := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if por_vertice == 8 else 0
	nueva.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, bandera)

	var material := ShaderMaterial.new()
	material.shader = load(SHADER)
	material.set_shader_parameter("raiz", opciones.get("raiz", Color(0.1, 0.08, 0.06)))
	material.set_shader_parameter("punta", opciones.get("punta", Color(0.3, 0.26, 0.21)))
	material.set_shader_parameter("densidad", opciones.get("densidad", 520.0))
	material.set_shader_parameter("variacion", opciones.get("variacion", 0.35))
	material.set_shader_parameter("cobertura", opciones.get("cobertura", 0.85))
	material.set_meta("identidad_historica_275", true)

	var capa_malla := MeshInstance3D.new()
	capa_malla.name = nombre
	capa_malla.mesh = nueva
	capa_malla.material_override = material
	capa_malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	malla.get_parent().add_child(capa_malla)
	capa_malla.transform = malla.transform
	capa_malla.skin = malla.skin
	capa_malla.skeleton = capa_malla.get_path_to(esqueleto)
	return capa_malla


## Para cada vínculo de la piel, la transformación que lleva la malla en
## reposo al espacio del esqueleto: el rest global del hueso por su bind pose.
static func reposo_de_vinculos(esqueleto: Skeleton3D, piel: Skin) -> Array:
	var reposo := []
	for b in piel.get_bind_count():
		var hueso := piel.get_bind_bone(b)
		if hueso < 0:
			hueso = esqueleto.find_bone(piel.get_bind_name(b))
		var rest := esqueleto.get_bone_global_rest(hueso) if hueso >= 0 else Transform3D()
		reposo.append(rest * piel.get_bind_pose(b))
	return reposo


## Posiciones en reposo, en el espacio del hueso Head, de los vértices de la
## superficie [param superficie]. La usan las pruebas para medir dónde cae cada
## capa a partir de la malla ya construida, no de las máscaras que la hicieron.
static func vertices_en_cabeza(
	esqueleto: Skeleton3D, malla: MeshInstance3D, superficie: int
) -> PackedVector3Array:
	var datos: Array = malla.mesh.surface_get_arrays(superficie)
	var formato: int = malla.mesh.surface_get_format(superficie)
	var por_vertice := 8 if formato & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS else 4
	var reposo := reposo_de_vinculos(esqueleto, malla.skin)
	var a_cabeza := esqueleto.get_bone_global_rest(esqueleto.find_bone("Head")).affine_inverse()
	var posiciones: PackedVector3Array = datos[Mesh.ARRAY_VERTEX]
	var salida := PackedVector3Array()
	for i in posiciones.size():
		var t := _mezcla(reposo, datos[Mesh.ARRAY_BONES], datos[Mesh.ARRAY_WEIGHTS], i, por_vertice)
		salida.append(a_cabeza * t * posiciones[i])
	return salida


static func _mezcla(
	reposo: Array, huesos: PackedInt32Array, pesos: PackedFloat32Array, i: int, n: int
) -> Transform3D:
	var suma := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO)
	var total := 0.0
	for k in n:
		var w := pesos[i * n + k]
		if w <= 0.0:
			continue
		var t: Transform3D = reposo[huesos[i * n + k]]
		suma.basis.x += t.basis.x * w
		suma.basis.y += t.basis.y * w
		suma.basis.z += t.basis.z * w
		suma.origin += t.origin * w
		total += w
	if total <= 0.0:
		return Transform3D()
	return suma


static func _escala(
	reposo: Array, huesos: PackedInt32Array, pesos: PackedFloat32Array, i: int, n: int
) -> float:
	return maxf(_mezcla(reposo, huesos, pesos, i, n).basis.get_scale().x, 0.0001)


## La superficie de la cabeza: Rocketbox la nombra `<modelo>_head`.
static func _superficie_cabeza(esqueleto: Skeleton3D) -> Dictionary:
	for nodo in esqueleto.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		if malla.mesh == null or malla.skin == null:
			continue
		for s in malla.mesh.get_surface_count():
			if String(malla.mesh.surface_get_name(s)).ends_with("_head"):
				return {"malla": malla, "superficie": s}
	return {}
