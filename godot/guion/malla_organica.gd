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
	for i in espina.size():
		# El anillo va perpendicular a la espina, no siempre de cara a Z: así
		# una cola que sube o una pata que baja no se aplastan en una lámina.
		var previo: Vector3 = espina[maxi(i - 1, 0)]["c"]
		var siguiente: Vector3 = espina[mini(i + 1, espina.size() - 1)]["c"]
		anillos.append(_anillo(espina[i], siguiente - previo, lados))

	for i in range(anillos.size() - 1):
		var a: Array = anillos[i]
		var b: Array = anillos[i + 1]
		var eje: Vector3 = (espina[i]["c"] + espina[i + 1]["c"]) / 2.0
		for j in lados:
			var k := (j + 1) % lados
			# Dos triángulos por cara. Si un anillo está degenerado (radio
			# cero) el triángulo sale con área nula y no se ve, que es
			# exactamente lo que se quiere en una punta.
			var hacia: Vector3 = (a[j] + a[k] + b[j] + b[k]) / 4.0 - eje
			_triangulo(st, a[j], b[j], b[k], hacia)
			_triangulo(st, a[j], b[k], a[k], hacia)

	var primero: Vector3 = espina[0]["c"]
	var ultimo: Vector3 = espina[espina.size() - 1]["c"]
	_tapa(st, anillos[0], primero, primero - espina[1]["c"], lados)
	_tapa(st, anillos[anillos.size() - 1], ultimo, ultimo - espina[espina.size() - 2]["c"], lados)

	st.generate_normals()
	return st.commit()


static func _anillo(punto: Dictionary, tangente: Vector3, lados: int) -> Array:
	# El radio entra suelto (float o Vector2) y sale SIEMPRE como Vector2. El
	# tipo va escrito: inferirlo de un ternario con dos tipos distintos no
	# compila, y el guion entero se quedaba sin cargar por esta línea.
	var radio = punto["r"]
	var r: Vector2 = radio if radio is Vector2 else Vector2(radio, radio)
	var centro: Vector3 = punto["c"]
	# `r.x` es siempre lo ancho (X) y `r.y` lo perpendicular a la vez a X y a
	# la espina: lo alto en un lomo, lo profundo en una pata.
	var t := tangente.normalized() if tangente.length() > 0.0001 else Vector3.FORWARD
	# El lado se toma de X proyectado, no de UP×tangente: ese producto cambia de
	# signo cuando la espina cruza la vertical y el anillo daba media vuelta,
	# estrangulando la pieza en una X (el corvejón del gato).
	var lado := Vector3.RIGHT - t * Vector3.RIGHT.dot(t)
	lado = lado.normalized() if lado.length() > 0.01 else Vector3.UP
	var arriba := t.cross(lado).normalized()
	var puntos := []
	for j in lados:
		var a := TAU * float(j) / float(lados)
		puntos.append(centro + lado * cos(a) * r.x + arriba * sin(a) * r.y)
	return puntos


static func _tapa(
	st: SurfaceTool, anillo: Array, centro: Vector3, hacia: Vector3, lados: int
) -> void:
	for j in lados:
		_triangulo(st, centro, anillo[j], anillo[(j + 1) % lados], hacia)


## Un triángulo con la cara vista hacia [param hacia]. El orden de los vértices
## decide qué cara pinta Godot, y depender del sentido en que se escribió la
## espina dejaba piezas del revés: el motor descartaba su exterior y el gato se
## veía hueco. Aquí se corrige triángulo a triángulo.
static func _triangulo(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, hacia: Vector3) -> void:
	st.add_vertex(a)
	if (b - a).cross(c - a).dot(hacia) > 0.0:
		st.add_vertex(c)
		st.add_vertex(b)
	else:
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
