extends SceneTree

const CorchoScript := preload("res://guion/corcho.gd")
const Corcho3DScript := preload("res://guion/corcho_3d.gd")
const CorchoPanelScript := preload("res://guion/corcho_panel.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_layout_acotado()
	_probar_mover_acotado()
	_probar_presentacion_pared()
	_probar_panel()
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
	_comprobar(
		typeof(fichas["entrada_rota"]) == TYPE_DICTIONARY, "repara una entrada antigua corrupta"
	)

	for id in fichas:
		var datos: Dictionary = fichas[id]
		var pos: Array = datos.get("pos", [])
		_comprobar(pos.size() >= 2, "%s conserva posición válida" % id)
		if pos.size() < 2:
			continue
		_comprobar(absf(float(pos[0])) <= limite.x + 0.001, "%s queda dentro del ancho" % id)
		_comprobar(absf(float(pos[1])) <= limite.y + 0.001, "%s queda dentro del alto" % id)

	_comprobar(not CorchoScript.limitar_posiciones(jornada, limite), "el saneado es idempotente")


func _probar_mover_acotado() -> void:
	var jornada := {}
	CorchoScript.sincronizar(jornada, [{"id": "a", "nombre": "Alpha"}])
	var borde: Vector2 = CorchoScript.limite()
	_comprobar(borde.is_equal_approx(Vector2(1.035, 0.57)), "el área útil lógica no cambia")
	_comprobar(CorchoScript.mover(jornada, "a", Vector2(0.3, -0.2)), "mueve una ficha existente")
	var pos: Array = CorchoScript.estado(jornada)["fichas"]["a"]["pos"]
	_comprobar(is_equal_approx(pos[0], 0.3) and is_equal_approx(pos[1], -0.2), "guarda la posición")
	_comprobar(
		not CorchoScript.mover(jornada, "a", Vector2(0.3, -0.2)), "no marca cambio sin mover"
	)
	CorchoScript.mover(jornada, "a", Vector2(9.0, -9.0))
	pos = CorchoScript.estado(jornada)["fichas"]["a"]["pos"]
	_comprobar(
		is_equal_approx(pos[0], borde.x) and is_equal_approx(pos[1], -borde.y),
		"no deja sacar la ficha del tablón"
	)
	_comprobar(not CorchoScript.mover(jornada, "fantasma", Vector2.ZERO), "no crea fichas al mover")


func _probar_presentacion_pared() -> void:
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
	_comprobar(tablero != null, "monta el tablero físico")
	_comprobar(marco != null, "monta un marco reconocible")
	if marco != null:
		var caja := marco.mesh as BoxMesh
		_comprobar(
			caja != null and caja.size.x <= 1.0 and caja.size.y <= 0.65,
			"el corcho tiene tamaño real (≈0,9 × 0,6 m)"
		)
	# Detrás del tabique del dormitorio y lejos de la ventana (#785).
	var ventana_x := Vector2(-3.0, -1.2)
	var medio_ancho: float = Corcho3DScript.TAM_TABLON.x * 0.5 + Corcho3DScript.MARCO
	_comprobar(Corcho3DScript.POSICION.z > -3.0, "no cuelga en el muro de la ventana")
	_comprobar(
		Corcho3DScript.POSICION.x + medio_ancho < 0.55 - 0.09,
		"no invade el tabique lateral ni otra habitación"
	)
	_comprobar(ventana_x.x < ventana_x.y, "rango de ventana coherente")

	var uso := corcho.get_node_or_null("UsarCorcho") as Interactuable3D
	_comprobar(uso != null, "el tablón entero es interactuable")
	if uso != null:
		_comprobar(uso.texto_accion() == "Usar corcho de conceptos", "el prompt nombra el corcho")
		var pedidos := [0]
		corcho.abrir_pedido.connect(func() -> void: pedidos[0] += 1)
		_comprobar(uso.interactuar(root), "usar el corcho se acepta")
		_comprobar(pedidos[0] == 1, "usar el corcho pide su interfaz")

	var ficha_a := corcho.find_child("Ficha_a", true, false) as Node3D
	_comprobar(ficha_a != null, "clava las fichas en la pared")
	_comprobar(
		not (ficha_a is Interactuable3D), "en la pared no se reordena: las fichas no son botones"
	)
	CorchoScript.mover(jornada, "a", Vector2(0.5, 0.25))
	CorchoScript.alternar_enlace(jornada, "a", "b")
	corcho.refrescar()
	ficha_a = corcho.find_child("Ficha_a", true, false) as Node3D
	_comprobar(
		(
			ficha_a != null
			and is_equal_approx(ficha_a.position.x, 0.5 * Corcho3DScript.ESCALA)
			and is_equal_approx(ficha_a.position.y, 0.25 * Corcho3DScript.ESCALA)
		),
		"la pared refleja el nuevo orden al refrescar"
	)
	var hilos := corcho.get_node_or_null("Hilos")
	_comprobar(hilos != null and hilos.get_child_count() == 1, "la pared dibuja el hilo manual")
	corcho.queue_free()


func _probar_panel() -> void:
	var jornada := {}
	var conceptos := {
		"a": {"id": "a", "nombre": "Alpha"},
		"b": {"id": "b", "nombre": "Beta"},
		"c": {"id": "c", "nombre": "Gamma"},
	}
	CorchoScript.sincronizar(jornada, conceptos.values())
	var panel := CorchoPanelScript.new()
	panel.configurar(jornada, conceptos)
	root.add_child(panel)
	panel.size = Vector2(1280, 720)
	var cambios := [0, 0]
	panel.cambiado.connect(func() -> void: cambios[0] += 1)
	panel.cerrado.connect(func() -> void: cambios[1] += 1)

	var boton_a: Button = panel.boton_de("a")
	var boton_b: Button = panel.boton_de("b")
	_comprobar(boton_a != null and boton_b != null, "la interfaz monta una ficha por concepto")
	if boton_a == null or boton_b == null:
		panel.queue_free()
		return
	_comprobar(boton_a.focus_mode == Control.FOCUS_ALL, "las fichas se eligen con teclado y mando")

	panel.pulsar("a")
	_comprobar(panel.seleccion() == "a", "el primer toque marca la ficha")
	panel.pulsar("b")
	_comprobar(CorchoScript.estado(jornada)["enlaces"].size() == 1, "dos fichas crean un hilo")
	_comprobar(panel.seleccion().is_empty(), "completar el par limpia la marca")
	_comprobar(cambios[0] == 1, "poner hilo avisa del cambio")
	panel.pulsar("b")
	panel.pulsar("a")
	_comprobar(CorchoScript.estado(jornada)["enlaces"].is_empty(), "el mismo par retira el hilo")

	var antes: Vector2 = _pos(jornada, "a")
	var coger := InputEventJoypadButton.new()
	coger.button_index = JOY_BUTTON_X
	coger.pressed = true
	panel._entrada_ficha(coger, "a")
	_comprobar(panel.cogida() == "a", "X del mando coge la ficha")
	var derecha := InputEventAction.new()
	derecha.action = "ui_right"
	derecha.pressed = true
	panel._entrada_ficha(derecha, "a")
	var despues: Vector2 = _pos(jornada, "a")
	_comprobar(
		is_equal_approx(despues.x, antes.x + CorchoPanelScript.PASO_TECLADO),
		"con la ficha cogida las direcciones la mueven"
	)
	var tecla := InputEventKey.new()
	tecla.physical_keycode = KEY_M
	tecla.pressed = true
	panel._entrada_ficha(tecla, "a")
	_comprobar(panel.cogida().is_empty(), "M del teclado suelta la ficha")
	var aceptar := InputEventAction.new()
	aceptar.action = "ui_accept"
	aceptar.pressed = true
	panel._entrada_ficha(aceptar, "c")
	_comprobar(panel.seleccion() == "c", "Intro/A marca la ficha para el hilo")

	var centro_a := boton_a.position + boton_a.size * 0.5
	var logico: Vector2 = panel._a_logico(centro_a)
	_comprobar(logico.distance_to(_pos(jornada, "a")) < 0.01, "la ficha se dibuja donde está")

	var cancelar := InputEventAction.new()
	cancelar.action = "ui_cancel"
	cancelar.pressed = true
	panel._input(cancelar)
	_comprobar(panel.seleccion().is_empty() and cambios[1] == 0, "Esc/B primero deshace la marca")
	panel._input(cancelar)
	_comprobar(cambios[1] == 1, "Esc/B sin nada en curso cierra la interfaz")
	panel.queue_free()


func _pos(jornada: Dictionary, id: String) -> Vector2:
	var pos: Array = CorchoScript.estado(jornada)["fichas"][id]["pos"]
	return Vector2(pos[0], pos[1])


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
