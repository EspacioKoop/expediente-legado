## #795/#2527: comprobar el montaje como datos Godot, no por grep.
extends SceneTree

const ESCENA_CINEMATICA := preload("res://escenas/cinematica.tscn")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	var planos := CreditosInicioCinematica.planos()
	var fuente := CreditosInicio.bloques_completos()
	var atribuciones := {}
	for bloque in fuente:
		for entrada in bloque.get("entradas", []):
			if entrada is Dictionary:
				atribuciones[String(entrada.get("nombre", ""))] = true

	_comprobar(planos.size() == 40, "cuarenta planos en el rodaje")
	_comprobar(Cinematica.validar(planos).is_empty(), "contrato Cinematica.validar")

	var localizaciones := {}
	var camaras := {}
	var verticales := {}
	var con_rotulo := 0
	var sin_rotulo := 0
	var zonas_dia := 0
	var identidades_sueno := {}
	for plano in planos:
		var nombre := String(plano.get("nombre", ""))
		var decorado: Dictionary = plano.get("decorado", {})
		_comprobar(plano.get("tipo", "") == "3d", "plano 3d: " + nombre)
		_comprobar(not decorado.is_empty(), "decorado no vacio: " + nombre)
		_comprobar(not localizaciones.has(nombre), "localizacion no repetida: " + nombre)
		localizaciones[nombre] = true
		_comprobar(plano.has("camara") and plano.has("mira"), "encuadre completo: " + nombre)
		_comprobar(
			plano.has("camara_desde") and plano.has("mira_desde"),
			"origen de movimiento explicito: " + nombre
		)
		_comprobar(
			Vector3(plano["camara"]).distance_to(Vector3(plano["camara_desde"])) < 0.5,
			"travelling corto: " + nombre
		)
		var camara_id := str(plano["camara"])
		_comprobar(not camaras.has(camara_id), "encuadre no repetido: " + nombre)
		camaras[camara_id] = true
		_comprobar(
			String(plano.get("voz", "")).is_empty(), "sin texto en subtitulo 18 px: " + nombre
		)

		var rotulo := String(plano.get("rotulo", ""))
		if rotulo.is_empty():
			sin_rotulo += 1
		else:
			con_rotulo += 1
			_comprobar(rotulo.length() <= 36, "rotulo legible: " + nombre)
			_comprobar(atribuciones.has(rotulo), "rotulo solo del catalogo: " + nombre)

		if decorado.has("escena"):
			var ruta := String(decorado["escena"])
			verticales[ruta] = true
			_comprobar(ResourceLoader.exists(ruta, "PackedScene"), "escena disponible: " + ruta)
		elif decorado.has("zona_creditos"):
			zonas_dia += 1
			_comprobar(
				String(decorado["zona_creditos"]) == nombre,
				"zona de vigilia con decorado propio: " + nombre
			)
		else:
			var identidad := String(decorado.get("identidad_onirica", ""))
			_comprobar(not identidad.is_empty(), "identidad de sueno: " + nombre)
			identidades_sueno[identidad] = true

	_comprobar(localizaciones.size() == 40, "ninguna localizacion se repite")
	_comprobar(camaras.size() == 40, "ningun encuadre se reutiliza")
	_comprobar(zonas_dia == 22, "22 rincones de vigilia")
	_comprobar(identidades_sueno.size() == 7, "siete identidades por diccionario")
	_comprobar(verticales.size() == 11, "once verticales de sueno")
	_comprobar(con_rotulo <= 12 and sin_rotulo >= 25, "espacio para imagenes sin rotulos")
	_comprobar(
		Cinematica.duracion(planos) >= 70.0 and Cinematica.duracion(planos) <= 95.0,
		"duracion de apertura contenida"
	)
	_comprobar(
		String(planos[planos.size() - 2].get("rotulo", "")) == _credito_de(fuente, "direccion"),
		"direccion en el penultimo plano"
	)
	_comprobar(
		String(planos[planos.size() - 1].get("rotulo", "")) == _credito_de(fuente, "titulo"),
		"titulo final desde la fuente canonica"
	)
	_comprobar(
		float(planos[planos.size() - 1].get("segundos", 0.0)) >= 3.5,
		"el titulo respira antes del final"
	)
	await _probar_movimiento_y_salto(planos)
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_movimiento_y_salto(planos: Array) -> void:
	# Reproducción real en el plató común: se comprueba que la alternativa
	# accesible detiene la cámara en el destino y que saltar termina limpiamente.
	var app := ESCENA_CINEMATICA.instantiate()
	root.add_child(app)
	var plano: Dictionary = planos[0].duplicate(true)
	plano["segundos"] = 1.0
	app.call("reproducir", [plano])
	var camara: Camera3D = app.get("_camara")
	_comprobar(camara != null, "el reproductor crea una camara 3D")
	if camara != null:
		app.set("_reduccion_movimiento", true)
		app.call("_mover_camara", plano, 0.4)
		_comprobar(
			camara.global_position.is_equal_approx(Vector3(plano["camara"])),
			"con reduccion de movimiento la camara queda quieta en destino"
		)
		app.set("_reduccion_movimiento", false)
		app.call("_mover_camara", plano, 0.0)
		_comprobar(
			camara.global_position.distance_to(Vector3(plano["camara"])) > 0.05,
			"sin reduccion se conserva el travelling"
		)
	var finalizado := {"ok": false}
	app.connect("terminada", func(): finalizado["ok"] = true)
	app.call("saltar")
	_comprobar(finalizado["ok"], "saltar emite la terminacion")
	_comprobar(not bool(app.get("_reproduciendo")), "saltar detiene el montaje")
	app.queue_free()
	await process_frame


func _credito_de(bloques: Array, id: String) -> String:
	for bloque in bloques:
		if String(bloque.get("id", "")) == id:
			var entradas: Array = bloque.get("entradas", [])
			if not entradas.is_empty():
				return String(entradas[0].get("nombre", ""))
	return ""


func _comprobar(ok: bool, mensaje: String) -> void:
	if ok:
		_pasadas += 1
	else:
		_fallos += 1
		printerr("FALLO: " + mensaje)
