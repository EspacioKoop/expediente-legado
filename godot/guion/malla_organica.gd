## Mallas que no son cajas.
##
## Todo lo que hay en este juego está hecho de cajas, y para una mesa o un muro
## está bien: una oficina de 1998 se parece más a eso que a un render. Para un
## bicho no: un gato de cajas es un gato de cajas, y se ve.
##
## Esto construye un TUBO a lo largo de una espina: una lista de puntos, cada
## uno con su radio, y anillos de N lados uniéndolos. Con eso se hace un cuerpo
## que se estrecha, una pata, una cola que se curva y una oreja (un tubo cuyo
## último radio es cero). No hace falta más geometría que esa para un animal, y
## lo que la hace parecer un animal es el perfil, no el número de caras.
##
## Los lados van POCOS a propósito (seis u ocho): es la misma decisión que las
## texturas de 64 píxeles y el temblor de vértices. Una malla suave aquí
## desentonaría más que una caja.
class_name MallaOrganica
extends RefCounted

## Los lados de cada anillo. Seis se lee como una máquina de 32 bits; con
## dieciséis, el gato es de otro juego.
const LADOS := 7


## Un tubo a lo largo de [param espina].
##
## Cada punto es `{"c": Vector3, "r": float}` (o `Vector2` para un radio
## elíptico: un cuerpo es más ancho que alto y eso es media parte de que
## parezca un lomo). Los extremos se tapan salvo que su radio sea cero, que es
## como se hace una punta.
static func tubo(espina: Array, lados: int = LADOS) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var anillos := []
	for punto in espina:
		anillos.append(_anillo(punto, lados))

	for i in range(anillos.size() - 1):
		var a: Array = anillos[i]
		var b: Array = anillos[i + 1]
		for j in lados:
			var k := (j + 1) % lados
			# Dos triángulos por cara. Si un anillo está degenerado (radio
			# cero) el triángulo sale con área nula y no se ve, que es
			# exactamente lo que se quiere en una punta.
			_triangulo(st, a[j], b[j], b[k])
			_triangulo(st, a[j], b[k], a[k])

	_tapa(st, anillos[0], espina[0]["c"], true, lados)
	_tapa(st, anillos[anillos.size() - 1], espina[espina.size() - 1]["c"], false, lados)

	st.generate_normals()
	return st.commit()


static func _anillo(punto: Dictionary, lados: int) -> Array:
	# El radio entra suelto (float o Vector2) y sale SIEMPRE como Vector2. El
	# tipo va escrito: inferirlo de un ternario con dos tipos distintos no
	# compila, y el guion entero se quedaba sin cargar por esta línea.
	var radio = punto["r"]
	var r: Vector2 = radio if radio is Vector2 else Vector2(radio, radio)
	var centro: Vector3 = punto["c"]
	var puntos := []
	for j in lados:
		var a := TAU * float(j) / float(lados)
		puntos.append(centro + Vector3(cos(a) * r.x, sin(a) * r.y, 0))
	return puntos


static func _tapa(
	st: SurfaceTool, anillo: Array, centro: Vector3, invertida: bool, lados: int
) -> void:
	for j in lados:
		var k := (j + 1) % lados
		if invertida:
			_triangulo(st, centro, anillo[k], anillo[j])
		else:
			_triangulo(st, centro, anillo[j], anillo[k])


static func _triangulo(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


## Un tubo ya colocado y girado, que es como se pega una pata a un cuerpo sin
## rehacer la espina en coordenadas del mundo.
static func pieza(
	raiz: Node3D, malla: ArrayMesh, pos: Vector3, giro: Vector3, color: Color
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.mesh = malla
	nodo.position = pos
	nodo.rotation = giro
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	nodo.material_override = material
	raiz.add_child(nodo)
	return nodo
