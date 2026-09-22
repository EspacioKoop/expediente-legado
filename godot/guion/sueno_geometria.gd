## Geometría no ortogonal para las salas del sueño (#279).
##
## Esta capa es deliberadamente independiente de `Espacio3D`: convierte un
## contorno 2D arbitrario en una malla cerrada de suelo, techo y paredes. Así el
## sueño puede dejar de depender visualmente de celdas `Rect2i` sin cambiar aún
## la navegación, las salidas ni el contenido procedente del día.
class_name SuenoGeometria
extends RefCounted


static func malla_sala(
	contorno: PackedVector2Array, altura: float = 3.2, tabiques: Array = []
) -> ArrayMesh:
	if not contorno_valido(contorno) or altura <= 0.0:
		return ArrayMesh.new()

	var indices := Geometry2D.triangulate_polygon(contorno)
	if indices.is_empty():
		return ArrayMesh.new()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_agregar_suelo_y_techo(st, contorno, indices, altura)
	_agregar_paredes(st, contorno, altura)
	_agregar_tabiques(st, tabiques)
	st.generate_normals()
	return st.commit()


## La misma geometría visible también define la colisión.
##
## Una malla poligonal superpuesta a una planta de cajas no sirve como corte de
## runtime: el jugador vería paredes diagonales pero chocaría con los antiguos
## Rect2i. El cuerpo estático evita esa divergencia generando el trimesh desde
## el ArrayMesh exacto que se dibuja. `ConcavePolygonShape3D` es apropiado aquí
## porque nunca se usa como cuerpo dinámico, solo como arquitectura inmóvil.
static func cuerpo_sala(
	contorno: PackedVector2Array, altura: float = 3.2, tabiques: Array = []
) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	var malla := malla_sala(contorno, altura, tabiques)
	if malla.get_surface_count() == 0:
		return cuerpo

	var visual := MeshInstance3D.new()
	visual.name = "Malla"
	visual.mesh = malla
	cuerpo.add_child(visual)

	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	var forma := malla.create_trimesh_shape()
	# El trimesh es hueco y por defecto solo colisiona por la cara de su normal.
	# En las salas cerradas el jugador debe poder pisar el suelo desde dentro
	# con independencia del winding de la triangulación del contorno.
	forma.backface_collision = true
	colision.shape = forma
	cuerpo.add_child(colision)
	return cuerpo


static func contorno_valido(contorno: PackedVector2Array) -> bool:
	if contorno.size() < 3:
		return false
	return absf(_area_firmada(contorno)) > 0.001


static func tiene_arista_diagonal(contorno: PackedVector2Array) -> bool:
	if contorno.size() < 2:
		return false
	for i in contorno.size():
		var a := contorno[i]
		var b := contorno[(i + 1) % contorno.size()]
		var delta := b - a
		if not is_zero_approx(delta.x) and not is_zero_approx(delta.y):
			return true
	return false


static func _agregar_suelo_y_techo(
	st: SurfaceTool, contorno: PackedVector2Array, indices: PackedInt32Array, altura: float
) -> void:
	for i in range(0, indices.size(), 3):
		var a := contorno[indices[i]]
		var b := contorno[indices[i + 1]]
		var c := contorno[indices[i + 2]]
		_triangulo(st, _punto(a, 0.0), _punto(c, 0.0), _punto(b, 0.0))
		_triangulo(st, _punto(a, altura), _punto(b, altura), _punto(c, altura))


static func _agregar_paredes(st: SurfaceTool, contorno: PackedVector2Array, altura: float) -> void:
	for i in contorno.size():
		var a := contorno[i]
		var b := contorno[(i + 1) % contorno.size()]
		var abajo_a := _punto(a, 0.0)
		var abajo_b := _punto(b, 0.0)
		var arriba_a := _punto(a, altura)
		var arriba_b := _punto(b, altura)
		_triangulo(st, abajo_a, abajo_b, arriba_b)
		_triangulo(st, abajo_a, arriba_b, arriba_a)


## Tabiques abiertos para la familia fragmentada (#279).
##
## Son planos, no cajas: cada segmento deja sus extremos libres para conservar
## rutas alternativas andando. Las alturas distintas rompen también la silueta
## horizontal sin introducir saltos ni plataformas de precisión.
static func _agregar_tabiques(st: SurfaceTool, tabiques: Array) -> void:
	for dato in tabiques:
		if not (dato is Dictionary):
			continue
		var tabique: Dictionary = dato
		var desde: Vector2 = tabique.get("desde", Vector2.ZERO)
		var hasta: Vector2 = tabique.get("hasta", Vector2.ZERO)
		if desde.is_equal_approx(hasta):
			continue
		var altura_desde := maxf(float(tabique.get("altura_desde", 1.4)), 0.2)
		var altura_hasta := maxf(float(tabique.get("altura_hasta", altura_desde)), 0.2)
		var abajo_desde := _punto(desde, 0.0)
		var abajo_hasta := _punto(hasta, 0.0)
		var arriba_desde := _punto(desde, altura_desde)
		var arriba_hasta := _punto(hasta, altura_hasta)
		# Dos caras: el shader puede hacer culling aunque la colisión trimesh
		# acepte contacto por ambas gracias a backface_collision.
		_triangulo(st, abajo_desde, abajo_hasta, arriba_hasta)
		_triangulo(st, abajo_desde, arriba_hasta, arriba_desde)
		_triangulo(st, abajo_hasta, abajo_desde, arriba_desde)
		_triangulo(st, abajo_hasta, arriba_desde, arriba_hasta)


static func _punto(punto: Vector2, altura: float) -> Vector3:
	return Vector3(punto.x, altura, punto.y)


static func _area_firmada(contorno: PackedVector2Array) -> float:
	var area := 0.0
	for i in contorno.size():
		var a := contorno[i]
		var b := contorno[(i + 1) % contorno.size()]
		area += a.x * b.y - b.x * a.y
	return area * 0.5


static func _triangulo(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
