## Regresión de #795: un decorado puede montar una escena .tscn.
##
## La apertura de créditos tiene que recorrer todas las verticales de sueño, y
## esas verticales son escenas completas, no espacios del catálogo. Aquí se
## comprueba el contrato de verdad: `Espacio3D.construir` las monta sin caja
## por defecto, una ruta rota no tumba nada y el reproductor común las rueda en
## su plató y las retira al cambiar de plano.
extends SceneTree

const ESCENA_CINEMATICA := preload("res://escenas/cinematica.tscn")
const GILGAMESH := "res://escenas/sueno_gilgamesh.tscn"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	await _probar_todas_las_verticales()
	await _probar_solo_escena_sin_caja()
	await _probar_ruta_rota()
	await _probar_en_el_reproductor()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _verticales() -> Array:
	var rutas: Array = []
	var dir := DirAccess.open("res://escenas")
	for fichero in dir.get_files():
		if fichero.begins_with("sueno_") and fichero.ends_with(".tscn"):
			rutas.append("res://escenas/" + fichero)
	rutas.sort()
	return rutas


func _mallas(nodo: Node) -> int:
	return nodo.find_children("*", "MeshInstance3D", true, false).size()


func _probar_todas_las_verticales() -> void:
	var rutas := _verticales()
	_comprobar(rutas.size() >= 11, "hay al menos once verticales de sueño (%d)" % rutas.size())
	for ruta in rutas:
		var raiz := Node3D.new()
		root.add_child(raiz)
		Espacio3D.construir(raiz, {"escena": ruta})
		await process_frame
		_comprobar(raiz.get_child_count() == 1, "%s se monta como un solo nodo" % ruta.get_file())
		_comprobar(_mallas(raiz) > 0, "%s trae geometría propia" % ruta.get_file())
		raiz.queue_free()
		await process_frame


func _probar_solo_escena_sin_caja() -> void:
	var directa := (load(GILGAMESH) as PackedScene).instantiate()
	root.add_child(directa)
	var sola := Node3D.new()
	root.add_child(sola)
	Espacio3D.construir(sola, {"escena": GILGAMESH})
	var con_suelo := Node3D.new()
	root.add_child(con_suelo)
	Espacio3D.construir(con_suelo, {"escena": GILGAMESH, "suelo": Vector2(4, 4)})
	await process_frame
	_comprobar(
		_mallas(sola) == _mallas(directa), "solo `escena`: ni suelo ni muros por defecto alrededor"
	)
	_comprobar(_mallas(con_suelo) > _mallas(sola), "con `suelo` explícito sí se levanta la sala")

	var desplazada := Node3D.new()
	root.add_child(desplazada)
	Espacio3D.construir(desplazada, {"escena": GILGAMESH, "escena_posicion": Vector3(3, 0, -2)})
	_comprobar(
		(desplazada.get_child(0) as Node3D).position == Vector3(3, 0, -2),
		"`escena_posicion` coloca la escena"
	)
	for nodo in [directa, sola, con_suelo, desplazada]:
		nodo.queue_free()
	await process_frame


func _probar_ruta_rota() -> void:
	var raiz := Node3D.new()
	root.add_child(raiz)
	Espacio3D.construir(raiz, {"escena": "res://escenas/no_existe_795.tscn"})
	await process_frame
	_comprobar(raiz.get_child_count() == 0, "una escena que no existe no monta nada ni rompe")
	raiz.queue_free()
	await process_frame


func _probar_en_el_reproductor() -> void:
	var rodaje := (
		Cinematica
		. resolver(
			[
				{
					"tipo": "3d",
					"nombre": "baba-yaga",
					"decorado": {"escena": "res://escenas/sueno_baba_yaga.tscn"},
					"camara": Vector3(0, 1.6, 4),
					"mira": Vector3(0, 1, 0),
					"segundos": 0.4,
				},
				{
					"tipo": "3d",
					"nombre": "oficina",
					"decorado": EspaciosCatalogo.OFICINA.duplicate(true),
					"camara": Vector3(0, 1.6, 3),
					"mira": Vector3(-3, 1, 0),
					"segundos": 0.4,
				},
			]
		)
	)
	_comprobar(Cinematica.validar(rodaje).is_empty(), "un plano con escena valida como 3d")
	var app := ESCENA_CINEMATICA.instantiate()
	root.add_child(app)
	app.reproducir(rodaje)
	await process_frame
	await process_frame
	_comprobar(
		not app.find_children("SuenoBabaYaga", "", true, false).is_empty(),
		"el plató rueda la vertical de Baba Yaga"
	)
	var estado := {"terminada": false}
	app.terminada.connect(func(): estado["terminada"] = true)
	# En headless los frames vuelan: se espera por reloj, no por número de frames.
	var limite := Time.get_ticks_msec() + 3000
	while (
		not app.find_children("SuenoBabaYaga", "", true, false).is_empty()
		and Time.get_ticks_msec() < limite
	):
		await process_frame
	_comprobar(
		app.find_children("SuenoBabaYaga", "", true, false).is_empty(),
		"al cambiar de plano la vertical se retira del plató"
	)
	limite = Time.get_ticks_msec() + 3000
	while not estado["terminada"] and Time.get_ticks_msec() < limite:
		await process_frame
	_comprobar(estado["terminada"], "la cinemática termina")
	app.queue_free()
	await process_frame


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		print("FALLO: " + descripcion)
