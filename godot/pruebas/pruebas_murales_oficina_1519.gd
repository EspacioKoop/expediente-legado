extends SceneTree

## #1519: cada capa mural de la oficina —pósteres (#443), láminas (#195),
## señalética (#1468) y reloj horario (#963)— elige sus coordenadas por su
## cuenta. Esta prueba las monta juntas, proyecta cada pieza sobre su pared y
## exige que ninguna pise a otra ni a lo que el catálogo ya cuelga o abre en
## esa pared: tablón, papeles, puerta y ventanas.

const Horario := preload("res://guion/dia_reloj_horario_app.gd")

## Hasta dónde se considera que algo está colgado de la pared.
const DISTANCIA_PARED := 0.30
## Un bulto del catálogo es mural si es así de fino en el eje de su pared.
const GROSOR_MURAL := 0.12

var pasadas := 0
var fallos := 0


func _init() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	PostersOficina.montar(mundo)
	CuadrosOficina.montar(mundo)
	SenaleticaOficina98.montar(mundo)
	var reloj := RelojOficina3D.new()
	reloj.name = "RelojJornadaOficina"
	reloj.position = Horario.POSICION_RELOJ
	mundo.add_child(reloj)
	# Fuera del árbol no hay _ready: poner la hora es lo que lo construye.
	reloj.poner_hora(Jornada.MINUTOS_INICIO_JORNADA)

	var piezas := []
	for capa in ["PostersOficina", "CuadrosOficina", "SenaleticaOficina98"]:
		for hijo in mundo.get_node(capa).get_children():
			piezas.append(_pieza("%s/%s" % [capa, hijo.name], _limites_globales(hijo)))
	piezas.append(_pieza("Reloj", _limites_globales(reloj)))
	comprobar("hay pósteres, láminas, señalética y reloj", piezas.size() >= 13, true)

	var sin_pared := []
	for pieza in piezas:
		if String(pieza["pared"]).is_empty():
			sin_pared.append(pieza["nombre"])
	comprobar("toda pieza cuelga de una pared", sin_pared, [])

	var obstaculos := _obstaculos_del_catalogo()
	comprobar("el catálogo aporta tablón, puerta y ventanas", obstaculos.size() >= 4, true)

	var solapes := []
	for i in piezas.size():
		for j in range(i + 1, piezas.size()):
			_anotar_solape(solapes, piezas[i], piezas[j])
		for obstaculo in obstaculos:
			_anotar_solape(solapes, piezas[i], obstaculo)
	comprobar("ninguna pieza mural pisa a otra", solapes, [])

	mundo.free()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _obstaculos_del_catalogo() -> Array:
	var resultado := []
	var bultos: Array = EspaciosCatalogo.OFICINA.get("bultos", [])
	var ventanas: Array = EspaciosCatalogo.OFICINA.get("ventanas", [])
	for indice in bultos.size() + ventanas.size():
		var es_ventana := indice >= bultos.size()
		var bulto: Dictionary = ventanas[indice - bultos.size()] if es_ventana else bultos[indice]
		var tam: Vector3 = bulto["tam"]
		var caja := AABB(Vector3(bulto["pos"]) - tam / 2.0, tam)
		var pieza := _pieza(
			"catálogo %s[%d]" % ["ventanas" if es_ventana else "bultos", indice], caja
		)
		var grosor := tam.z if pieza["pared"] in ["norte", "sur"] else tam.x
		if not String(pieza["pared"]).is_empty() and grosor <= GROSOR_MURAL:
			resultado.append(pieza)
	return resultado


## Clasifica una caja por la pared de la que cuelga y la proyecta en ella:
## (x, y) en norte/sur y (z, y) en este/oeste.
func _pieza(nombre: String, caja: AABB) -> Dictionary:
	var medio: Vector2 = EspaciosCatalogo.OFICINA["suelo"] / 2.0
	var centro := caja.get_center()
	var pared := ""
	var rect := Rect2()
	if absf(centro.z) > medio.y - DISTANCIA_PARED and caja.size.z <= caja.size.x:
		pared = "norte" if centro.z < 0.0 else "sur"
		rect = Rect2(caja.position.x, caja.position.y, caja.size.x, caja.size.y)
	elif absf(centro.x) > medio.x - DISTANCIA_PARED and caja.size.x <= caja.size.z:
		pared = "oeste" if centro.x < 0.0 else "este"
		rect = Rect2(caja.position.z, caja.position.y, caja.size.z, caja.size.y)
	return {"nombre": nombre, "pared": pared, "rect": rect}


func _anotar_solape(solapes: Array, a: Dictionary, b: Dictionary) -> void:
	if a["pared"] != b["pared"] or String(a["pared"]).is_empty():
		return
	var ra: Rect2 = a["rect"]
	var rb: Rect2 = b["rect"]
	if ra.intersects(rb):
		var zona := ra.intersection(rb)
		solapes.append(
			(
				"%s × %s en %s (%.2f × %.2f m)"
				% [a["nombre"], b["nombre"], a["pared"], zona.size.x, zona.size.y]
			)
		)


## Límites en coordenadas del mundo, que está en el origen. Se compone la
## cadena de transformaciones locales porque en `_init` nada está en el árbol.
func _limites_globales(nodo: Node3D) -> AABB:
	var mundo: Node3D = nodo
	while mundo.get_parent() is Node3D:
		mundo = mundo.get_parent()
	var total := AABB()
	var primero := true
	for malla in _mallas(nodo):
		var caja: AABB = Modelos._relativa(mundo, malla) * malla.get_aabb()
		total = caja if primero else total.merge(caja)
		primero = false
	return total


func _mallas(nodo: Node) -> Array:
	var encontradas := []
	if nodo is MeshInstance3D:
		encontradas.append(nodo)
	for hijo in nodo.get_children():
		encontradas.append_array(_mallas(hijo))
	return encontradas


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		print("FALLO %s: obtenido %s, esperado %s" % [nombre, obtenido, esperado])
