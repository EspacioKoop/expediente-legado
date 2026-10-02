## Regresion del adaptador 3D EMBESTIDOR (#2130).
##
## godot4 --headless --path godot --script pruebas/pruebas_embestidor_runtime_1771.gd
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const RUNTIME = preload("res://guion/juicio_combate_embestidor_3d.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_linea_bloqueada()
	_probar_rumbo_fijado_y_carga()
	_probar_choque_abre_ventana()
	_probar_movimiento_acotado()
	_probar_telegraph_geometrico()
	_probar_determinismo()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _nueva() -> Dictionary:
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.EMBESTIDOR, 2130, 1)
	unidad["cooldown"] = 0.0
	return unidad


func _probar_linea_bloqueada() -> void:
	var paso := RUNTIME.avanzar(_nueva(), 0.01, Vector3.ZERO, Vector3(0.0, 0.0, 6.0), false)
	_comprobar(String(paso["unidad"]["estado"]) == ARQUETIPOS.REPOSICIONAR, "sin linea no carga")
	_comprobar(
		String(paso["unidad"]["_intencion_runtime"]) == "buscar_linea",
		"linea bloqueada pide reposicionarse",
	)
	_comprobar(not bool(paso["inicio_agresion"]), "buscar linea no inicia agresion")


func _probar_rumbo_fijado_y_carga() -> void:
	var rival := Vector3.ZERO
	var jugador_inicial := Vector3(4.0, 0.0, 4.0)
	var paso := RUNTIME.avanzar(_nueva(), 0.01, rival, jugador_inicial)
	var unidad: Dictionary = paso["unidad"]
	_comprobar(String(unidad["estado"]) == ARQUETIPOS.TELEGRAFIAR, "entra en telegraph")
	_comprobar(String(paso["telegraph"]) == "carga_lineal", "avisa carga lineal")
	_comprobar(bool(paso["inicio_agresion"]), "expone inicio de agresion")
	var rumbo := float(unidad["rumbo_bloqueado"])

	var jugador_movido := Vector3(-5.0, 0.0, 3.0)
	paso = RUNTIME.avanzar(unidad, 0.30, rival, jugador_movido)
	unidad = paso["unidad"]
	_comprobar(
		float(unidad["rumbo_bloqueado"]) == rumbo, "moverse no corrige el rumbo telegrafiado"
	)
	paso = RUNTIME.avanzar(unidad, 0.45, rival, jugador_movido)
	unidad = paso["unidad"]
	_comprobar(String(unidad["estado"]) == ARQUETIPOS.CARGAR, "entra en carga tras el aviso")
	_comprobar(bool(paso["inicio_carga"]), "expone inicio de carga")

	var movimiento := RUNTIME.mover(jugador_movido, rival, 0.0, unidad, 5.0, 0.10)
	var esperado := HOST.direccion_linea(rumbo)
	var desplazamiento: Vector3 = movimiento["posicion"] - rival
	_comprobar(bool(movimiento["cargando"]), "runtime marca movimiento de carga")
	_comprobar(desplazamiento.length() > 0.1, "la carga desplaza al rival")
	_comprobar(
		desplazamiento.normalized().dot(esperado) > 0.999,
		"la carga conserva la direccion fijada",
	)


func _probar_choque_abre_ventana() -> void:
	var rival := Vector3.ZERO
	var jugador := Vector3(0.0, 0.0, 6.0)
	var paso := RUNTIME.avanzar(_nueva(), 0.01, rival, jugador)
	var unidad: Dictionary = paso["unidad"]
	paso = RUNTIME.avanzar(unidad, 0.75, rival, jugador)
	unidad = paso["unidad"]
	_comprobar(String(unidad["estado"]) == ARQUETIPOS.CARGAR, "precondicion de choque en carga")
	paso = RUNTIME.avanzar(unidad, 0.01, rival, jugador, true, true)
	unidad = paso["unidad"]
	_comprobar(String(unidad["estado"]) == ARQUETIPOS.RECUPERAR, "choque corta la carga")
	_comprobar(bool(paso["abrir_ventana"]), "choque abre ventana de respuesta")


func _probar_movimiento_acotado() -> void:
	var unidad := _nueva()
	unidad["estado"] = ARQUETIPOS.CARGAR
	unidad["rumbo_bloqueado"] = PI * 0.5
	unidad["_intencion_runtime"] = ARQUETIPOS.CARGAR
	var movimiento := RUNTIME.mover(
		Vector3(9.0, 0.0, 0.0), Vector3(4.8, 0.0, 0.0), 0.0, unidad, 5.0, 1.0
	)
	var posicion: Vector3 = movimiento["posicion"]
	_comprobar(Vector2(posicion.x, posicion.z).length() <= 5.001, "carga queda dentro de arena")


func _probar_telegraph_geometrico() -> void:
	var raiz := Node3D.new()
	get_root().add_child(raiz)
	var linea := RUNTIME.montar_linea(raiz)
	_comprobar(linea != null and not linea.visible, "linea empieza oculta")
	var unidad := _nueva()
	unidad["rumbo_bloqueado"] = 0.7
	RUNTIME.pintar_linea(linea, Vector3.ZERO, unidad, "carga_lineal")
	_comprobar(linea.visible, "carga_lineal muestra telegraph")
	_comprobar(is_equal_approx(linea.rotation.y, 0.7), "telegraph usa rumbo congelado")
	RUNTIME.pintar_linea(linea, Vector3.ZERO, unidad, "")
	_comprobar(not linea.visible, "sin telegraph oculta la linea")
	raiz.free()


func _probar_determinismo() -> void:
	var rival := Vector3(1.0, 0.0, -1.0)
	var jugador := Vector3(4.0, 0.0, 3.0)
	var a := RUNTIME.avanzar(_nueva(), 0.01, rival, jugador)
	var b := RUNTIME.avanzar(_nueva(), 0.01, rival, jugador)
	_comprobar(a == b, "misma entrada produce el mismo paso")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
