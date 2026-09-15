extends SceneTree

const CorchoScript := preload("res://guion/corcho.gd")
const Corcho3DScript := preload("res://guion/corcho_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_layout_acotado()
	_probar_presentacion_interactiva()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_layout_acotado() -> void:
	var jornada := {}
	var conceptos := _conceptos(24)
	_comprobar(CorchoScript.sincronizar(jornada, conceptos), "sincroniza conceptos nuevos")
	var fichas: Dictionary = CorchoScript.estado(jornada)["fichas"]
	_comprobar(fichas.size() == 24, "mantiene todas las fichas descubiertas")

	fichas["entrada_rota"] = "dato legado inválido"
	var limite := Vector2(1.03, 0.57)
	_comprobar(CorchoScript.limitar_posiciones(jornada, limite), "sanea posiciones fuera de área")
	fichas = CorchoScript.estado(jornada)["fichas"]
	_comprobar(typeof(fichas["entrada_rota"]) == TYPE_DICTIONARY, "repara una entrada antigua corrupta")

	for id in fichas:
		var datos: Dictionary = fichas[id]
		var pos: Array = datos.get("pos", [])
		_comprobar(pos.size() >= 2, "%s conserva posición válida" % id)
		if pos.size() < 2:
			continue
		_comprobar(absf(float(pos[0])) <= limite.x + 0.001, "%s queda dentro del ancho" % id)
		_comprobar(absf(float(pos[1])) <= limite.y + 0.001, "%s queda dentro del alto" % id)

	_comprobar(not CorchoScript.limitar_posiciones(jornada, limite), "el saneado es idempotente")


func _probar_presentacion_interactiva() -> void:
	var jornada := {}
	var conceptos := [
		{"id": "a", "nombre": "Alpha"},
		{"id": "b", "nombre": "Beta"},
		{"id": "c", "nombre": "Gamma"},
	]
	var corcho := Corcho3DScript.new()
	root.add_child(corcho)
	corcho.configurar(jornada, conceptos)

	_comprobar(corcho.position == Corcho3DScript.POSICION, "usa la posición doméstica canónica")
	var tablero := corcho.get_node_or_null("TablonCorcho") as MeshInstance3D
	var marco := corcho.get_node_or_null("MarcoCorcho") as MeshInstance3D
	var etiqueta := corcho.get_node_or_null("EtiquetaCorcho") as MeshInstance3D
	var instruccion := corcho.get_node_or_null("InstruccionCorcho") as MeshInstance3D
	_comprobar(tablero != null, "monta el tablero físico")
	_comprobar(marco != null, "monta un marco reconocible")
	_comprobar(etiqueta != null, "identifica el corcho físicamente")
	_comprobar(instruccion != null, "explica el gesto de dos fichas en el mundo")
	if tablero != null:
		var caja := tablero.mesh as BoxMesh
		_comprobar(caja != null and caja.size.x < 3.0, "el tablero deja de dominar la pared")
	if etiqueta != null:
		var texto := etiqueta.get_node_or_null("Texto") as Label3D
		_comprobar(texto != null and texto.text == "CORCHO DE CONCEPTOS", "la etiqueta aclara qué objeto es")
	if instruccion != null:
		var texto := instruccion.get_node_or_null("Texto") as Label3D
		_comprobar(texto != null and texto.text.contains("DOS FICHAS"), "la instrucción aclara cómo acceder")

	var ficha_a := corcho.get_node_or_null("Ficha_a") as Interactuable3D
	var ficha_b := corcho.get_node_or_null("Ficha_b") as Interactuable3D
	_comprobar(ficha_a != null and ficha_b != null, "materializa fichas interactuables")
	if ficha_a == null or ficha_b == null:
		corcho.queue_free()
		return
	_comprobar(ficha_a.texto_accion() == "Usar ficha «Alpha»", "el prompt nombra la ficha como objeto")

	var papel_a := ficha_a.get_node_or_null("Papel") as MeshInstance3D
	var material_a := papel_a.material_override as StandardMaterial3D if papel_a != null else null
	_comprobar(material_a != null, "la ficha expone papel visible")
	_comprobar(ficha_a.interactuar(root), "permite seleccionar la primera ficha")
	if material_a != null:
		_comprobar(material_a.albedo_color == Corcho3DScript.COLOR_FICHA_SELECCIONADA, "marca la primera selección")
	_comprobar(ficha_b.interactuar(root), "permite completar el par")
	_comprobar(CorchoScript.estado(jornada)["enlaces"].size() == 1, "dos fichas crean un hilo manual")
	if material_a != null:
		_comprobar(material_a.albedo_color == Corcho3DScript.COLOR_FICHA, "limpia el feedback al completar el par")

	_comprobar(ficha_b.interactuar(root), "permite iniciar el mismo par en orden inverso")
	_comprobar(ficha_a.interactuar(root), "permite completar el mismo par en orden inverso")
	_comprobar(CorchoScript.estado(jornada)["enlaces"].is_empty(), "el mismo par retira el hilo")
	corcho.queue_free()


func _conceptos(cantidad: int) -> Array:
	var resultado := []
	for indice in range(cantidad):
		resultado.append({"id": "c%02d" % indice, "nombre": "Concepto %02d" % indice})
	return resultado


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Corcho: " + nombre)
