## Regresion headless del runtime CONTROLADOR (#2145).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const CONTROLADOR = preload("res://guion/juicio_combate_controlador_3d.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_telegraph_y_geometria_congelada()
	_probar_salida_valida_y_limite()
	_probar_recuperacion()
	_probar_reduccion_movimiento()
	print("controlador_runtime_2086: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_telegraph_y_geometria_congelada() -> void:
	var raiz := Node3D.new()
	get_root().add_child(raiz)
	var zonas := CONTROLADOR.montar_zonas(raiz)
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.CONTROLADOR, 2086)
	var paso := CONTROLADOR.avanzar(
		unidad,
		0.0,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 5.0),
		zonas,
		0,
		true,
	)
	unidad = paso["unidad"]
	_comprobar(String(unidad["estado"]), ARQUETIPOS.MARCAR_ZONA, "entra en MARCAR_ZONA")
	_comprobar(bool(paso["inicio_marca"]), true, "expone inicio de marca")
	_comprobar(String(paso["telegraph"]), "zona", "expone telegraph de zona")
	_comprobar(_visibles(zonas), 1, "muestra una zona durante el aviso")
	var geometria: Dictionary = paso["geometria"].duplicate(true)

	paso = CONTROLADOR.avanzar(
		unidad,
		0.1,
		Vector3(3.0, 0.0, 2.0),
		Vector3(-5.0, 0.0, -4.0),
		zonas,
		0,
		true,
	)
	unidad = paso["unidad"]
	_comprobar(paso["geometria"], geometria, "mover contexto no corrige la geometria marcada")
	raiz.free()


func _probar_salida_valida_y_limite() -> void:
	var raiz := Node3D.new()
	get_root().add_child(raiz)
	var zonas := CONTROLADOR.montar_zonas(raiz)
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.CONTROLADOR, 2086)
	var paso := CONTROLADOR.avanzar(
		unidad, 0.0, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), zonas, 0, true
	)
	unidad = paso["unidad"]
	paso = CONTROLADOR.avanzar(
		unidad, 1.0, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), zonas, 0, false
	)
	unidad = paso["unidad"]
	_comprobar(
		String(unidad["estado"]),
		ARQUETIPOS.MARCAR_ZONA,
		"sin salida valida no activa la zona",
	)
	_comprobar(bool(paso["zona_activa"]), false, "sin salida valida no declara autoridad")

	paso = CONTROLADOR.avanzar(
		unidad, 0.0, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), zonas, 0, true
	)
	_comprobar(String(paso["unidad"]["estado"]), ARQUETIPOS.ACTIVAR_ZONA, "activa al recuperar salida")
	_comprobar(bool(paso["inicio_zona"]), true, "expone inicio de zona")

	var saturada := ARQUETIPOS.nuevo(ARQUETIPOS.CONTROLADOR, 2086)
	saturada["estado"] = ARQUETIPOS.MARCAR_ZONA
	saturada["temporizador"] = 0.0
	saturada["zonas_marcadas"] = ARQUETIPOS.CONTROLADOR_MAX_ZONAS
	var bloqueada := CONTROLADOR.avanzar(
		saturada,
		0.0,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 5.0),
		zonas,
		ARQUETIPOS.CONTROLADOR_MAX_ZONAS,
		true,
	)
	_comprobar(
		String(bloqueada["unidad"]["estado"]),
		ARQUETIPOS.MARCAR_ZONA,
		"el limite de zonas impide otra activacion",
	)
	_comprobar(bool(bloqueada["zona_activa"]), false, "el limite no crea autoridad extra")
	raiz.free()


func _probar_recuperacion() -> void:
	var raiz := Node3D.new()
	get_root().add_child(raiz)
	var zonas := CONTROLADOR.montar_zonas(raiz)
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.CONTROLADOR, 2086)
	var paso := CONTROLADOR.avanzar(
		unidad, 0.0, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), zonas, 0, true
	)
	unidad = paso["unidad"]
	paso = CONTROLADOR.avanzar(
		unidad, 1.0, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), zonas, 0, true
	)
	unidad = paso["unidad"]
	_comprobar(String(unidad["estado"]), ARQUETIPOS.ACTIVAR_ZONA, "entra en zona activa")
	paso = CONTROLADOR.avanzar(
		unidad, 1.0, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), zonas, 1, true
	)
	_comprobar(String(paso["unidad"]["estado"]), ARQUETIPOS.RECUPERAR, "termina en recuperacion")
	_comprobar(bool(paso["abrir_ventana"]), true, "recuperacion abre ventana de respuesta")
	_comprobar(_visibles(zonas), 0, "recuperar apaga la autoridad espacial")
	raiz.free()


func _probar_reduccion_movimiento() -> void:
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.CONTROLADOR, 2086)
	unidad["estado"] = ARQUETIPOS.MARCAR_ZONA
	unidad["temporizador"] = ARQUETIPOS.CONTROLADOR_TELEGRAFO
	unidad["_zona_indice"] = 1
	unidad["_zona_origen"] = Vector3(1.0, 0.0, 2.0)
	unidad["_zona_rumbo"] = 0.75
	var animada := CONTROLADOR.presentacion(unidad, false)
	var reducida := CONTROLADOR.presentacion(unidad, true)
	_comprobar(animada["geometria"], reducida["geometria"], "reduccion conserva geometria logica")
	_comprobar(animada["estado"], reducida["estado"], "reduccion conserva estado y timing")
	_comprobar(String(reducida["estilo"]), "corte", "reduccion solo cambia presentacion")


func _visibles(zonas: Array) -> int:
	var total := 0
	for zona_variant in zonas:
		var zona := zona_variant as MeshInstance3D
		if zona != null and zona.visible:
			total += 1
	return total


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #2145 CONTROLADOR: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
