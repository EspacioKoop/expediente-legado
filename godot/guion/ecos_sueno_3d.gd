## Cuerpo del eco del día en la sala del sueño.
##
## `EcosSueno` decide quién y qué dice; aquí se le busca sitio y se le monta el
## mismo avatar que tiene en su tienda, con el mismo gesto a menos de la mitad
## de velocidad: la persona es la misma, el tiempo no.
##
## El sitio sale de la planta de la sala, lejos de la entrada, de la salida y
## de los sospechosos, igual que el sueño reparte sus figuras: al eco uno se lo
## encuentra, no lo tiene delante al llegar ni plantado en la puerta de salida.
## En las salas poligonales, que no tienen rejilla, se busca dentro del
## contorno un punto a unos pasos de la entrada (ni encima, ni al fondo), lejos
## de la salida y de las figuras, y con margen a los muros. Mira hacia la
## entrada.
class_name EcosSueno3D
extends RefCounted

const NOMBRE := "EcoDelDia"
const VELOCIDAD_GESTO := 0.42
## Distancia a la entrada que se busca en las salas poligonales: a la vista
## al llegar, pero no encima.
const DISTANCIA_POLIGONAL := 7.0
const MARGEN_MURO := 1.0
const SEPARACION := 2.5
## Las salas del sueño son oscuras a propósito y el eco se leía como una
## silueta más, que es justo lo que no es: se le tiene que ver la cara. Trae su
## propia luz, pálida y corta, que además es por donde se le encuentra.
const COLOR_LUZ := Color(0.86, 0.82, 0.96)
const ENERGIA_LUZ := 1.7
const ALCANCE_LUZ := 3.6


## Monta el eco que toque en esta sala y devuelve su interactuable, o null si
## en esta sala no hay nadie.
static func montar(
	mundo: Node3D, espacio: Dictionary, jornada: Dictionary
) -> CompaneroInteractivo3D:
	if mundo == null:
		return null
	var anterior := mundo.get_node_or_null(NOMBRE)
	if anterior != null:
		anterior.free()
	var pendientes = jornada.get("sueno_escenas", [])
	var quedan := maxi((pendientes as Array).size() - 1, 0) if pendientes is Array else 0
	var eco := EcosSueno.de_sala(jornada, quedan)
	if eco.is_empty():
		return null
	var dependiente: Dictionary = eco["dependiente"]

	var raiz := Node3D.new()
	raiz.name = NOMBRE
	raiz.position = sitio(espacio)
	var hacia: Vector3 = espacio.get("entrada", Vector3.ZERO) - raiz.position
	if Vector2(hacia.x, hacia.z).length() > 0.01:
		raiz.rotation.y = atan2(hacia.x, hacia.z)
	raiz.set_meta("dependiente", eco["id"])
	mundo.add_child(raiz)

	var cuerpo := Node3D.new()
	cuerpo.name = "Cuerpo"
	raiz.add_child(cuerpo)
	if Modelos.persona(cuerpo, String(dependiente["cuerpo"]), Color.WHITE, ""):
		var pieza := cuerpo.get_child(0) as Node3D
		AnimacionesUAL.reproducir(pieza, String(dependiente["gesto"]))
		var reproductor := Modelos._reproductor(pieza)
		if reproductor != null:
			reproductor.speed_scale = VELOCIDAD_GESTO

	var luz := OmniLight3D.new()
	luz.name = "LuzEco"
	luz.position = Vector3(0.0, 2.1, 0.7)
	luz.light_color = COLOR_LUZ
	luz.light_energy = ENERGIA_LUZ
	luz.omni_range = ALCANCE_LUZ
	luz.shadow_enabled = false
	raiz.add_child(luz)

	var charla := CompaneroInteractivo3D.new()
	charla.name = "Conversacion"
	charla.position = Vector3(0.0, 0.9, 0.0)
	charla.nombre_visible = TranslationServer.translate(String(dependiente["clave"]))
	charla.clave_dialogo = String(eco["frase"])
	charla.set_meta("dependiente", eco["id"])
	raiz.add_child(charla)
	return charla


## Dónde se pone el eco en [param espacio], en metros y a ras de suelo.
static func sitio(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salida := entrada
	var salidas: Array = espacio.get("salidas", [])
	if not salidas.is_empty():
		salida = salidas[0].get("pos", entrada)
	var contorno: Array = espacio.get("contorno", [])
	if not contorno.is_empty():
		return _sitio_poligonal(espacio, entrada, contorno)
	var bloques: Array = espacio.get("planta", [])
	if bloques.is_empty():
		return Vector3(entrada.x, 0.0, entrada.z + DISTANCIA_POLIGONAL * 0.5)
	var evitar := [_celda_de(bloques, entrada), _celda_de(bloques, salida)]
	for figura in espacio.get("figuras", []):
		evitar.append(_celda_de(bloques, figura.get("pos", Vector3.ZERO)))
	var celda: Vector2i = Planta.repartidas(bloques, 1, evitar)[0]
	var centro := Planta.centro_en_metros(bloques, celda)
	return Vector3(centro.x, 0.0, centro.z)


static func _sitio_poligonal(espacio: Dictionary, entrada: Vector3, contorno: Array) -> Vector3:
	var poligono := PackedVector2Array()
	var centro := Vector2.ZERO
	for vertice in contorno:
		poligono.append(vertice)
		centro += Vector2(vertice)
	centro /= float(poligono.size())
	var evitar: Array[Vector2] = []
	for salida in espacio.get("salidas", []):
		var pos: Vector3 = salida.get("pos", entrada)
		evitar.append(Vector2(pos.x, pos.z))
	for figura in espacio.get("figuras", []):
		var pos: Vector3 = figura.get("pos", entrada)
		evitar.append(Vector2(pos.x, pos.z))
	var desde := Vector2(entrada.x, entrada.z)
	var candidatos: Array[Vector2] = [centro]
	for vertice in poligono:
		for t in [0.3, 0.5, 0.7]:
			candidatos.append(centro.lerp(vertice, t))
	var mejor := centro
	var mejor_nota := INF
	for punto in candidatos:
		if not _dentro_con_margen(poligono, punto):
			continue
		var nota := absf(punto.distance_to(desde) - DISTANCIA_POLIGONAL)
		for otro in evitar:
			if punto.distance_to(otro) < SEPARACION:
				nota += 100.0
		if nota < mejor_nota:
			mejor_nota = nota
			mejor = punto
	return Vector3(mejor.x, 0.0, mejor.y)


## Dentro del polígono y a [constant MARGEN_MURO] de cualquier muro.
static func _dentro_con_margen(poligono: PackedVector2Array, punto: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(punto, poligono):
		return false
	for i in poligono.size():
		var a := poligono[i]
		var b := poligono[(i + 1) % poligono.size()]
		if Geometry2D.get_closest_point_to_segment(punto, a, b).distance_to(punto) < MARGEN_MURO:
			return false
	return true


## La celda cuyo centro cae más cerca de [param punto].
static func _celda_de(bloques: Array, punto: Vector3) -> Vector2i:
	var mejor := Vector2i.ZERO
	var mejor_distancia := INF
	for celda in Planta.celdas(bloques).keys():
		var centro := Planta.centro_en_metros(bloques, celda)
		var distancia := Vector2(centro.x - punto.x, centro.z - punto.z).length_squared()
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = celda
	return mejor
